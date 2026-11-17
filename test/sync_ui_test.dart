import 'dart:io';

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
import 'package:nsl_writer_tools/data/sync_prefs.dart';
import 'package:nsl_writer_tools/providers.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase db;

  Future<void> openSettings(WidgetTester tester, {required Size size, double textScale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.runAsync(() async {
      final repo = Repository(db);
      final w = await repo.createWorld('หมู่เกาะเงาจันทร์');
      await seedSampleWorld(repo, w.id);
    });
    await tester.pumpWidget(ProviderScope(overrides: [databaseProvider.overrideWithValue(db)], child: const NslApp()));
    await settle(tester);

    if (size.width >= 900) {
      await tester.tap(find.byIcon(Icons.settings_outlined));
    } else {
      await tester.tap(find.text('ตั้งค่า'));
    }
    await settle(tester);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
    await tester.runAsync(db.close);
  }

  testWidgets('phone, large text: settings lists the four sync actions', (tester) async {
    await openSettings(tester, size: const Size(360, 760), textScale: 1.5);
    for (final label in ['รับซิงก์ผ่าน Wi-Fi', 'ซิงก์กับอีกเครื่อง', 'ส่งออกไฟล์ซิงก์', 'รวมจากไฟล์ซิงก์']) {
      await tester.scrollUntilVisible(find.text(label), 120, scrollable: find.byType(Scrollable).first);
      expect(find.text(label), findsOneWidget);
    }
    await close(tester);
  });

  testWidgets('connect dialog: explains missing address and code, and does not close', (tester) async {
    await openSettings(tester, size: const Size(360, 760), textScale: 1.5);
    await tester.scrollUntilVisible(find.text('ซิงก์กับอีกเครื่อง'), 120, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('ซิงก์กับอีกเครื่อง'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('ซิงก์กับอีกเครื่อง'));
    await settle(tester);
    expect(find.text('ซิงก์กับอีกเครื่อง'), findsNWidgets(2)); // the tile and the dialog title

    await tester.tap(find.text('ซิงก์')); // nothing typed
    await settle(tester);
    expect(find.textContaining('ใส่ที่อยู่ของอีกเครื่อง'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '192.168.1.20');
    await tester.tap(find.text('ซิงก์'));
    await settle(tester);
    expect(find.textContaining('ใส่รหัสจับคู่'), findsOneWidget);

    await tester.tap(find.text('ยกเลิก'));
    await settle(tester);
    expect(find.byType(AlertDialog), findsNothing);
    await close(tester);
  });

  testWidgets('desktop: settings dialog has the sync section too', (tester) async {
    await openSettings(tester, size: const Size(1280, 820));
    expect(find.text('รับซิงก์ผ่าน Wi-Fi'), findsOneWidget);
    expect(find.text('ซิงก์กับอีกเครื่อง'), findsOneWidget);
    await close(tester);
  });

  testWidgets('host dialog: starts listening, shows a 6-digit code, and stops when closed', (tester) async {
    await openSettings(tester, size: const Size(360, 760), textScale: 1.5);
    await tester.scrollUntilVisible(find.text('รับซิงก์ผ่าน Wi-Fi'), 120, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('รับซิงก์ผ่าน Wi-Fi'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('รับซิงก์ผ่าน Wi-Fi'));
    // The server binds a real socket and lists network interfaces, which need real time
    // rather than the test's fake clock. Poll instead of guessing a delay.
    final sw = Stopwatch()..start();
    while (find.text('รหัสจับคู่').evaluate().isEmpty && sw.elapsedMilliseconds < 8000) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(sw.elapsedMilliseconds, lessThan(8000), reason: 'the host dialog never finished starting');

    expect(find.text('รหัสจับคู่'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^\d{6}$')), findsOneWidget);
    expect(find.textContaining('กำลังรอการเชื่อมต่อ'), findsOneWidget);

    await tester.tap(find.text('หยุดรับซิงก์'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100))); // socket closing
    await settle(tester); // dialog's exit animation
    expect(find.text('รหัสจับคู่'), findsNothing);
    await close(tester);
  });

  test('the remembered address survives restarts, and a broken file means "nothing remembered"', () async {
    final dir = await Directory.systemTemp.createTemp('nsl_prefs');
    addTearDown(() => dir.delete(recursive: true));
    final prefs = SyncPrefs(dir: dir);
    expect(await prefs.lastAddress(), '');
    await prefs.saveLastAddress('192.168.1.20:48765');
    expect(await SyncPrefs(dir: dir).lastAddress(), '192.168.1.20:48765');
    await File('${dir.path}/sync_prefs.json').writeAsString('{ not json');
    expect(await prefs.lastAddress(), '');
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
