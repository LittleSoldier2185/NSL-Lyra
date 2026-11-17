import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_writer_tools/data/backup.dart';
import 'package:nsl_writer_tools/data/database.dart';
import 'package:nsl_writer_tools/data/repository.dart';
import 'package:nsl_writer_tools/data/seed.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  late BackupService backup;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
    backup = BackupService(repo);
  });
  tearDown(() => db.close());

  test('JSON round trip keeps entries, relations, links and timestamps', () async {
    final src = await repo.createWorld('หมู่เกาะเงาจันทร์');
    await seedSampleWorld(repo, src.id);

    final json = backup.encode(await backup.exportWorld(src));
    final result = await backup.importWorld(json);

    expect(result.world.id, isNot(src.id));
    expect(result.world.name, 'หมู่เกาะเงาจันทร์ (นำเข้า)');
    expect(result.skipped, 0);

    final a = await repo.entriesOfWorld(src.id);
    final b = await repo.entriesOfWorld(result.world.id);
    expect(b.length, a.length);
    expect(result.relations, (await repo.relationsOfWorld(src.id)).length);

    for (final e in a) {
      final copy = b.singleWhere((x) => x.title == e.title);
      expect(copy.id, isNot(e.id));
      expect(copy.type, e.type);
      expect(copy.status, e.status);
      expect(copy.body, e.body);
      expect(copy.summary, e.summary);
      expect(decodeList(copy.aliases), decodeList(e.aliases));
      expect(decodeList(copy.tags), decodeList(e.tags));
      expect(decodeMap(copy.fields), decodeMap(e.fields));
      // Stored at second precision or better; must not drift.
      expect(copy.created.millisecondsSinceEpoch, e.created.millisecondsSinceEpoch);
      expect(copy.updated.millisecondsSinceEpoch, e.updated.millisecondsSinceEpoch);
    }

    // Backlinks still work in the imported copy.
    final lyra = b.singleWhere((e) => e.title == 'ไลรา วาเลน');
    expect(repo.backlinksFor(b, lyra).map((x) => x.entry.title), contains('ออร์ริน วาเลน'));
    // The original world is untouched.
    expect((await repo.entriesOfWorld(src.id)).length, a.length);
  });

  test('importing twice makes distinct worlds with distinct names', () async {
    final src = await repo.createWorld('w');
    await repo.createEntry(worldId: src.id, type: EntryType.place, title: 'x');
    final json = backup.encode(await backup.exportWorld(src));
    final one = await backup.importWorld(json);
    final two = await backup.importWorld(json);
    expect({src.name, one.world.name, two.world.name}, hasLength(3));
  });

  test('relations with a missing endpoint are skipped, not fatal', () async {
    final src = await repo.createWorld('w');
    final a = await repo.createEntry(worldId: src.id, type: EntryType.place, title: 'a');
    final b = await repo.createEntry(worldId: src.id, type: EntryType.place, title: 'b');
    await repo.addRelation(from: a.id, to: b.id, type: 't');
    final map = await backup.exportWorld(src);
    (map['entries'] as List).removeWhere((e) => e['title'] == 'b');
    final r = await backup.importWorld(jsonEncode(map));
    expect(r.entries, 1);
    expect(r.relations, 0);
    expect(r.skipped, 1);
  });

  test('bad files give a readable error and import nothing', () async {
    final before = (await repo.worlds()).length;
    for (final bad in ['not json', '{"format":"other"}', '{"format":"nsl-writer-tools","version":99}', '{"format":"nsl-writer-tools","version":1,"world":{"name":"x"},"entries":[{"id":1}]}']) {
      await expectLater(backup.importWorld(bad), throwsA(isA<BackupException>()), reason: bad);
    }
    expect((await repo.worlds()).length, before);
  });

  test('markdown contains front matter, links and relations', () async {
    final w = await repo.createWorld('w');
    final a = await repo.createEntry(worldId: w.id, type: EntryType.character, title: 'ไลรา', summary: 'กัปตัน', body: 'อยู่ที่ [[ท่าเรือ]]', tags: ['ตัวเอก'], fields: {'อายุ': '27'});
    final p = await repo.createEntry(worldId: w.id, type: EntryType.place, title: 'ท่าเรือ');
    await repo.addRelation(from: a.id, to: p.id, type: 'อาศัยอยู่ที่', inverseType: 'ผู้อยู่อาศัย', note: 'ริมอู่');

    final md = await backup.entryMarkdown(a);
    expect(md, startsWith('---\ntype: "character"'));
    expect(md, contains('# ไลรา'));
    expect(md, contains('> กัปตัน'));
    expect(md, contains('- **อายุ:** 27'));
    expect(md, contains('อยู่ที่ [[ท่าเรือ]]'));
    expect(md, contains('- อาศัยอยู่ที่ [[ท่าเรือ]] — ริมอู่'));

    final world = await backup.worldMarkdown(w);
    expect(world, contains('# w'));
    expect(world, contains('## ตัวละคร'));
    expect(world, contains('- ผู้อยู่อาศัย [[ไลรา]] — ริมอู่'));
  });

  test('safeFileName strips characters Windows rejects', () {
    expect(safeFileName('a/b:c*?'), 'a_b_c__');
    expect(safeFileName('  '), 'export');
  });
}
