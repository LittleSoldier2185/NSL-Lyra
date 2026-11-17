import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_writer_tools/core/calendar.dart';
import 'package:nsl_writer_tools/data/database.dart';
import 'package:nsl_writer_tools/data/image_store.dart';
import 'package:nsl_writer_tools/data/repository.dart';
import 'package:nsl_writer_tools/data/seed.dart';
import 'package:nsl_writer_tools/data/sync.dart';

/// One simulated device: its own database and a clock the test controls.
class Device {
  Device(this.name, DateTime start, {Directory? images}) : _now = start {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db, clock: () => _now, images: images == null ? null : ImageStore(dir: images));
    sync = SyncService(repo);
  }
  final String name;
  late final AppDatabase db;
  late final Repository repo;
  late final SyncService sync;
  DateTime _now;

  void at(DateTime t) => _now = t;
  DateTime nowForTest() => _now;
  void tick([int seconds = 2]) => _now = _now.add(Duration(seconds: seconds));

  Future<String> worldId() async => (await repo.worlds()).first.id;

  /// Everything a user could see, without stamps: used to check two devices agree.
  Future<String> fingerprint() async {
    final out = <String, Object?>{};
    for (final w in await repo.worlds()) {
      final entries = await repo.entriesOfWorld(w.id);
      final rels = await repo.relationsOfWorld(w.id);
      final tl = await repo.timelineOfWorld(w.id);
      out[w.id] = {
        'name': w.name,
        'calendar': w.calendarConfig,
        'entries': {
          for (final e in entries)
            e.id: [e.type.name, e.title, decodeList(e.aliases), e.summary, e.body, e.status.name, decodeList(e.tags), decodeMap(e.fields)]
        },
        'relations': {for (final r in rels) r.id: [r.fromEntry, r.toEntry, r.type, r.inverseType, r.note]},
        'timeline': {
          for (final t in tl)
            t.entry.id: [t.start.year, t.start.month, t.start.day, t.end?.year, t.end?.month, t.end?.day, (t.participantIds.toList()..sort())]
        },
      };
    }
    return jsonEncode(_sorted(out));
  }

  /// Maps with their keys in order, so two equal worlds always give the same string.
  static Object? _sorted(Object? v) => v is Map
      ? {for (final k in (v.keys.toList()..sort())) k: _sorted(v[k])}
      : v is List
          ? v.map(_sorted).toList()
          : v;

  Future<List<Entry>> entries() async => repo.entriesOfWorld(await worldId());
  Future<Entry> entry(String title) async => (await entries()).firstWhere((e) => e.title == title);

  Future<void> close() => db.close();
}

