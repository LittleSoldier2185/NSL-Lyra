import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/graph.dart';
import '../data/database.dart';
import '../providers.dart';
import '../theme.dart';
import 'entry_list.dart' show TypeGlyph;

/// Relationship graph: entries as nodes, relations (and optionally `[[links]]`) as lines.
/// Drag a node to move it (it then stays put), drag the background to pan,
/// pinch or scroll to zoom, tap a node to see its details.
class GraphView extends ConsumerStatefulWidget {
  const GraphView({super.key, required this.onOpen});
  final void Function(Entry) onOpen;

  @override
  ConsumerState<GraphView> createState() => GraphViewState();
}

class GraphViewState extends ConsumerState<GraphView> {
  late GraphSession _s;
  String? _sessionWorld;
  Graph _graph = const Graph(nodes: [], edges: []);
  String _signature = '';
  String? _selected;
  Size _size = Size.zero;

  // Raw pointer tracking. A GestureDetector's scale recognizer only starts after ~36px of
  // slop, which would make a grabbed node lag behind the finger, so pointers are handled here.
  final _pointers = <int, Offset>{};
  String? _dragging; // node under the first pointer, if any
  Offset _downPos = Offset.zero;
  bool _moved = false;
  double _pinchStartDist = 1, _pinchStartScale = 1;
  Offset _lastFocal = Offset.zero;
  static const double _tapSlop = 6;
  final canvasKey = GlobalKey();

  @visibleForTesting
  Map<String, Offset> get positions => _s.positions;
  @visibleForTesting
  String? get selectedId => _selected;
  @visibleForTesting
  Graph get graph => _graph;

  /// Screen position (inside the canvas) of a world-space point.
  Offset toScreen(Offset w) => w * _s.scale + _s.pan;
  Offset _toWorld(Offset s) => (s - _s.pan) / _s.scale;

  static const double _minScale = 0.15, _maxScale = 3;

  double _radius(String id) => 13.0 + math.min(_graph.degree[id] ?? 0, 8) * 1.4;

  String? _hit(Offset screen) {
    final w = _toWorld(screen);
    String? best;
    var bestD = double.infinity;
    for (final n in _graph.nodes) {
      final p = _s.positions[n.id];
      if (p == null) continue;
      final d = (p - w).distance;
      // Generous slop (in screen pixels) so fingers can hit small nodes.
      if (d * _s.scale <= _radius(n.id) * _s.scale + 8 && d < bestD) {
        best = n.id;
        bestD = d;
      }
    }
    return best;
  }

