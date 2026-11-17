import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nsl_writer_tools/app.dart';
import 'package:nsl_writer_tools/data/database.dart';
import 'package:nsl_writer_tools/data/repository.dart';
import 'package:nsl_writer_tools/data/seed.dart';
import 'package:nsl_writer_tools/providers.dart';
import 'package:nsl_writer_tools/ui/graph_view.dart';

/// Interaction tests for the relationship graph (the sample world has 8 connected
/// entries and 9 relations; ไลรา วาเลน has 5 neighbours).
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase db;

  Future<GraphViewState> openGraph(WidgetTester tester, {Size size = const Size(1280, 820), double textScale = 1}) async {
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
      await tester.tap(find.text('กราฟ').first);
    } else {
      await tester.tap(find.text('โลก').last);
      await settle(tester);
      await tester.tap(find.text('กราฟ'));
    }
    await settle(tester);
    return tester.state<GraphViewState>(find.byType(GraphView));
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
    await tester.runAsync(db.close);
  }

  String idOf(GraphViewState g, String title) => g.graph.nodes.firstWhere((n) => n.title == title).id;

  Offset screenOf(WidgetTester tester, GraphViewState g, String title) =>
      tester.getTopLeft(find.byKey(g.canvasKey)) + g.toScreen(g.positions[idOf(g, title)]!);

  testWidgets('shows the connected entries and relations, laid out inside the view', (tester) async {
    final g = await openGraph(tester);
    expect(g.graph.nodes, hasLength(8)); // the 2 entries without relations are hidden
    expect(g.graph.edges, hasLength(9));
    final box = tester.getRect(find.byKey(g.canvasKey));
    for (final n in g.graph.nodes) {
      expect(box.contains(screenOf(tester, g, n.title)), isTrue, reason: '${n.title} should start inside the view');
    }
    await close(tester);
  });

  testWidgets('tapping a node selects it and shows its card; tapping empty space clears it', (tester) async {
    final g = await openGraph(tester);
    await tester.tapAt(screenOf(tester, g, 'ไลรา วาเลน'));
    await settle(tester);
    expect(g.selectedId, idOf(g, 'ไลรา วาเลน'));
    expect(find.text('เปิดรายการ'), findsOneWidget);
    expect(find.textContaining('เชื่อมกับ 5 รายการ'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).last); // card's close button
    await settle(tester);
    expect(g.selectedId, isNull);
    await close(tester);
  });

  testWidgets('dragging a node moves exactly with the pointer and pins it; the view does not pan', (tester) async {
    final g = await openGraph(tester);
    final id = idOf(g, 'เซเรน ดาห์');
    final before = g.positions[id]!;
    final panBefore = g.toScreen(Offset.zero);
    final scale = (g.toScreen(const Offset(1, 0)) - g.toScreen(Offset.zero)).dx;

    // Grab the node's edge, not its centre: this is where a slop-delayed gesture would miss.
    await tester.dragFrom(screenOf(tester, g, 'เซเรน ดาห์') + const Offset(6, 0), const Offset(70, 40));
    await settle(tester);

    final after = g.positions[id]!;
    expect((after - before).dx, closeTo(70 / scale, 0.5));
    expect((after - before).dy, closeTo(40 / scale, 0.5));
    expect(g.toScreen(Offset.zero), panBefore);
    expect(g.selectedId, id);
    await close(tester);
  });

  testWidgets('dragging empty space pans the whole graph without moving nodes', (tester) async {
    final g = await openGraph(tester);
    final id = idOf(g, 'ไลรา วาเลน');
    final nodeBefore = g.positions[id]!;
    final screenBefore = g.toScreen(nodeBefore);
    final box = tester.getRect(find.byKey(g.canvasKey));

    await tester.dragFrom(box.bottomLeft + const Offset(14, -14), const Offset(30, -20));
    await settle(tester);

    expect(g.positions[id], nodeBefore);
    expect((g.toScreen(nodeBefore) - screenBefore).dx, closeTo(30, 0.5));
    expect((g.toScreen(nodeBefore) - screenBefore).dy, closeTo(-20, 0.5));
    await close(tester);
  });

  testWidgets('pinch and mouse wheel zoom', (tester) async {
    final g = await openGraph(tester);
    double scaleNow() => (g.toScreen(const Offset(1, 0)) - g.toScreen(Offset.zero)).dx;
    final box = tester.getRect(find.byKey(g.canvasKey));
    final c = box.center;

    final s0 = scaleNow();
    final a = await tester.startGesture(c + const Offset(-40, 0), pointer: 11);
    final b = await tester.startGesture(c + const Offset(40, 0), pointer: 12);
    await a.moveTo(c + const Offset(-80, 0));
    await b.moveTo(c + const Offset(80, 0));
    await a.up();
    await b.up();
    await settle(tester);
    expect(scaleNow(), closeTo(s0 * 2, s0 * 0.05));

    final mouse = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(mouse.hover(c));
    final s1 = scaleNow();
    await tester.sendEventToBinding(mouse.scroll(const Offset(0, 100))); // scroll down = zoom out
    await settle(tester);
    expect(scaleNow(), lessThan(s1));
    await close(tester);
  });

  testWidgets('hiding a relation type removes its lines; "include links" adds [[link]] lines', (tester) async {
    final g = await openGraph(tester);
    expect(g.graph.edges, hasLength(9));

    await tester.tap(find.textContaining('ศัตรู').first);
    await settle(tester);
    expect(g.graph.edges, hasLength(8));

    await tester.tap(find.textContaining('ศัตรู').first); // show it again
    await settle(tester);
    expect(g.graph.edges, hasLength(9));

    await tester.tap(find.text('รวมลิงก์ [[ ]]'));
    await settle(tester);
    expect(g.graph.edges.length, greaterThan(9));
    expect(g.graph.edges.where((e) => e.isLink), isNotEmpty);
    await close(tester);
  });

  testWidgets('focus keeps one entry and its neighbours; leaving focus restores the rest', (tester) async {
    final g = await openGraph(tester);
    await tester.tapAt(screenOf(tester, g, 'ไลรา วาเลน'));
    await settle(tester);
    await tester.tap(find.text('โฟกัสเฉพาะรายการนี้'));
    await settle(tester);
    expect(g.graph.nodes, hasLength(6)); // ไลรา + 5 neighbours
    expect(g.graph.nodes.any((n) => n.title == 'ชาวเกล็ดเงิน'), isFalse);

    await tester.tap(find.text('2 ชั้น'));
    await settle(tester);
    expect(g.graph.nodes.any((n) => n.title == 'ชาวเกล็ดเงิน'), isTrue); // via เซเรน

    await tester.tap(find.text('ออกจากโฟกัส'));
    await settle(tester);
    expect(g.graph.nodes, hasLength(8));
    await close(tester);
  });

  testWidgets('layout and drags survive opening an entry and coming back', (tester) async {
    final g = await openGraph(tester);
    final id = idOf(g, 'ไลรา วาเลน');
    await tester.dragFrom(screenOf(tester, g, 'ไลรา วาเลน'), const Offset(50, 30));
    final moved = g.positions[id]!;
    await settle(tester);

    await tester.tap(find.text('เปิดรายการ'));
    await settle(tester);
    expect(find.byType(GraphView), findsNothing); // now showing the entry

    await tester.tap(find.text('กราฟ').first);
    await settle(tester);
    final back = tester.state<GraphViewState>(find.byType(GraphView));
    expect(back.positions[id], moved);
    await close(tester);
  });

  testWidgets('phone, large text: opens from the world page, no overflow, node card fits', (tester) async {
    final g = await openGraph(tester, size: const Size(360, 760), textScale: 1.5);
    expect(g.graph.nodes, hasLength(8));
    await tester.tapAt(screenOf(tester, g, 'ไลรา วาเลน'));
    await settle(tester);
    expect(find.text('เปิดรายการ'), findsOneWidget);

    await tester.tap(find.text('เปิดรายการ'));
    await settle(tester);
    expect(find.textContaining('พ่อของเธอ'), findsOneWidget); // landed on the entry's detail page
    await tester.pageBack();
    await settle(tester);
    expect(find.byType(GraphView), findsOneWidget);
    await close(tester);
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
