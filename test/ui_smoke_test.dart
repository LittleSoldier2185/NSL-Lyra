import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nsl_writer_tools/app.dart';
import 'package:nsl_writer_tools/data/database.dart';
import 'package:nsl_writer_tools/data/repository.dart';
import 'package:nsl_writer_tools/data/seed.dart';
import 'package:nsl_writer_tools/providers.dart';
import 'package:nsl_writer_tools/ui/timeline_view.dart';

/// Layout smoke tests: any overflow or build exception fails the test.
void main() {
  setUpAll(() {
    // Fonts must come from the bundled assets; a missing weight should fail loudly.
    GoogleFonts.config.allowRuntimeFetching = false;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase db;

  Future<void> start(WidgetTester tester, {required Size size, double textScale = 1, bool seed = true}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.runAsync(() async {
      final repo = Repository(db);
      final w = await repo.createWorld('หมู่เกาะเงาจันทร์');
      if (seed) await seedSampleWorld(repo, w.id);
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const NslApp(),
    ));
    await settle(tester);
  }

  Future<void> stop(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
    await tester.runAsync(db.close);
  }

  const phone = Size(360, 760);
  const desktop = Size(1280, 820);

  testWidgets('phone: list → detail → backlinks tab → edit with [[ autocomplete', (tester) async {
    await start(tester, size: phone);

    expect(find.text('ไลรา วาเลน'), findsOneWidget);
    expect(find.text('ท่าเรือโคราล'), findsOneWidget);

    await tester.tap(find.text('ไลรา วาเลน'));
    await settle(tester);
    expect(find.textContaining('พ่อของเธอ'), findsOneWidget);

    await tester.tap(find.textContaining('Backlinks ·'));
    await settle(tester);
    expect(find.text('ออร์ริน วาเลน'), findsWidgets);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await settle(tester);
    expect(find.text('แก้ไขรายการ'), findsOneWidget);

    final bodyField = find.byWidgetPredicate((w) => w is TextField && w.focusNode != null);
    final ctl = tester.widget<TextField>(bodyField).controller!;
    await tester.ensureVisible(bodyField);
    ctl.value = const TextEditingValue(text: 'ไปที่ [[ท่า', selection: TextSelection.collapsed(offset: 11));
    await settle(tester);
    expect(find.text('ลิงก์ไปยัง…'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(InkWell), matching: find.text('ท่าเรือโคราล')).last);
    await settle(tester);
    expect(ctl.text, 'ไปที่ [[ท่าเรือโคราล]]');

    // Autosave lands in the database after the debounce.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.runAsync(() async {
      final saved = (await Repository(db).entriesOfWorld((await Repository(db).worlds()).first.id)).firstWhere((e) => e.title == 'ไลรา วาเลน');
      expect(saved.body, 'ไปที่ [[ท่าเรือโคราล]]');
    });
    await stop(tester);
  });

  testWidgets('phone, large text: list, detail, dashboard, settings', (tester) async {
    await start(tester, size: phone, textScale: 1.5);

    await tester.tap(find.text('ไลรา วาเลน'));
    await settle(tester);
    await tester.pageBack();
    await settle(tester);

    await tester.tap(find.text('โลก').last); // bottom bar tab
    await settle(tester);
    expect(find.text('ตามประเภท'), findsOneWidget);
    await tester.pageBack();
    await settle(tester);

    await tester.tap(find.text('ตั้งค่า'));
    await settle(tester);
    expect(find.text('ส่งออกโลกนี้เป็น JSON'), findsOneWidget);
    await stop(tester);
  });

  testWidgets('phone, large text: first launch with an empty world', (tester) async {
    await start(tester, size: phone, textScale: 1.5, seed: false);
    expect(find.text('โลกนี้ยังว่างอยู่'), findsOneWidget);

    await tester.tap(find.text('โลก').last);
    await settle(tester);
    expect(find.text('สลับโลก'), findsOneWidget);
    await stop(tester);
  });

  testWidgets('desktop: three columns, dashboard, select, edit', (tester) async {
    await start(tester, size: desktop);

    expect(find.text('ภาพรวม'), findsOneWidget); // the tab
    expect(find.text('ตามประเภท'), findsOneWidget);
    expect(find.text('Backlinks'), findsNothing); // no entry selected yet

    await tester.tap(find.text('ไลรา วาเลน').first);
    await settle(tester);
    expect(find.text('Backlinks'), findsOneWidget);
    expect(find.text('ความสัมพันธ์'), findsOneWidget);

    await tester.tap(find.text('✎ แก้ไข'));
    await settle(tester);
    expect(find.text('ข้อมูลเฉพาะ'), findsOneWidget);
    expect(find.text('เสร็จ'), findsOneWidget);
    await stop(tester);
  });

  testWidgets('desktop: timeline groups by year, filters by participant, and the detail shows the date', (tester) async {
    await start(tester, size: desktop);

    await tester.tap(find.text('เส้นเวลา').first); // the tab, not the dashboard button
    await settle(tester);
    final timeline = find.byType(TimelineView);
    expect(find.descendant(of: timeline, matching: find.text('ปีที่ 401')), findsOneWidget);
    expect(find.descendant(of: timeline, matching: find.text('สมาคมเข็มทิศ')), findsOneWidget);

    await tester.tap(find.text('ทั้งหมด ▾'));
    await settle(tester);
    await tester.tap(find.text('เซเรน ดาห์').last); // only in the compass event
    await settle(tester);
    expect(find.descendant(of: timeline, matching: find.text('เข็มทิศไร้เหนือ')), findsOneWidget);
    expect(find.descendant(of: timeline, matching: find.text('พายุปีกำแพง')), findsNothing);
    expect(find.descendant(of: timeline, matching: find.text('สมาคมเข็มทิศ')), findsNothing);

    // The event's detail shows its span in the world's calendar.
    await tester.tap(find.descendant(of: timeline, matching: find.text('เข็มทิศไร้เหนือ')));
    await settle(tester);
    expect(find.text('2 เดือนคลื่น ปีที่ 401'), findsOneWidget);
    await stop(tester);
  });

  testWidgets('phone, large text: dashboard → timeline page', (tester) async {
    await start(tester, size: phone, textScale: 1.5);
    await tester.tap(find.text('โลก').last);
    await settle(tester);
    await tester.tap(find.text('เส้นเวลา'));
    await settle(tester);
    expect(find.text('ปีที่ 212'), findsOneWidget);
    expect(find.text('พายุปีกำแพง'), findsOneWidget);
    await stop(tester);
  });

  testWidgets('editing an event keeps its date and participants (autosave must not wipe the timeline)', (tester) async {
    await start(tester, size: phone, textScale: 1.3);
    await tester.scrollUntilVisible(find.text('พายุปีกำแพง'), 100, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('พายุปีกำแพง'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('พายุปีกำแพง'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await settle(tester);

    // The editor shows the stored date.
    final timelineSwitch = find.byType(Switch);
    await tester.ensureVisible(timelineSwitch);
    expect(tester.widget<Switch>(timelineSwitch).value, isTrue);
    expect(find.text('401'), findsNWidgets(2)); // start year and end year
    expect(find.widgetWithText(InputChip, 'ไลรา วาเลน'), findsOneWidget);

    // Change an unrelated field.
    final summary = find.byWidgetPredicate((w) => w is TextField && w.controller?.text.startsWith('พายุที่จมเรือ') == true);
    await tester.enterText(summary, 'แก้สรุปแล้ว');
    await tester.pump(const Duration(milliseconds: 700));

    await tester.runAsync(() async {
      final repo = Repository(db);
      final wid = (await repo.worlds()).first.id;
      final storm = (await repo.timelineOfWorld(wid)).firstWhere((t) => t.entry.title == 'พายุปีกำแพง');
      expect(storm.entry.summary, 'แก้สรุปแล้ว');
      expect(storm.start.year, 401);
      expect(storm.start.month, 3);
      expect(storm.start.day, 12);
      expect(storm.end?.day, 13);
      expect(storm.participantIds.length, 3);
    });
    await stop(tester);
  });

  testWidgets('editing: switching the timeline off removes the date', (tester) async {
    await start(tester, size: desktop);
    await tester.tap(find.text('พายุปีกำแพง').first);
    await settle(tester);
    await tester.tap(find.text('✎ แก้ไข'));
    await settle(tester);

    final timelineSwitch = find.byType(Switch);
    await tester.ensureVisible(timelineSwitch);
    await tester.tap(timelineSwitch);
    await tester.pump(const Duration(milliseconds: 700));

    await tester.runAsync(() async {
      final repo = Repository(db);
      final items = await repo.timelineOfWorld((await repo.worlds()).first.id);
      expect(items.any((t) => t.entry.title == 'พายุปีกำแพง'), isFalse);
      expect(items, isNotEmpty); // the others are untouched
    });
    await stop(tester);
  });

  testWidgets('narrow desktop window falls back to the single-column layout', (tester) async {
    await start(tester, size: const Size(800, 700));
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await stop(tester);
  });
}

/// Pumps a few frames; the app has no endless animations, but drift streams need turns.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
