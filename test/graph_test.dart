
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_writer_tools/core/graph.dart';
import 'package:nsl_writer_tools/data/database.dart';
import 'package:nsl_writer_tools/data/repository.dart';
import 'package:nsl_writer_tools/data/seed.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  late String worldId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
    worldId = (await repo.createWorld('w')).id;
  });
  tearDown(() => db.close());

  Future<Entry> mk(String title, {String body = '', List<String> aliases = const []}) =>
      repo.createEntry(worldId: worldId, type: EntryType.character, title: title, body: body, aliases: aliases);

  Future<Graph> build({
    Set<String> hidden = const {},
    bool links = false,
    bool isolated = false,
    String? focus,
    int depth = 1,
  }) async =>
      buildGraph(
        entries: await repo.entriesOfWorld(worldId),
        relations: await repo.relationsOfWorld(worldId),
        hiddenTypes: hidden,
        includeLinks: links,
        showIsolated: isolated,
        focusId: focus,
        depth: depth,
      );

  group('buildGraph', () {
    test('hides isolated entries unless asked, and merges relations between one pair', () async {
      final a = await mk('a'), b = await mk('b');
      await mk('lonely');
      await repo.addRelation(from: a.id, to: b.id, type: 'ศัตรู');
      await repo.addRelation(from: a.id, to: b.id, type: 'คู่แข่ง');

      var g = await build();
      expect(g.nodes.map((e) => e.title), ['a', 'b']);
      expect(g.edges, hasLength(1));
      expect(g.edges.single.labels, ['ศัตรู', 'คู่แข่ง']);

      g = await build(isolated: true);
      expect(g.nodes.map((e) => e.title), ['a', 'b', 'lonely']);
    });

    test('direction is kept only when every relation agrees', () async {
      final a = await mk('a'), b = await mk('b'), c = await mk('c');
      final lo = a.id.compareTo(b.id) < 0 ? a : b; // edge.a is the smaller id
      final hi = lo == a ? b : a;
      await repo.addRelation(from: lo.id, to: hi.id, type: 'x');
      await repo.addRelation(from: b.id, to: c.id, type: 'y');
      var g = await build();
      final ab = g.edges.firstWhere((e) => {e.a, e.b}.containsAll([a.id, b.id]));
      expect(ab.aToB, isTrue);

      await repo.addRelation(from: hi.id, to: lo.id, type: 'z');
      g = await build();
      expect(g.edges.firstWhere((e) => {e.a, e.b}.containsAll([a.id, b.id])).aToB, isNull);
    });

    test('hidden relation types disappear, taking their orphaned nodes with them', () async {
      final a = await mk('a'), b = await mk('b'), c = await mk('c');
      await repo.addRelation(from: a.id, to: b.id, type: 'ศัตรู');
      await repo.addRelation(from: b.id, to: c.id, type: 'สังกัด');
      final g = await build(hidden: {'สังกัด'});
      expect(g.nodes.map((e) => e.title), ['a', 'b']);
      expect(g.edges, hasLength(1));
    });

    test('[[links]] become edges (by title and alias) only when enabled', () async {
      await mk('a', body: 'เจอ [[b]] และ [[ชื่อเล่นซี]] และ [[ไม่มี]] และ [[a]]');
      await mk('b');
      await mk('c', aliases: ['ชื่อเล่นซี']);
      expect((await build()).edges, isEmpty);

      final g = await build(links: true);
      expect(g.edges, hasLength(2)); // a–b, a–c; broken and self links ignored
      expect(g.edges.every((e) => e.isLink && e.labels.isEmpty), isTrue);
      expect(g.nodes.map((e) => e.title), ['a', 'b', 'c']);
    });

    test('a relation wins over a link between the same pair', () async {
      final a = await mk('a', body: '[[b]]'), b = await mk('b');
      await repo.addRelation(from: a.id, to: b.id, type: 'ศัตรู');
      final g = await build(links: true);
      expect(g.edges, hasLength(1));
      expect(g.edges.single.isLink, isFalse);
    });

    test('focus keeps only the neighbourhood within the given depth', () async {
      final a = await mk('a'), b = await mk('b'), c = await mk('c'), d = await mk('d');
      await repo.addRelation(from: a.id, to: b.id, type: 't');
      await repo.addRelation(from: b.id, to: c.id, type: 't');
      await repo.addRelation(from: c.id, to: d.id, type: 't');
      expect((await build(focus: a.id, depth: 1)).nodes.map((e) => e.title), ['a', 'b']);
      expect((await build(focus: a.id, depth: 2)).nodes.map((e) => e.title), ['a', 'b', 'c']);
      expect((await build(focus: b.id, depth: 1)).edges, hasLength(2));
      // A focused entry with no edges still shows (alone).
      final lone = await mk('lone');
      expect((await build(focus: lone.id)).nodes.map((e) => e.title), ['lone']);
    });

    test('relationTypeCounts orders by use', () async {
      final a = await mk('a'), b = await mk('b'), c = await mk('c');
      await repo.addRelation(from: a.id, to: b.id, type: 'ศัตรู');
      await repo.addRelation(from: a.id, to: c.id, type: 'สังกัด');
      await repo.addRelation(from: b.id, to: c.id, type: 'สังกัด');
      final counts = relationTypeCounts(await repo.relationsOfWorld(worldId));
      expect(counts.map((e) => '${e.key}:${e.value}'), ['สังกัด:2', 'ศัตรู:1']);
    });
  });

  group('layoutGraph', () {
    Future<Graph> chainPlusLoners() async {
      final a = await mk('a'), b = await mk('b'), c = await mk('c');
      await mk('x');
      await mk('y');
      await repo.addRelation(from: a.id, to: b.id, type: 't');
      await repo.addRelation(from: b.id, to: c.id, type: 't');
      return build(isolated: true);
    }

    test('is deterministic and finite', () async {
      final g = await chainPlusLoners();
      final one = layoutGraph(g), two = layoutGraph(g);
      expect(one.keys.toSet(), {for (final n in g.nodes) n.id});
      for (final id in one.keys) {
        expect(one[id], two[id]);
        expect(one[id]!.dx.isFinite && one[id]!.dy.isFinite, isTrue);
      }
    });

    test('connected entries end up closer than unconnected ones', () async {
      final g = await chainPlusLoners();
      final pos = layoutGraph(g);
      double dist(String x, String y) {
        final a = g.nodes.firstWhere((n) => n.title == x).id, b = g.nodes.firstWhere((n) => n.title == y).id;
        return (pos[a]! - pos[b]!).distance;
      }

      expect(dist('a', 'b'), lessThan(dist('a', 'x')));
      expect(dist('b', 'c'), lessThan(dist('b', 'y')));
    });

    test('nodes never sit on top of each other', () async {
      for (var i = 0; i < 30; i++) {
        await mk('n$i');
      }
      final g = await build(isolated: true);
      final pos = layoutGraph(g).values.toList();
      var closest = double.infinity;
      for (var i = 0; i < pos.length; i++) {
        for (var j = i + 1; j < pos.length; j++) {
          closest = closest < (pos[i] - pos[j]).distance ? closest : (pos[i] - pos[j]).distance;
        }
      }
      expect(closest, greaterThan(40));
    });

    test('pinned nodes and kept start positions do not move', () async {
      final g = await chainPlusLoners();
      final id = g.nodes.first.id;
      final start = {id: const Offset(500, -300)};
      final pos = layoutGraph(g, start: start, pinned: {id});
      expect(pos[id], const Offset(500, -300));
      // With no iterations nothing is moved at all.
      expect(layoutGraph(g, start: start, iterations: 0)[id], const Offset(500, -300));
    });

    test('empty and single-node graphs are fine', () async {
      expect(layoutGraph(const Graph(nodes: [], edges: [])), isEmpty);
      final only = await mk('only');
      final pos = layoutGraph(Graph(nodes: [only], edges: const []));
      expect(pos.keys, [only.id]);
      expect(pos[only.id]!.dx.isFinite, isTrue);
    });

    test('300 nodes lay out in reasonable time', () async {
      for (var i = 0; i < 300; i++) {
        await mk('n$i');
      }
      final entries = await repo.entriesOfWorld(worldId);
      final rels = <Relation>[];
      for (var i = 1; i < entries.length; i++) {
        await repo.addRelation(from: entries[i].id, to: entries[(i * 7) % i].id, type: 't');
      }
      rels.addAll(await repo.relationsOfWorld(worldId));
      final g = buildGraph(entries: entries, relations: rels);
      final sw = Stopwatch()..start();
      final pos = layoutGraph(g);
      sw.stop();
      expect(pos, hasLength(g.nodes.length));
      expect(sw.elapsedMilliseconds, lessThan(5000), reason: 'took ${sw.elapsedMilliseconds}ms');
    });

    test('the sample world lays out and shows its relations', () async {
      await seedSampleWorld(repo, worldId);
      final g = await build();
      expect(g.edges, isNotEmpty);
      expect(layoutGraph(g), hasLength(g.nodes.length));
    });
  });
}