/// `from` sends its data to `to`, `to` merges it and answers with all of its data, `from` merges
/// that: what a Wi-Fi sync does.
Future<(List<SyncReport>, List<SyncReport>)> syncBoth(Device from, Device to) async {
  final (toReports, reply) = await to.sync.exchange(await from.sync.exportBundle());
  final fromReports = await from.sync.mergeBundle(reply);
  // Real time passes between syncs; without it everything looks "edited since the last sync".
  from.tick();
  to.tick();
  return (fromReports, toReports);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final t0 = DateTime.utc(2026, 3, 1, 9);
  late Device a, b;

  setUp(() {
    a = Device('A', t0);
    b = Device('B', t0);
  });
  tearDown(() async {
    await a.close();
    await b.close();
  });

  test('first sync creates the world on an empty device with everything intact; the next is a no-op', () async {
    final w = await a.repo.createWorld('หมู่เกาะเงาจันทร์');
    await seedSampleWorld(a.repo, w.id);

    final (_, serverReports) = await syncBoth(a, b);
    expect(serverReports.single.createdWorld, isTrue);
    expect(await b.fingerprint(), await a.fingerprint());
    expect((await b.repo.worlds()).single.id, w.id); // same identity on both devices
    expect(CalendarConfig.parse((await b.repo.worlds()).single.calendarConfig).months, hasLength(12));
    expect((await b.repo.timelineOfWorld(w.id)), isNotEmpty);

    a.tick(5);
    b.tick(5);
    final (r1, r2) = await syncBoth(a, b);
    expect([...r1, ...r2].every((r) => !r.changed), isTrue, reason: 'nothing changed, nothing to do');
  });

  test('an edit fast-forwards to the other device and keeps its "last edited" time', () async {
    final w = await a.repo.createWorld('w');
    final e = await a.repo.createEntry(worldId: w.id, type: EntryType.place, title: 'x', body: 'one');
    await syncBoth(a, b);

    a.tick(60);
    await a.repo.updateEntry(e.id, body: 'two');
    final edited = (await a.entry('x')).updated;
    b.tick(120);
    final (_, reports) = await syncBoth(a, b);

    expect((await b.entry('x')).body, 'two');
    expect((await b.entry('x')).updated, edited);
    expect(reports.single.entriesUpdated, 1);
    expect(reports.single.conflicts, 0);
    expect(await b.fingerprint(), await a.fingerprint());
  });

  test('edits to different entries on both devices both survive', () async {
    final w = await a.repo.createWorld('w');
    final x = await a.repo.createEntry(worldId: w.id, type: EntryType.place, title: 'x');
    final y = await a.repo.createEntry(worldId: w.id, type: EntryType.place, title: 'y');
    await syncBoth(a, b);

    a.tick();
    b.tick();
    await a.repo.updateEntry(x.id, summary: 'from A');
    await b.repo.updateEntry(y.id, summary: 'from B');
    a.tick();
    b.tick();
    await syncBoth(a, b);

    expect((await a.entry('x')).summary, 'from A');
    expect((await a.entry('y')).summary, 'from B');
    expect(await a.fingerprint(), await b.fingerprint());
    expect((await a.entries()).length, 2, reason: 'no conflict copies when nothing clashed');
  });

  test('the same entry edited on both: newest wins, the other text is kept once as a conflict copy', () async {
    final w = await a.repo.createWorld('w');
    final e = await a.repo.createEntry(worldId: w.id, type: EntryType.character, title: 'ไลรา', body: 'start');
    await syncBoth(a, b);

    a.tick(10);
    b.tick(30);
    await a.repo.updateEntry(e.id, body: 'A wrote this');
    b.tick(5);
    await b.repo.updateEntry(e.id, body: 'B wrote this later');
    a.tick(60);
    b.tick(60);
    final (_, reports) = await syncBoth(a, b);

    for (final d in [a, b]) {
      expect((await d.entry('ไลรา')).body, 'B wrote this later', reason: 'newer edit wins on ${d.name}');
      final copies = (await d.entries()).where((x) => x.title.contains('ขัดแย้ง')).toList();
      expect(copies, hasLength(1), reason: 'exactly one copy on ${d.name}');
      expect(copies.single.body, 'A wrote this');
    }
    expect(reports.single.conflicts, 1);
    expect(await a.fingerprint(), await b.fingerprint());

    // Syncing again, in either direction, never makes more copies.
    for (var i = 0; i < 3; i++) {
      a.tick(10);
      b.tick(10);
      await syncBoth(a, b);
      await syncBoth(b, a);
    }
    expect((await a.entries()).where((x) => x.title.contains('ขัดแย้ง')), hasLength(1));
    expect(await a.fingerprint(), await b.fingerprint());
  });

  test('conflict copies are the same whichever device syncs first', () async {
    // Ids are random per run, so compare what the user sees: (title, body) pairs.
    Future<List<String>> run(bool aFirst) async {
      final x = Device('x', t0), y = Device('y', t0);
      final w = await x.repo.createWorld('w');
      final e = await x.repo.createEntry(worldId: w.id, type: EntryType.item, title: 'item', body: 'base');
      await syncBoth(x, y);
      x.tick(10);
      y.tick(10);
      await x.repo.updateEntry(e.id, body: 'x edit');
      y.tick(3);
      await y.repo.updateEntry(e.id, body: 'y edit');
      x.tick(30);
      y.tick(30);
      await (aFirst ? syncBoth(x, y) : syncBoth(y, x));
      await syncBoth(x, y);
      expect(await x.fingerprint(), await y.fingerprint());
      final seen = (await x.entries()).map((e) => '${e.title}|${e.body}').toList()..sort();
      await x.close();
      await y.close();
      return seen;
    }

    expect(await run(true), await run(false));
  });

  group('deletes', () {
    test('a delete reaches the other device', () async {
      final w = await a.repo.createWorld('w');
      final e = await a.repo.createEntry(worldId: w.id, type: EntryType.place, title: 'gone');
      await a.repo.createEntry(worldId: w.id, type: EntryType.place, title: 'stays');
      await syncBoth(a, b);

      a.tick(30);
      b.tick(30);
      await a.repo.deleteEntry(e.id);
      a.tick(10);
      b.tick(10);
      final (_, reports) = await syncBoth(a, b);

      expect((await b.entries()).map((x) => x.title), ['stays']);
      expect(reports.single.entriesDeleted, 1);
      expect(await a.fingerprint(), await b.fingerprint());
    });

    test('an edit made after the other device deleted brings the entry back', () async {
      final w = await a.repo.createWorld('w');
      final e = await a.repo.createEntry(worldId: w.id, type: EntryType.place, title: 'x', body: 'old');
      await syncBoth(a, b);

      a.tick(30);
      b.tick(30);
      await a.repo.deleteEntry(e.id);
      b.tick(30); // B edits after A deleted
      await b.repo.updateEntry(e.id, body: 'rescued');
      a.tick(60);
      b.tick(60);
      await syncBoth(a, b);

      expect((await a.entry('x')).body, 'rescued');
      expect(await a.fingerprint(), await b.fingerprint());
    });

    test('an edit made before the other device deleted does not bring it back', () async {
      final w = await a.repo.createWorld('w');
      final e = await a.repo.createEntry(worldId: w.id, type: EntryType.place, title: 'x', body: 'old');
      await syncBoth(a, b);

      b.tick(30);
      await b.repo.updateEntry(e.id, body: 'edited early');
      a.tick(90);
      await a.repo.deleteEntry(e.id); // later than B's edit
      a.tick(60);
      b.tick(120);
      await syncBoth(a, b);

      expect(await a.entries(), isEmpty);
      expect(await b.entries(), isEmpty);
    });

    test('a deleted entry stays deleted when a stale device syncs later', () async {
      final w = await a.repo.createWorld('w');
      final e = await a.repo.createEntry(worldId: w.id, type: EntryType.place, title: 'x');
      await syncBoth(a, b);
      a.tick(20);
      await a.repo.deleteEntry(e.id);
      a.tick(20);
      b.tick(500); // B did nothing meanwhile
      await syncBoth(b, a);
      await syncBoth(a, b);
      expect(await a.entries(), isEmpty);
      expect(await b.entries(), isEmpty);
    });
  });

  test('relations and timeline entries travel, and their deletions travel too', () async {
    final w = await a.repo.createWorld('w');
    final p = await a.repo.createEntry(worldId: w.id, type: EntryType.character, title: 'p');
    final q = await a.repo.createEntry(worldId: w.id, type: EntryType.place, title: 'q');
    await a.repo.addRelation(from: p.id, to: q.id, type: 'อยู่ที่', inverseType: 'ที่อยู่ของ', note: 'n');
    await a.repo.setTimeline(q.id, start: const WorldDate(5, 2, 3), end: const WorldDate(6), participants: [p.id]);
    await syncBoth(a, b);

    final bw = await b.worldId();
    expect(await b.repo.relationsOfWorld(bw), hasLength(1));
    final item = (await b.repo.timelineOfWorld(bw)).single;
    expect([item.start.year, item.start.month, item.start.day, item.end?.year], [5, 2, 3, 6]);
    expect(item.participantIds, [p.id]);

    // B removes both; A learns about it.
    b.tick(60);
    a.tick(60);
    await b.repo.deleteRelation((await b.repo.relationsOfWorld(bw)).single.id);
    await b.repo.setTimeline(q.id);
    b.tick(10);
    a.tick(10);
    await syncBoth(b, a);
    expect(await a.repo.relationsOfWorld(w.id), isEmpty);
    expect(await a.repo.timelineOfWorld(w.id), isEmpty);
    expect(await a.fingerprint(), await b.fingerprint());
  });

  test('renaming an entry carries the rewritten [[links]] in OTHER entries to the other device', () async {
    final w = await a.repo.createWorld('w');
    final place = await a.repo.createEntry(worldId: w.id, type: EntryType.place, title: 'ท่าเรือ');
    await a.repo.createEntry(worldId: w.id, type: EntryType.character, title: 'ไลรา', body: 'อยู่ที่ [[ท่าเรือ]]');
    await syncBoth(a, b);

    a.tick(60);
    b.tick(60);
    await a.repo.updateEntry(place.id, title: 'ท่าเรือโคราล');
    a.tick(30);
    b.tick(30);
    await syncBoth(a, b);

    expect((await b.entry('ไลรา')).body, 'อยู่ที่ [[ท่าเรือโคราล]]');
    expect(await a.fingerprint(), await b.fingerprint());
  });

  test('two entries created independently with the same title end up with different titles on both devices', () async {
    final w = await a.repo.createWorld('w');
    await a.repo.createEntry(worldId: w.id, type: EntryType.character, title: 'seed');
    await syncBoth(a, b);

    a.tick(20);
    b.tick(25);
    await a.repo.createEntry(worldId: w.id, type: EntryType.character, title: 'ไลรา', summary: 'from A');
    await b.repo.createEntry(worldId: w.id, type: EntryType.place, title: 'ไลรา', summary: 'from B');
    a.tick(30);
    b.tick(30);
    await syncBoth(a, b);
    await syncBoth(b, a);

    final titles = (await a.entries()).map((e) => e.title).toList()..sort();
    expect(titles.toSet(), hasLength(titles.length), reason: 'no duplicate titles');
    expect(titles, contains('ไลรา'));
    expect(titles.where((t) => t.startsWith('ไลรา')), hasLength(2));
    expect(await a.fingerprint(), await b.fingerprint());
    // Nobody lost their text.
    expect((await a.entries()).map((e) => e.summary), containsAll(['from A', 'from B']));
  });

  test('world name and calendar: the newer change wins', () async {
    final w = await a.repo.createWorld('เดิม');
    await syncBoth(a, b);
    b.tick(30);
    await b.repo.renameWorld(w.id, 'ชื่อใหม่');
    await b.repo.setCalendar(w.id, const CalendarConfig(yearLabel: 'ศ.ก.', months: ['ม1', 'ม2']));
    a.tick(60);
    b.tick(60);
    await syncBoth(a, b);
    for (final d in [a, b]) {
      final world = (await d.repo.worlds()).single;
      expect(world.name, 'ชื่อใหม่');
      expect(CalendarConfig.parse(world.calendarConfig).yearLabel, 'ศ.ก.');
    }
  });

  group('autosave must not look like an edit', () {
    test('saving identical values changes neither "modified" nor "updated"', () async {
      final w = await a.repo.createWorld('w');
      final e = await a.repo.createEntry(worldId: w.id, type: EntryType.place, title: 'x', body: 'b', tags: ['t'], fields: {'k': 'v'});
      await a.repo.setTimeline(e.id, start: const WorldDate(1, 2, 3));
      final before = await a.entry('x');
      final tlBefore = await a.db.select(a.db.timelineEvents).getSingle();

      a.tick(600);
      await a.repo.updateEntry(e.id, title: 'x', body: 'b', tags: ['t'], fields: {'k': 'v'}, summary: '');
      await a.repo.setTimeline(e.id, start: const WorldDate(1, 2, 3));

      final after = await a.entry('x');
      expect(after.modified, before.modified);
      expect(after.updated, before.updated);
      expect((await a.db.select(a.db.timelineEvents).getSingle()).modified, tlBefore.modified);
    });

    test('a real change does move both stamps', () async {
      final w = await a.repo.createWorld('w');
      final e = await a.repo.createEntry(worldId: w.id, type: EntryType.place, title: 'x');
      final before = await a.entry('x');
      a.tick(600);
      await a.repo.updateEntry(e.id, body: 'changed');
      final after = await a.entry('x');
      expect(after.modified.isAfter(before.modified), isTrue);
      expect(after.updated.isAfter(before.updated), isTrue);
    });
  });

  group('bad input', () {
    test('is rejected with a readable message and changes nothing', () async {
      await a.repo.createWorld('w');
      final before = await a.fingerprint();
      for (final bad in [
        'not json',
        '[]',
        '{"format":"other","version":1}',
        '{"format":"nsl-writer-tools-sync-bundle","version":99,"snapshots":[]}',
        '{"format":"nsl-writer-tools-sync-bundle","version":1,"snapshots":[{"world":{"id":1}}]}',
      ]) {
        await expectLater(a.sync.mergeBundle(bad), throwsA(isA<SyncException>()), reason: bad);
      }
      expect(await a.fingerprint(), before);
    });
  });

  test('randomized: many edits, renames, deletes and partial syncs still converge', () async {
    for (final seed in [for (var i = 1; i <= 15; i++) i]) {
      const skew = Duration(seconds: 40); // device clocks never agree exactly
      final x = Device('x$seed', t0), y = Device('y$seed', t0);
      final rnd = Random(seed);
      var clock = t0;
      final w = await x.repo.createWorld('w');
      for (var i = 0; i < 4; i++) {
        await x.repo.createEntry(worldId: w.id, type: EntryType.values[i], title: 'seed$i');
      }
      await syncBoth(x, y);

      var counter = 0;
      Future<void> op(Device d, String who) async {
        final wid = await d.worldId();
        final entries = await d.repo.entriesOfWorld(wid);
        Entry? pick() => entries.isEmpty ? null : entries[rnd.nextInt(entries.length)];
        String text() {
          final link = pick();
          return 'text ${rnd.nextInt(1000)}${link != null && rnd.nextBool() ? ' [[${link.title}]]' : ''}';
        }

        switch (rnd.nextInt(9)) {
          case 0:
            await d.repo.createEntry(worldId: wid, type: EntryType.values[rnd.nextInt(7)], title: '$who-${counter++}', body: text());
          case 1 || 2:
            final e = pick();
            if (e != null) await d.repo.updateEntry(e.id, body: text());
          case 3:
            final e = pick();
            if (e != null) await d.repo.updateEntry(e.id, summary: 's${rnd.nextInt(50)}');
          case 4:
            final e = pick();
            if (e != null) await d.repo.updateEntry(e.id, title: '$who-r${counter++}');
          case 5:
            final e = pick();
            if (e != null && entries.length > 2) await d.repo.deleteEntry(e.id);
          case 6:
            final p = pick(), q = pick();
            if (p != null && q != null && p.id != q.id) await d.repo.addRelation(from: p.id, to: q.id, type: 'rel${rnd.nextInt(3)}');
          case 7:
            final rels = await d.repo.relationsOfWorld(wid);
            if (rels.isNotEmpty) await d.repo.deleteRelation(rels[rnd.nextInt(rels.length)].id);
          case 8:
            final e = pick(), p = pick();
            if (e != null) {
              if (rnd.nextInt(3) == 0) {
                await d.repo.setTimeline(e.id);
              } else {
                await d.repo.setTimeline(e.id, start: WorldDate(rnd.nextInt(5), 1 + rnd.nextInt(3)), participants: [if (p != null) p.id]);
              }
            }
        }
      }

      for (var step = 0; step < 150; step++) {
        clock = clock.add(Duration(seconds: 1 + rnd.nextInt(3)));
        x.at(clock);
        y.at(clock.add(skew));
        await op(rnd.nextBool() ? x : y, rnd.nextBool() ? 'p' : 'q');
        if (step % 9 == 8) {
          clock = clock.add(const Duration(seconds: 2));
          x.at(clock);
          y.at(clock.add(skew));
          switch (rnd.nextInt(3)) {
            case 0:
              await syncBoth(x, y);
            case 1:
              await syncBoth(y, x);
            default:
              await y.sync.mergeBundle(await x.sync.exportBundle()); // one-way, like a file
          }
        }
      }

      for (var i = 0; i < 3; i++) {
        clock = clock.add(const Duration(seconds: 5));
        x.at(clock);
        y.at(clock.add(skew));
        await syncBoth(x, y);
        await syncBoth(y, x);
      }
      expect(await x.fingerprint(), await y.fingerprint(), reason: 'seed $seed did not converge');

      // And converged means settled: another full sync changes nothing.
      clock = clock.add(const Duration(seconds: 5));
      x.at(clock);
      y.at(clock.add(skew));
      final (r1, r2) = await syncBoth(x, y);
      expect([...r1, ...r2].every((r) => !r.changed), isTrue, reason: 'seed $seed kept changing: ${[...r1, ...r2].map((r) => r.summary)}');

      // Titles stay unique, so links keep working.
      final titles = (await x.entries()).map((e) => e.title).toList();
      expect(titles.toSet(), hasLength(titles.length), reason: 'seed $seed duplicate titles');
      await x.close();
      await y.close();
    }
  });
}
