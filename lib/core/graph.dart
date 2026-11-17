import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../data/database.dart';
import '../data/repository.dart' show decodeList;
import 'wiki_links.dart';

/// One line on the graph: every relation (and optionally `[[link]]`) between a pair of entries.
class GraphEdge {
  const GraphEdge({required this.a, required this.b, required this.labels, required this.isLink, this.aToB});

  /// Entry ids, with `a.compareTo(b) < 0`.
  final String a;
  final String b;

  /// Relation names ("ศัตรู", "สังกัด"…) between the pair; empty for a pure `[[link]]` edge.
  final List<String> labels;
  final bool isLink;

  /// True if every relation points a→b, false if all point b→a, null if mixed or there are none.
  final bool? aToB;
}

class Graph {
  const Graph({required this.nodes, required this.edges});
  final List<Entry> nodes;
  final List<GraphEdge> edges;

  Map<String, int> get degree {
    final d = {for (final n in nodes) n.id: 0};
    for (final e in edges) {
      d[e.a] = (d[e.a] ?? 0) + 1;
      d[e.b] = (d[e.b] ?? 0) + 1;
    }
    return d;
  }
}

/// Relation names in [relations] with how many times each is used, most used first.
List<MapEntry<String, int>> relationTypeCounts(List<Relation> relations) {
  final counts = <String, int>{};
  for (final r in relations) {
    counts[r.type] = (counts[r.type] ?? 0) + 1;
  }
  return counts.entries.toList()..sort((x, y) => y.value != x.value ? y.value.compareTo(x.value) : x.key.compareTo(y.key));
}

/// Builds the visible graph.
///
/// - [hiddenTypes]: relation names to leave out.
/// - [includeLinks]: also draw an edge for each `[[link]]` in a body (resolved by title, then alias).
/// - [showIsolated]: keep entries that have no visible edge.
/// - [focusId]/[depth]: keep only entries within [depth] hops of the focused entry.
Graph buildGraph({
  required List<Entry> entries,
  required List<Relation> relations,
  Set<String> hiddenTypes = const {},
  bool includeLinks = false,
  bool showIsolated = false,
  String? focusId,
  int depth = 1,
}) {
  final byId = {for (final e in entries) e.id: e};
  final pairs = <String, _PairBuilder>{};

  _PairBuilder pair(String x, String y) {
    final a = x.compareTo(y) < 0 ? x : y, b = a == x ? y : x;
    return pairs.putIfAbsent('$a|$b', () => _PairBuilder(a, b));
  }

  for (final r in relations) {
    if (hiddenTypes.contains(r.type) || r.fromEntry == r.toEntry) continue;
    if (!byId.containsKey(r.fromEntry) || !byId.containsKey(r.toEntry)) continue;
    pair(r.fromEntry, r.toEntry).addRelation(r.type, from: r.fromEntry);
  }

  if (includeLinks) {
    final byName = <String, Entry>{};
    for (final e in entries) {
      for (final alias in decodeList(e.aliases)) {
        byName.putIfAbsent(alias, () => e);
      }
    }
    for (final e in entries) {
      byName[e.title] = e; // titles win over aliases, as in the reader
    }
    for (final e in entries) {
      for (final name in extractLinks(e.body)) {
        final target = byName[name];
        if (target != null && target.id != e.id) pair(e.id, target.id).hasLink = true;
      }
    }
  }

  var edges = [for (final p in pairs.values) p.build()];
  var nodes = entries;

  if (focusId != null && byId.containsKey(focusId)) {
    final keep = {focusId};
    var frontier = {focusId};
    for (var hop = 0; hop < depth; hop++) {
      final next = <String>{};
      for (final e in edges) {
        if (frontier.contains(e.a) && !keep.contains(e.b)) next.add(e.b);
        if (frontier.contains(e.b) && !keep.contains(e.a)) next.add(e.a);
      }
      keep.addAll(next);
      frontier = next;
    }
    nodes = entries.where((e) => keep.contains(e.id)).toList();
    edges = edges.where((e) => keep.contains(e.a) && keep.contains(e.b)).toList();
  } else if (!showIsolated) {
    final connected = {for (final e in edges) ...[e.a, e.b]};
    nodes = entries.where((e) => connected.contains(e.id)).toList();
  }

  nodes = [...nodes]..sort((x, y) => x.title.compareTo(y.title));
  return Graph(nodes: nodes, edges: edges);
}

class _PairBuilder {
  _PairBuilder(this.a, this.b);
  final String a;
  final String b;
  final labels = <String>[];
  var _forward = 0, _backward = 0;
  var hasLink = false;

  void addRelation(String label, {required String from}) {
    if (!labels.contains(label)) labels.add(label);
    from == a ? _forward++ : _backward++;
  }

  GraphEdge build() => GraphEdge(
        a: a,
        b: b,
        labels: labels,
        isLink: labels.isEmpty,
        aToB: _forward > 0 && _backward == 0 ? true : (_backward > 0 && _forward == 0 ? false : null),
      );
}

/// Force-directed layout (Fruchterman–Reingold). Deterministic: the same graph
/// and starting positions always give the same result.
///
/// [start] keeps nodes where they are (new nodes are spiralled around the centre),
/// [pinned] nodes never move. Returns a position for every node.
Map<String, Offset> layoutGraph(
  Graph g, {
  Map<String, Offset> start = const {},
  Set<String> pinned = const {},
  int iterations = 250,
  double spacing = 130,
}) {
  final n = g.nodes.length;
  if (n == 0) return {};
  final ids = [for (final e in g.nodes) e.id];
  final index = {for (var i = 0; i < n; i++) ids[i]: i};

  final pos = List<Offset>.generate(n, (i) {
    final known = start[ids[i]];
    if (known != null) return known;
    // Golden-angle spiral: spread out, never overlapping, stable by index.
    final r = spacing * 0.55 * math.sqrt(i + 1);
    final t = i * 2.399963229728653;
    return Offset(r * math.cos(t), r * math.sin(t));
  });
  if (n == 1) return {ids[0]: pinned.contains(ids[0]) ? pos[0] : (start[ids[0]] ?? Offset.zero)};

  final edgeIdx = [
    for (final e in g.edges)
      if (index.containsKey(e.a) && index.containsKey(e.b)) (index[e.a]!, index[e.b]!),
  ];
  final fixed = [for (final id in ids) pinned.contains(id)];
  final k = spacing;

  for (var it = 0; it < iterations; it++) {
    final temp = spacing * (1 - it / iterations) + 1;
    final disp = List<Offset>.filled(n, Offset.zero);

    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        var d = pos[i] - pos[j];
        var dist = d.distance;
        if (dist < 0.01) {
          d = Offset((i - j) * 0.5, 0.3);
          dist = d.distance;
        }
        final f = (k * k) / dist; // repulsion
        final push = d / dist * f;
        disp[i] += push;
        disp[j] -= push;
      }
    }
    for (final (a, b) in edgeIdx) {
      final d = pos[a] - pos[b];
      final dist = math.max(d.distance, 0.01);
      final pull = d / dist * (dist * dist / k); // attraction
      disp[a] -= pull;
      disp[b] += pull;
    }
    for (var i = 0; i < n; i++) {
      if (fixed[i]) continue;
      disp[i] -= pos[i] * 0.04; // gravity keeps separate clusters on screen together
      final len = disp[i].distance;
      if (len > 0) pos[i] += disp[i] / len * math.min(len, temp);
    }
  }
  return {for (var i = 0; i < n; i++) ids[i]: pos[i]};
}
