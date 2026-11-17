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
import 'package:nsl_writer_tools/data/theme_prefs.dart';
import 'package:nsl_writer_tools/providers.dart';
import 'package:nsl_writer_tools/theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + .05) / (lo + .05);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  tearDown(() => C.p = Palette.light);

  group('palettes', () {
    for (final entry in {'light': Palette.light, 'night': Palette.dark}.entries) {
      final p = entry.value;
      test('${entry.key}: text and badges are readable', () {
        expect(_contrast(p.ink, p.bg), greaterThan(10));
        expect(_contrast(p.body, p.bg), greaterThan(7));
        expect(_contrast(p.inkSoft, p.bg), greaterThan(7));
        expect(_contrast(p.inkFaint, p.bg), greaterThan(4.5));
        expect(_contrast(p.inkFaint, p.bgPanel), greaterThan(4.5));
        expect(_contrast(p.danger, p.bg), greaterThan(4.5));
        // Lines and outlines must be visible, not just present.
        expect(_contrast(p.line, p.bg), greaterThan(1.4), reason: 'panel lines');
        expect(_contrast(p.lineInput, p.bg), greaterThan(2.4), reason: 'input / button outlines');
        expect(_contrast(p.border, p.bg), greaterThan(1.8));
        expect(_contrast(p.edge, p.bg), greaterThan(3), reason: 'graph edges');
        expect(_contrast(p.selected, p.bg), greaterThan(1.1), reason: 'selected row');
        expect(_contrast(p.accent, p.bg), greaterThan(4.5));
        expect(_contrast(p.accent, p.accentTint), greaterThan(4));
        expect(_contrast(p.summary, p.bg), greaterThan(7));
        expect(_contrast(p.snippet, p.bgPanel), greaterThan(4.5));
        for (final t in EntryType.values) {
          // The type glyph is drawn in the page colour on the type colour.
          expect(_contrast(p.bg, p.types[t]!), greaterThan(4), reason: '$t glyph');
          expect(_contrast(p.types[t]!, p.bg), greaterThan(4), reason: '$t as text');
        }
        for (final s in EntryStatus.values) {
          expect(_contrast(p.statuses[s]!.$2, p.statuses[s]!.$1), greaterThan(4.5), reason: '$s badge');
        }
      });
    }
    test('every type and status has a colour in both palettes', () {
      for (final p in [Palette.light, Palette.dark]) {
        expect(p.types.keys.toSet(), EntryType.values.toSet());
        expect(p.statuses.keys.toSet(), EntryStatus.values.toSet());
      }
    });
    test('typeMeta / statusMeta follow the palette in force', () {
      final light = typeMeta[EntryType.place]!.color;
      C.p = Palette.dark;
      expect(typeMeta[EntryType.place]!.color, isNot(light));
      expect(statusMeta[EntryStatus.canon]!.bg, Palette.dark.statuses[EntryStatus.canon]!.$1);
    });
  });

  test('ThemePrefs: remembers the mode; bad or missing file means system', () async {
    final dir = await Directory.systemTemp.createTemp('theme_prefs');
    addTearDown(() => dir.delete(recursive: true));
    final prefs = ThemePrefs(dir: dir);
    expect(await prefs.load(), ThemeMode.system);
    await prefs.save(ThemeMode.dark);
    expect(await ThemePrefs(dir: dir).load(), ThemeMode.dark);
    await File('${dir.path}/theme_prefs.json').writeAsString('{"mode":"purple"}');
    expect(await prefs.load(), ThemeMode.system);
    await File('${dir.path}/theme_prefs.json').writeAsString('not json');
    expect(await prefs.load(), ThemeMode.system);
  });

  group('app', () {
    late AppDatabase db;
    late Directory dir;

    Future<void> start(WidgetTester tester, Size size, {double textScale = 1}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.runAsync(() async {
        dir = await Directory.systemTemp.createTemp('theme_app');
        final repo = Repository(db);
        final w = await repo.createWorld('หมู่เกาะเงาจันทร์');
        await seedSampleWorld(repo, w.id);
      });
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          themePrefsProvider.overrideWithValue(ThemePrefs(dir: dir)),
        ],
        child: const NslApp(),
      ));
      await _settle(tester);
    }

    Future<void> stop(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 10));
      await tester.runAsync(() async {
        await db.close();
        try { await dir.delete(recursive: true); } catch (_) {}
      });
    }

    testWidgets('phone: switching to night restyles the open screen, keeps it, and is remembered', (tester) async {
      await start(tester, const Size(360, 760), textScale: 1.5);
      expect(C.isDark, isFalse);
      expect(find.text('ไลรา วาเลน'), findsOneWidget);

      await tester.tap(find.text('ตั้งค่า'));
      await _settle(tester);
      // Let the bundled font weights used by this page finish loading, so a late
      // font swap isn't mistaken for a theme problem.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await _settle(tester);
      expect(find.text('กลางคืน'), findsOneWidget);
      await tester.tap(find.text('กลางคืน'));
      await _settle(tester);

      expect(C.isDark, isTrue);
      expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, Brightness.dark);
      expect(Theme.of(tester.element(find.byType(Scaffold).first)).scaffoldBackgroundColor, Palette.dark.bg);
      // The settings page is still open and its heading now uses the night ink colour.
      expect(find.text('ธีม'), findsOneWidget);
      final heading = tester.widget<Text>(find.text('ธีม'));
      expect(heading.style!.color, Palette.dark.inkFaint);
      // The save is fire-and-forget (real file IO started from the fake-async zone):
      // alternate real time and pumps until it lands.
      var saved = ThemeMode.system;
      for (var i = 0; i < 20 && saved != ThemeMode.dark; i++) {
        saved = (await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return ThemePrefs(dir: dir).load();
        }))!;
        await tester.pump();
      }
      expect(saved, ThemeMode.dark);

      // Walk the other screens in night mode: any overflow or exception fails.
      await tester.pageBack();
      await _settle(tester);
      await tester.tap(find.text('ไลรา วาเลน'));
      await _settle(tester);
      expect(tester.takeException(), isNull);

      await tester.pageBack();
      await _settle(tester);
      await tester.tap(find.text('ตั้งค่า'));
      await _settle(tester);
      await tester.tap(find.text('สว่าง'));
      await _settle(tester);
      expect(C.isDark, isFalse);
      expect(Theme.of(tester.element(find.byType(Scaffold).first)).scaffoldBackgroundColor, Palette.light.bg);
      await stop(tester);
    });

    testWidgets('desktop: night mode from the settings dialog; dialog stays open', (tester) async {
      await start(tester, const Size(1280, 820));
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await _settle(tester);
      await tester.tap(find.text('กลางคืน'));
      await _settle(tester);
      expect(C.isDark, isTrue);
      expect(find.text('ตั้งค่า'), findsWidgets);
      expect(find.text('ธีม'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await stop(tester);
    });

    testWidgets('system mode follows the platform brightness', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await start(tester, const Size(1280, 820));
      expect(C.isDark, isTrue);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await _settle(tester);
      expect(C.isDark, isFalse);
      await stop(tester);
    });
  });
}
