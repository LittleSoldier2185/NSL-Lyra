import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_writer_tools/core/calendar.dart';
import 'package:nsl_writer_tools/data/backup.dart';
import 'package:nsl_writer_tools/data/database.dart';
import 'package:nsl_writer_tools/data/repository.dart';
import 'package:nsl_writer_tools/data/seed.dart';

void main() {
  group('calendar', () {
    const cfg = CalendarConfig(yearLabel: 'ปีที่', months: ['ลม', 'ฝน', 'หมอก']);

    test('formats full, month-only and year-only dates', () {
      expect(cfg.format(const WorldDate(401, 3, 12)), '12 หมอก ปีที่ 401');
      expect(cfg.format(const WorldDate(401, 3)), 'หมอก ปีที่ 401');
      expect(cfg.format(const WorldDate(401)), 'ปีที่ 401');
      expect(cfg.format(const WorldDate(5, 9, 1)), '1 เดือน 9 ปีที่ 5'); // beyond the named months
    });

    test('formats spans, collapsing identical ends', () {
      expect(cfg.formatSpan(const WorldDate(401, 3, 12), const WorldDate(401, 3, 13)), '12 หมอก ปีที่ 401 – 13 หมอก ปีที่ 401');
      expect(cfg.formatSpan(const WorldDate(401), const WorldDate(401)), 'ปีที่ 401');
      expect(cfg.formatSpan(const WorldDate(401), null), 'ปีที่ 401');
    });

    test('orders by year, then month, then day; unknown month/day first', () {
      final dates = [const WorldDate(401, 3, 12), const WorldDate(401), const WorldDate(-5), const WorldDate(401, 3), const WorldDate(401, 1, 30)]
        ..sort();
      expect(dates.map((d) => cfg.format(d)).toList(),
          ['ปีที่ -5', 'ปีที่ 401', '30 ลม ปีที่ 401', 'หมอก ปีที่ 401', '12 หมอก ปีที่ 401']);
    });

    test('config survives encode/parse, and bad JSON falls back to defaults', () {
      final back = CalendarConfig.parse(cfg.encode());
      expect(back.months, cfg.months);
      expect(back.yearLabel, 'ปีที่');
      expect(CalendarConfig.parse('not json').months, isEmpty);
      expect(CalendarConfig.parse('{}').yearLabel, 'ปีที่');
    });
  });

  group('timeline data', () {
    late AppDatabase db;
    late Repository repo;
    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = Repository(db);
    });
    tearDown(() => db.close());

    test('items come back oldest first with participants; clearing removes them', () async {
      final w = await repo.createWorld('w');
      Future<Entry> mk(String t) => repo.createEntry(worldId: w.id, type: EntryType.event, title: t);
      final late = await mk('late'), early = await mk('early'), who = await mk('who');
      await repo.setTimeline(late.id, start: const WorldDate(10, 2), participants: [who.id, who.id, late.id]);
      await repo.setTimeline(early.id, start: const WorldDate(3), end: const WorldDate(4, 1, 1));

      final items = await repo.timelineOfWorld(w.id);
      expect(items.map((i) => i.entry.title), ['early', 'late']);
      expect(items[1].participantIds, [who.id]); // deduped, and never itself
      expect(items[0].end?.year, 4);

      await repo.setTimeline(late.id); // start == null clears it
      expect((await repo.timelineOfWorld(w.id)).map((i) => i.entry.title), ['early']);
    });

    test('deleting a participant or an event entry cleans up', () async {
      final w = await repo.createWorld('w');
      final ev = await repo.createEntry(worldId: w.id, type: EntryType.event, title: 'ev');
      final p = await repo.createEntry(worldId: w.id, type: EntryType.character, title: 'p');
      await repo.setTimeline(ev.id, start: const WorldDate(1), participants: [p.id]);

      await repo.deleteEntry(p.id);
      expect((await repo.timelineOfWorld(w.id)).single.participantIds, isEmpty);

      await repo.deleteEntry(ev.id);
      expect(await repo.timelineOfWorld(w.id), isEmpty);
      expect(await db.select(db.timelineEvents).get(), isEmpty);
    });

    test('watchTimeline re-emits when the timeline changes', () async {
      final w = await repo.createWorld('w');
      final e = await repo.createEntry(worldId: w.id, type: EntryType.event, title: 'e');
      final seen = <int>[];
      final sub = repo.watchTimeline(w.id).listen((l) => seen.add(l.length));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.setTimeline(e.id, start: const WorldDate(1));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(seen.first, 0);
      expect(seen.last, 1);
    });
  });

  test('upgrading a version-1 database keeps data and adds the timeline tables', () async {
    // Hand-written version-1 schema (what the first releases created).
    final old = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE worlds (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL,
          calendar_config TEXT NOT NULL DEFAULT '{}', created INTEGER NOT NULL);
        CREATE TABLE entries (id TEXT NOT NULL PRIMARY KEY, world_id TEXT NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
          type TEXT NOT NULL, title TEXT NOT NULL, aliases TEXT NOT NULL DEFAULT '[]', summary TEXT NOT NULL DEFAULT '',
          body TEXT NOT NULL DEFAULT '', status TEXT NOT NULL DEFAULT 'draft', tags TEXT NOT NULL DEFAULT '[]',
          fields TEXT NOT NULL DEFAULT '{}', image_path TEXT NULL, created INTEGER NOT NULL, updated INTEGER NOT NULL);
        CREATE TABLE relations (id TEXT NOT NULL PRIMARY KEY, from_entry TEXT NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
          to_entry TEXT NOT NULL REFERENCES entries(id) ON DELETE CASCADE, type TEXT NOT NULL,
          inverse_type TEXT NOT NULL DEFAULT '', note TEXT NOT NULL DEFAULT '');
        INSERT INTO worlds VALUES ('w1', 'โลกเดิม', '{}', 1700000000);
        INSERT INTO entries (id, world_id, type, title, created, updated)
          VALUES ('e1', 'w1', 'character', 'ไลรา', 1700000000, 1700000000);
        PRAGMA user_version = 1;
      ''');
    }));
    addTearDown(old.close);
    final repo = Repository(old);

    // Old data is intact…
    expect((await repo.worlds()).single.name, 'โลกเดิม');
    final entry = (await repo.entriesOfWorld('w1')).single;
    expect(entry.title, 'ไลรา');
    // …and the new tables work.
    await repo.setTimeline(entry.id, start: const WorldDate(7, 1, 2));
    expect((await repo.timelineOfWorld('w1')).single.start.year, 7);
  });

  group('backup with timeline', () {
    late AppDatabase db;
    late Repository repo;
    late BackupService backup;
    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = Repository(db);
      backup = BackupService(repo);
    });
    tearDown(() => db.close());

    test('round trip keeps calendar, dates, spans and participants', () async {
      final src = await repo.createWorld('w');
      await seedSampleWorld(repo, src.id);
      final r = await backup.importWorld(backup.encode(await backup.exportWorld(src)));

      final a = await repo.timelineOfWorld(src.id);
      final b = await repo.timelineOfWorld(r.world.id);
      expect(a, isNotEmpty);
      expect(b.length, a.length);
      for (var i = 0; i < a.length; i++) {
        expect(b[i].entry.title, a[i].entry.title);
        expect(b[i].start.compareTo(a[i].start), 0);
        expect(b[i].end?.compareTo(a[i].end!), a[i].end == null ? null : 0);
        // Participant ids are remapped, so compare by title.
        Future<List<String>> titles(String worldId, TimelineItem t) async {
          final all = {for (final e in await repo.entriesOfWorld(worldId)) e.id: e.title};
          return t.participantIds.map((id) => all[id]!).toList()..sort();
        }

        expect(await titles(r.world.id, b[i]), await titles(src.id, a[i]));
      }
      expect(CalendarConfig.parse(r.world.calendarConfig).months.length, 12);
    });

    test('a version-1 file (no timeline key) still imports', () async {
      final src = await repo.createWorld('w');
      await repo.createEntry(worldId: src.id, type: EntryType.place, title: 'x');
      final map = await backup.exportWorld(src)
        ..['version'] = 1
        ..remove('timeline');
      final r = await backup.importWorld(jsonEncode(map));
      expect(r.entries, 1);
      expect(await repo.timelineOfWorld(r.world.id), isEmpty);
    });
  });
}
