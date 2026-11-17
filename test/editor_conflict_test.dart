import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nsl_writer_tools/data/database.dart';
import 'package:nsl_writer_tools/data/repository.dart';
import 'package:nsl_writer_tools/providers.dart';
import 'package:nsl_writer_tools/theme.dart';
import 'package:nsl_writer_tools/ui/entry_editor.dart';

/// A sync can change an entry while it is open in the editor. The editor's autosave used to
/// overwrite that change without a trace.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late AppDatabase db;
  late Repository repo;
  var now = DateTime(2026, 10, 12, 9);
  void later([int s = 10]) => now = now.add(Duration(seconds: s));

  setUp(() {
    now = DateTime(2026, 10, 12, 9);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db, clock: () => now);
  });
  tearDown(() => db.close());

  Future<(String, Entry)> world() async {
    final w = await repo.createWorld('โลก');
    final e = await repo.createEntry(worldId: w.id, type: EntryType.character, title: 'อาริน', summary: 'เดิม');
    return (w.id, e);
  }

  group('Repository.updateEntry with expectedModified', () {
    test('matching stamp: plain save, no copy', () async {
      final (_, e) = await world();
      later();
      final r = await repo.updateEntry(e.id, summary: 'ใหม่', expectedModified: e.modified);
      expect(r.conflictCopy, isNull);
      expect(r.entry!.summary, 'ใหม่');
      expect(r.entry!.modified.isAfter(e.modified), isTrue);
    });

    test('stale stamp: the stored version is kept as a conflict copy, the typed one wins', () async {
      final (wid, e) = await world();
      later();
      await repo.updateEntry(e.id, summary: 'มาจากการซิงก์'); // "the other device"
      later();
      final r = await repo.updateEntry(e.id, summary: 'ที่ฉันพิมพ์', expectedModified: e.modified);

      expect(r.entry!.summary, 'ที่ฉันพิมพ์');
      expect(r.conflictCopy, 'อาริน (ขัดแย้ง)');
      final copy = (await repo.entriesOfWorld(wid)).firstWhere((x) => x.title == 'อาริน (ขัดแย้ง)');
      expect(copy.summary, 'มาจากการซิงก์');
      expect(copy.id, startsWith('cc-${e.id}-'));
    });

    test('stale stamp but nothing to overwrite: no copy', () async {
      final (wid, e) = await world();
      later();
      await repo.updateEntry(e.id, summary: 'เหมือนกัน');
      later();
      final r = await repo.updateEntry(e.id, summary: 'เหมือนกัน', expectedModified: e.modified);
      expect(r.conflictCopy, isNull);
      expect((await repo.entriesOfWorld(wid)).length, 1);
    });

    test('the same stale save twice makes one copy, and a second clash gets a numbered title', () async {
      final (wid, e) = await world();
      later();
      await repo.updateEntry(e.id, summary: 'หนึ่ง');
      later();
      final first = await repo.updateEntry(e.id, summary: 'ฉัน 1', expectedModified: e.modified);
      expect(first.conflictCopy, isNotNull);
      later();
      await repo.updateEntry(e.id, summary: 'สอง'); // another outside change
      later();
      final second = await repo.updateEntry(e.id, summary: 'ฉัน 2', expectedModified: first.entry!.modified);
      expect(second.conflictCopy, 'อาริน (ขัดแย้ง) 2');
      expect((await repo.entriesOfWorld(wid)).length, 3);
    });

    test('a rename together with a stale save still rewrites links and keeps the copy', () async {
      final (wid, e) = await world();
      final other = await repo.createEntry(worldId: wid, type: EntryType.place, title: 'เมือง', body: 'บ้านของ [[อาริน]]');
      later();
      await repo.updateEntry(e.id, summary: 'จากการซิงก์');
      later();
      final r = await repo.updateEntry(e.id, title: 'อารินทร์', expectedModified: e.modified);
      expect(r.conflictCopy, 'อาริน (ขัดแย้ง)');
      final all = await repo.entriesOfWorld(wid);
      expect(all.firstWhere((x) => x.id == other.id).body, 'บ้านของ [[อารินทร์]]');
    });

    test('without expectedModified nothing changes (old callers)', () async {
      final (wid, e) = await world();
      later();
      await repo.updateEntry(e.id, summary: 'a');
      later();
      await repo.updateEntry(e.id, summary: 'b');
      expect((await repo.entriesOfWorld(wid)).length, 1);
    });
  });

  group('open editor', () {
    late String wid;
    late String id;

    Future<void> pumpUntilQuiet(WidgetTester tester, {int rounds = 6}) async {
      for (var i = 0; i < rounds; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    Future<void> open(WidgetTester tester) async {
      await tester.runAsync(() async {
        final (w, e) = await world();
        wid = w;
        id = e.id;
      });
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), repositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: buildTheme(),
          home: Scaffold(
            body: StreamBuilder<Entry?>(
              stream: repo.watchEntry(id),
              builder: (context, snap) => snap.data == null
                  ? const SizedBox()
                  : SingleChildScrollView(child: EntryEditor(key: ValueKey(id), entry: snap.data!, onDone: () {})),
            ),
          ),
        ),
      ));
      await pumpUntilQuiet(tester);
    }

    /// An outside change (what a sync does).
    Future<void> outside(WidgetTester tester, {required String summary}) async {
      later();
      await tester.runAsync(() => repo.updateEntry(id, summary: summary));
      await pumpUntilQuiet(tester, rounds: 3);
    }

    /// Unmounts the editor (it saves on the way out) and lets drift's stream timers finish.
    Future<void> close(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await pumpUntilQuiet(tester, rounds: 2);
    }

    Future<List<Entry>> stored(WidgetTester tester) async => (await tester.runAsync(() => repo.entriesOfWorld(wid)))!;

    testWidgets('nothing typed: a change from a sync shows up in the open editor and is not written back', (tester) async {
      await open(tester);
      expect(find.widgetWithText(TextField, 'เดิม'), findsOneWidget);

      await outside(tester, summary: 'แก้จากอีกเครื่อง');
      expect(find.widgetWithText(TextField, 'แก้จากอีกเครื่อง'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'เดิม'), findsNothing);
      expect(find.text('รายการนี้ถูกอัปเดตจากการซิงก์'), findsOneWidget);

      await tester.pumpWidget(const SizedBox()); // closing the editor
      await pumpUntilQuiet(tester, rounds: 2);
      final all = await stored(tester);
      expect(all.single.summary, 'แก้จากอีกเครื่อง');
    });

    testWidgets('typing while a sync changes the entry: the typed text wins and the other version is kept', (tester) async {
      await open(tester);
      await tester.enterText(find.widgetWithText(TextField, 'เดิม'), 'ที่ฉันพิมพ์');
      await outside(tester, summary: 'จากการซิงก์'); // lands before the autosave fires
      // The editor must not discard what is being typed.
      expect(find.widgetWithText(TextField, 'ที่ฉันพิมพ์'), findsOneWidget);

      later();
      await pumpUntilQuiet(tester, rounds: 8); // past the 0.6 s autosave
      final all = await stored(tester);
      expect(all.length, 2);
      expect(all.firstWhere((e) => e.id == id).summary, 'ที่ฉันพิมพ์');
      expect(all.firstWhere((e) => e.id != id).summary, 'จากการซิงก์');
      expect(all.firstWhere((e) => e.id != id).title, 'อาริน (ขัดแย้ง)');
      expect(find.textContaining('เก็บฉบับนั้นไว้เป็น'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'ที่ฉันพิมพ์'), findsOneWidget);
      await close(tester);
    });

    testWidgets('own autosaves never look like a conflict', (tester) async {
      await open(tester);
      for (final text in ['หนึ่ง', 'หนึ่งสอง', 'หนึ่งสองสาม']) {
        later();
        await tester.enterText(find.byType(TextField).at(3), text); // summary or body: any field will do
        await pumpUntilQuiet(tester, rounds: 6);
      }
      final all = await stored(tester);
      expect(all.length, 1, reason: 'no conflict copy from our own saves');
      expect(find.textContaining('เก็บฉบับนั้นไว้เป็น'), findsNothing);
      expect(find.text('รายการนี้ถูกอัปเดตจากการซิงก์'), findsNothing);
      await close(tester);
    });
  });
}