  void _fit() {
    if (_graph.nodes.isEmpty || _size.isEmpty) return;
    var minX = double.infinity, maxX = -double.infinity, minY = double.infinity, maxY = -double.infinity;
    for (final n in _graph.nodes) {
      final p = _s.positions[n.id];
      if (p == null) continue;
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    const margin = 70.0;
    final w = math.max(maxX - minX, 1) + margin * 2, h = math.max(maxY - minY, 1) + margin * 2;
    final scale = math.min(_size.width / w, _size.height / h).clamp(_minScale, 1.2);
    final centre = Offset((minX + maxX) / 2, (minY + maxY) / 2);
    _s.scale = scale;
    _s.pan = Offset(_size.width / 2, _size.height / 2) - centre * scale;
    _s.fitted = true;
  }

  /// Recomputes the visible graph; lays out again only when its nodes or edges changed.
  void _sync(List<Entry> entries, List<Relation> relations, String worldId) {
    if (_sessionWorld != worldId) {
      _sessionWorld = worldId;
      _s = ref.read(graphSessionProvider(worldId));
      _signature = '';
      _selected = null;
    }
    _graph = buildGraph(
      entries: entries,
      relations: relations,
      hiddenTypes: _s.hiddenTypes,
      includeLinks: _s.includeLinks,
      showIsolated: _s.showIsolated,
      focusId: _s.focusId,
      depth: _s.depth,
    );
    final sig = '${_graph.nodes.map((n) => n.id).join(',')}|${_graph.edges.map((e) => '${e.a}${e.b}').join(',')}';
    if (sig == _signature) return;
    final first = _s.positions.isEmpty;
    _signature = sig;
    final pos = layoutGraph(
      _graph,
      start: _s.positions,
      pinned: _s.pinned,
      iterations: first ? 260 : 180, // existing nodes start where they are; new edges need room to spread
    );
    _s.positions
      ..clear()
      ..addAll(pos);
    if (first) _s.fitted = false;
    if (_selected != null && !_graph.nodes.any((n) => n.id == _selected)) _selected = null;
  }

  void _relayoutAll() {
    setState(() {
      _s.pinned.clear();
      _s.positions.clear();
      _signature = '';
      _s.fitted = false;
    });
  }

  void _pointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length == 1) {
      _downPos = e.localPosition;
      _moved = false;
      _dragging = _hit(e.localPosition);
    } else if (_pointers.length == 2) {
      _dragging = null; // a second finger turns the gesture into pan/zoom
      _moved = true;
      final pts = _pointers.values.toList();
      _pinchStartDist = math.max((pts[0] - pts[1]).distance, 1);
      _pinchStartScale = _s.scale;
      _lastFocal = (pts[0] + pts[1]) / 2;
    }
  }

  void _pointerMove(PointerMoveEvent e) {
    final prev = _pointers[e.pointer];
    if (prev == null) return;
    _pointers[e.pointer] = e.localPosition;
    setState(() {
      if (_pointers.length >= 2) {
        final pts = _pointers.values.take(2).toList();
        final focal = (pts[0] + pts[1]) / 2;
        final dist = math.max((pts[0] - pts[1]).distance, 1);
        _s.pan += focal - _lastFocal;
        _lastFocal = focal;
        final next = (_pinchStartScale * dist / _pinchStartDist).clamp(_minScale, _maxScale);
        _zoomAround(focal, next / _s.scale);
        return;
      }
      if (!_moved) {
        if ((e.localPosition - _downPos).distance <= _tapSlop) return;
        _moved = true;
        _move(e.localPosition - _downPos); // catch up on what the slop swallowed
        return;
      }
      _move(e.localPosition - prev);
    });
  }

  /// Moves the grabbed node, or pans the view when the background was grabbed.
  void _move(Offset screenDelta) {
    final id = _dragging;
    if (id != null) {
      _s.positions[id] = _s.positions[id]! + screenDelta / _s.scale;
      _s.pinned.add(id);
      _selected = id;
    } else {
      _s.pan += screenDelta;
    }
  }

  void _pointerUp(PointerEvent e, {required bool cancelled}) {
    final wasSingle = _pointers.length == 1;
    _pointers.remove(e.pointer);
    if (_pointers.length == 1) {
      // Back to one finger after a pinch: keep panning from here, don't treat it as a tap.
      _downPos = _pointers.values.first;
      _dragging = null;
      _moved = true;
    }
    if (wasSingle && !_moved && !cancelled) {
      final id = _hit(e.localPosition);
      setState(() => _selected = id == _selected ? null : id);
    }
    if (_pointers.isEmpty) _dragging = null;
  }

  void _zoomAround(Offset focal, double factor) {
    final next = (_s.scale * factor).clamp(_minScale, _maxScale);
    final k = next / _s.scale;
    _s.pan = focal - (focal - _s.pan) * k;
    _s.scale = next;
  }

  @override
  Widget build(BuildContext context) {
    final world = ref.watch(activeWorldProvider);
    if (world == null) return const SizedBox.shrink();
    final entries = ref.watch(allEntriesProvider);
    final relations = ref.watch(worldRelationsProvider).value ?? const <Relation>[];
    _sync(entries, relations, world.id);
    final types = relationTypeCounts(relations);

    return Column(children: [
      _Toolbar(
        types: types,
        session: _s,
        onChanged: () => setState(() {}),
        onRelayout: _relayoutAll,
        onFit: () => setState(_fit),
      ),
      Divider(height: 1, color: C.line),
      Expanded(
        child: LayoutBuilder(builder: (context, c) {
          _size = Size(c.maxWidth, c.maxHeight);
          if (!_s.fitted && _graph.nodes.isNotEmpty) _fit();
          return Stack(children: [
            Positioned.fill(
              child: Listener(
                key: canvasKey,
                behavior: HitTestBehavior.opaque,
                onPointerDown: _pointerDown,
                onPointerMove: _pointerMove,
                onPointerUp: (e) => _pointerUp(e, cancelled: false),
                onPointerCancel: (e) => _pointerUp(e, cancelled: true),
                onPointerSignal: (e) {
                  if (e is PointerScrollEvent) {
                    setState(() => _zoomAround(e.localPosition, math.exp(-e.scrollDelta.dy / 400)));
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _GraphPainter(
                      graph: _graph,
                      positions: _s.positions,
                      scale: _s.scale,
                      pan: _s.pan,
                      selected: _selected,
                      radius: _radius,
                    ),
                  ),
                ),
              ),
            ),
            if (_graph.nodes.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    relations.isEmpty && !_s.includeLinks
                        ? 'ยังไม่มีความสัมพันธ์ให้แสดง — เพิ่มได้จากหน้ารายการ (“+ เพิ่มความสัมพันธ์”) หรือเปิด “รวมลิงก์ [[ ]]” ด้านบนเพื่อดูการอ้างถึงกัน'
                        : 'ไม่มีรายการที่ตรงกับตัวกรอง',
                    textAlign: TextAlign.center,
                    style: T.ui(14, color: C.inkFaint, h: 1.6),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              top: 8,
              child: Text('${_graph.nodes.length} รายการ · ${_graph.edges.length} เส้น', style: T.ui(11, color: C.inkFaint)),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Column(children: [
                _ZoomButton(icon: Icons.add, onTap: () => setState(() => _zoomAround(_size.center(Offset.zero), 1.25))),
                const SizedBox(height: 4),
                _ZoomButton(icon: Icons.remove, onTap: () => setState(() => _zoomAround(_size.center(Offset.zero), 0.8))),
              ]),
            ),
            if (_selected != null) Positioned(left: 12, right: 12, bottom: 12, child: _SelectionCard(
              entry: _graph.nodes.firstWhere((n) => n.id == _selected),
              degree: _graph.degree[_selected] ?? 0,
              focused: _s.focusId == _selected,
              depth: _s.depth,
              onOpen: widget.onOpen,
              onClose: () => setState(() => _selected = null),
              onFocus: (on) => setState(() {
                _s.focusId = on ? _selected : null;
                _s.fitted = false;
              }),
              onDepth: (d) => setState(() {
                _s.depth = d;
                _s.fitted = false;
              }),
            )),
          ]);
        }),
      ),
    ]);
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: C.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: C.lineInput)),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 18, color: C.inkSoft)),
        ),
      );
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.types, required this.session, required this.onChanged, required this.onRelayout, required this.onFit});
  final List<MapEntry<String, int>> types;
  final GraphSession session;
  final VoidCallback onChanged;
  final VoidCallback onRelayout;
  final VoidCallback onFit;

  @override
  Widget build(BuildContext context) {
    Widget toggle(String label, bool on, ValueChanged<bool> set) => FilterChip(
          label: Text(label, style: T.ui(12, color: on ? C.accent : C.ink)),
          selected: on,
          showCheckmark: false,
          selectedColor: C.accentTint,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: on ? C.accentLine : C.lineInput),
          visualDensity: VisualDensity.compact,
          onSelected: (v) {
            set(v);
            session.fitted = false;
            onChanged();
          },
        );

    final items = <Widget>[
      Text('ชนิด', style: T.ui(12, color: C.inkFaint)),
      for (final t in types)
        FilterChip(
          label: Text('${t.key}  ${t.value}', style: T.ui(12, color: session.hiddenTypes.contains(t.key) ? C.inkFaint : C.ink)),
          selected: !session.hiddenTypes.contains(t.key),
          showCheckmark: false,
          selectedColor: C.bg,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: session.hiddenTypes.contains(t.key) ? C.line : C.ink),
          visualDensity: VisualDensity.compact,
          onSelected: (on) {
            on ? session.hiddenTypes.remove(t.key) : session.hiddenTypes.add(t.key);
            session.fitted = false;
            onChanged();
          },
        ),
      if (types.isEmpty) Text('—', style: T.ui(12, color: C.inkFaint)),
      toggle('รวมลิงก์ [[ ]]', session.includeLinks, (v) => session.includeLinks = v),
      toggle('แสดงที่ไม่มีเส้น', session.showIsolated, (v) => session.showIsolated = v),
      TextButton(onPressed: onFit, child: Text('พอดีหน้าจอ', style: T.ui(12, color: C.accent))),
      TextButton(onPressed: onRelayout, child: Text('จัดเรียงใหม่', style: T.ui(12, color: C.accent))),
    ];

    return Container(
      color: C.bgBar,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      // Wide: wrap onto extra rows so nothing is hidden (a mouse can't scroll sideways).
      // Narrow: one scrollable row, to leave room for the graph.
      child: LayoutBuilder(
        builder: (_, c) => c.maxWidth >= 720
            ? Wrap(spacing: 6, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: items)
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [for (final w in items) Padding(padding: const EdgeInsets.only(right: 6), child: w)]),
              ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.entry,
    required this.degree,
    required this.focused,
    required this.depth,
    required this.onOpen,
    required this.onClose,
    required this.onFocus,
    required this.onDepth,
  });
  final Entry entry;
  final int degree;
  final bool focused;
  final int depth;
  final void Function(Entry) onOpen;
  final VoidCallback onClose;
  final ValueChanged<bool> onFocus;
  final ValueChanged<int> onDepth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: C.bg,
            border: Border.all(color: C.lineInput),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: const Color(0xFF3C2814).withValues(alpha: .18), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              TypeGlyph(entry.type, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(15, w: FontWeight.w600)),
                  Text('${typeMeta[entry.type]!.label} · เชื่อมกับ $degree รายการ', style: T.ui(12, color: C.inkSoft)),
                ]),
              ),
              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onClose),
            ]),
            if (entry.summary.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(entry.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.serif(13, color: C.inkSoft, h: 1.5)),
            ],
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: C.accent, visualDensity: VisualDensity.compact),
                onPressed: () => onOpen(entry),
                child: const Text('เปิดรายการ'),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, side: BorderSide(color: C.lineInput)),
                onPressed: () => onFocus(!focused),
                child: Text(focused ? 'ออกจากโฟกัส' : 'โฟกัสเฉพาะรายการนี้', style: T.ui(13, color: C.ink)),
              ),
              if (focused)
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  segments: const [ButtonSegment(value: 1, label: Text('1 ชั้น')), ButtonSegment(value: 2, label: Text('2 ชั้น'))],
                  selected: {depth},
                  onSelectionChanged: (s) => onDepth(s.first),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  _GraphPainter({
    required this.graph,
    required this.positions,
    required this.scale,
    required this.pan,
    required this.selected,
    required this.radius,
  });

  final Graph graph;
  final Map<String, Offset> positions;
  final double scale;
  final Offset pan;
  final String? selected;
  final double Function(String id) radius;

  Offset _p(String id) => positions[id]! * scale + pan;

  @override
  void paint(Canvas canvas, Size size) {
    final neighbours = <String>{};
    if (selected != null) {
      neighbours.add(selected!);
      for (final e in graph.edges) {
        if (e.a == selected) neighbours.add(e.b);
        if (e.b == selected) neighbours.add(e.a);
      }
    }
    bool dim(String id) => selected != null && !neighbours.contains(id);

    // Edges.
    for (final e in graph.edges) {
      if (!positions.containsKey(e.a) || !positions.containsKey(e.b)) continue;
      final a = _p(e.a), b = _p(e.b);
      final touches = selected != null && (e.a == selected || e.b == selected);
      final faded = selected != null && !touches;
      final paint = Paint()
        ..color = touches ? C.accent : C.edge.withValues(alpha: faded ? .35 : 1)
        ..strokeWidth = touches ? 3 : 1.8
        ..style = PaintingStyle.stroke;
      if (e.isLink) {
        _dashed(canvas, a, b, paint);
      } else {
        canvas.drawLine(a, b, paint);
        if (e.aToB != null) {
          final from = e.aToB! ? a : b, to = e.aToB! ? b : a;
          final toId = e.aToB! ? e.b : e.a;
          _arrow(canvas, from, to, radius(toId) * scale, paint..style = PaintingStyle.fill);
        }
      }
    }

    // Edge labels: always when zoomed in, otherwise only around the selected node.
    for (final e in graph.edges) {
      if (e.labels.isEmpty || !positions.containsKey(e.a) || !positions.containsKey(e.b)) continue;
      final touches = selected != null && (e.a == selected || e.b == selected);
      if (!touches && (scale < 0.9 || selected != null)) continue;
      final mid = (_p(e.a) + _p(e.b)) / 2;
      _label(canvas, e.labels.join(' · '), mid, color: touches ? C.accent : C.inkSoft, size: 13, background: true);
    }

    // Nodes.
    for (final n in graph.nodes) {
      final pos = positions[n.id];
      if (pos == null) continue;
      final c = _p(n.id);
      if (c.dx < -80 || c.dy < -80 || c.dx > size.width + 80 || c.dy > size.height + 80) continue;
      final r = radius(n.id) * scale.clamp(0.5, 1.6);
      final meta = typeMeta[n.type]!;
      final alpha = dim(n.id) ? 0.4 : 1.0;
      if (n.id == selected) {
        canvas.drawCircle(c, r + 5, Paint()..color = C.accent.withValues(alpha: .35));
      }
      canvas.drawCircle(c, r, Paint()..color = meta.color.withValues(alpha: alpha));
      canvas.drawCircle(
          c, r, Paint()..color = C.bg.withValues(alpha: alpha)..style = PaintingStyle.stroke..strokeWidth = 2);
      _label(canvas, meta.glyph, c, color: C.bg.withValues(alpha: alpha), size: math.max(12, r * .95), serif: true, weight: FontWeight.w600);
      final showTitle = scale >= 0.5 || n.id == selected || neighbours.contains(n.id);
      if (showTitle && !dim(n.id)) {
        _label(canvas, n.title, c + Offset(0, r + 10), color: C.ink, size: 14, weight: n.id == selected ? FontWeight.w600 : FontWeight.w400);
      }
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    for (var d = 0.0; d < total; d += 9) {
      canvas.drawLine(a + dir * d, a + dir * math.min(d + 5, total), paint);
    }
  }

  void _arrow(Canvas canvas, Offset from, Offset to, double targetRadius, Paint paint) {
    final v = to - from;
    final len = v.distance;
    if (len < targetRadius * 2) return;
    final dir = v / len;
    final tip = to - dir * (targetRadius + 2);
    final left = Offset(-dir.dy, dir.dx);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo((tip - dir * 9 + left * 4.5).dx, (tip - dir * 9 + left * 4.5).dy)
      ..lineTo((tip - dir * 9 - left * 4.5).dx, (tip - dir * 9 - left * 4.5).dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _label(Canvas canvas, String text, Offset centre,
      {required Color color, required double size, bool background = false, bool serif = false, FontWeight weight = FontWeight.w400}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: serif ? T.serif(size, w: weight, color: color) : T.ui(size, w: weight, color: color)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 160);
    final topLeft = centre - Offset(tp.width / 2, tp.height / 2);
    if (background) {
      final rect = RRect.fromRectAndRadius((topLeft & tp.size).inflate(3), const Radius.circular(4));
      canvas.drawRRect(rect, Paint()..color = C.bg.withValues(alpha: .92));
    }
    tp.paint(canvas, topLeft);
  }

  @override
  bool shouldRepaint(_GraphPainter old) => true;
}

/// Android page wrapper.
class MobileGraphPage extends ConsumerWidget {
  const MobileGraphPage({super.key, required this.onOpen});
  final void Function(Entry) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(
          backgroundColor: C.bg,
          surfaceTintColor: Colors.transparent,
          title: Text('กราฟความสัมพันธ์', style: T.ui(16, w: FontWeight.w600)),
        ),
        body: GraphView(onOpen: onOpen),
      );
}
