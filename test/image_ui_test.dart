import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:nsl_writer_tools/app.dart';
import 'package:nsl_writer_tools/data/database.dart';
import 'package:nsl_writer_tools/data/image_store.dart';
import 'package:nsl_writer_tools/data/repository.dart';
import 'package:nsl_writer_tools/data/seed.dart';
import 'package:nsl_writer_tools/providers.dart';
import 'package:nsl_writer_tools/theme.dart';
import 'package:nsl_writer_tools/ui/entry_editor.dart';

Uint8List _png(int w, int h) {
  final image = img.Image(width: w, height: h);
  for (final px in image) {
    px
      ..r = px.x * 255 ~/ w
      ..g = 90
      ..b = px.y * 255 ~/ h;
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late AppDatabase db;
  late Repository repo;
  late Directory dir;
  Uint8List? picked;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('image_ui');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db, images: ImageStore(dir: dir));
    picked = _png(300, 200);
  });
  tearDown(() async {
    await db.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Future<void> quiet(WidgetTester tester, {int rounds = 8}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  dynamic overrides() => [
        databaseProvider.overrideWithValue(db),
        repositoryProvider.overrideWithValue(repo),
        imagePickerProvider.overrideWithValue(() async => picked),
      ];

  testWidgets('editor: add, change and remove a picture', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late String id;
    await tester.runAsync(() async {
      final w = await repo.createWorld('โลก');
      id = (await repo.createEntry(worldId: w.id, type: EntryType.character, title: 'อาริน')).id;
    });
    await tester.pumpWidget(ProviderScope(
      overrides: overrides(),
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
    await quiet(tester);

    expect(find.text('เพิ่มรูป'), findsOneWidget);
    expect(find.text('เอารูปออก'), findsNothing);

    await tester.tap(find.text('เพิ่มรูป'));
    await quiet(tester, rounds: 12);
    final stored = (await tester.runAsync(() async => (await db.select(db.entries).get()).single))!;
    expect(ImageStore.validName(stored.imagePath), isTrue);
    expect(find.text('เปลี่ยนรูป'), findsOneWidget);
    expect(find.text('เอารูปออก'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(await tester.runAsync(() => repo.images.has(stored.imagePath)), isTrue);

    // Change it.
    picked = _png(120, 300);
    await tester.tap(find.text('เปลี่ยนรูป'));
    await quiet(tester, rounds: 12);
    final changed = (await tester.runAsync(() async => (await db.select(db.entries).get()).single))!;
    expect(changed.imagePath, isNot(stored.imagePath));
    expect(ImageStore.validName(changed.imagePath), isTrue);

    // Remove it.
    await tester.tap(find.text('เอารูปออก'));
    await quiet(tester);
    final removed = (await tester.runAsync(() async => (await db.select(db.entries).get()).single))!;
    expect(removed.imagePath, isNull);
    expect(find.text('เพิ่มรูป'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    // Nothing was reported as a conflict by our own changes.
    expect(await tester.runAsync(() async => (await db.select(db.entries).get()).length), 1);

    await tester.pumpWidget(const SizedBox());
    await quiet(tester, rounds: 2);
  });

  testWidgets('a cancelled or broken pick changes nothing', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late String id;
    await tester.runAsync(() async {
      final w = await repo.createWorld('โลก');
      id = (await repo.createEntry(worldId: w.id, type: EntryType.character, title: 'อาริน')).id;
    });
    await tester.pumpWidget(ProviderScope(
      overrides: overrides(),
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
    await quiet(tester);

    picked = null; // cancelled
    await tester.tap(find.text('เพิ่มรูป'));
    await quiet(tester);
    expect((await tester.runAsync(() async => (await db.select(db.entries).get()).single))!.imagePath, isNull);

    picked = Uint8List.fromList([1, 2, 3, 4]); // not a picture
    await tester.tap(find.text('เพิ่มรูป'));
    await quiet(tester, rounds: 12);
    expect((await tester.runAsync(() async => (await db.select(db.entries).get()).single))!.imagePath, isNull);
    expect(find.textContaining('เปิดรูปนี้ไม่ได้'), findsOneWidget);
    expect(find.text('เพิ่มรูป'), findsOneWidget, reason: 'the button is usable again');

    await tester.pumpWidget(const SizedBox());
    await quiet(tester, rounds: 2);
  });

  testWidgets('desktop: the picture shows in the entry and as the list thumbnail', (tester) async {
    tester.view.physicalSize = const Size(1280, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      final w = await repo.createWorld('โลก');
      await seedSampleWorld(repo, w.id);
      final lyra = (await repo.entriesOfWorld(w.id)).firstWhere((e) => e.title == 'ไลรา วาเลน');
      final name = await repo.images.addFromBytes(_png(400, 300));
      await repo.updateEntry(lyra.id, imagePath: Value(name));
    });
    await tester.pumpWidget(ProviderScope(overrides: overrides(), child: const NslApp()));
    await quiet(tester);
    expect(find.byType(Image), findsWidgets, reason: 'thumbnail in the list');
    final before = find.byType(Image).evaluate().length;

    await tester.tap(find.text('ไลรา วาเลน').first);
    await quiet(tester);
    expect(find.byType(Image).evaluate().length, greaterThan(before), reason: 'big picture in the entry');

    // Tapping it opens the viewer.
    await tester.tap(find.bySemanticsLabel(RegExp('รูปของ ไลรา วาเลน')));
    await quiet(tester);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.byTooltip('ปิด'));
    await quiet(tester);
    expect(find.byType(InteractiveViewer), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await quiet(tester, rounds: 2);
  });
}
