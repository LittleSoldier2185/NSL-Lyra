import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_writer_tools/core/stats.dart';
import 'package:nsl_writer_tools/data/database.dart';
import 'package:nsl_writer_tools/data/repository.dart';

void main() {
  late AppDatabase db;
  late Repository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
  });
  tearDown(() => db.close());

  test('counts, orphans and broken links', () async {
    final w = await repo.createWorld('w');
    await repo.createEntry(worldId: w.id, type: EntryType.character, title: 'ไลรา', aliases: ['กัปตัน'], status: EntryStatus.canon,
        body: 'อยู่ที่ [[ท่าเรือ]] เห็น [[ไลรา]] และ [[ผี]] กับ [[ผี]]');
    await repo.createEntry(worldId: w.id, type: EntryType.place, title: 'ท่าเรือ');
    await repo.createEntry(worldId: w.id, type: EntryType.character, title: 'เซเรน', body: 'ศัตรูของ [[กัปตัน]]');

    final s = computeStats(await repo.entriesOfWorld(w.id));
    expect(s.total, 3);
    expect(s.byType[EntryType.character], 2);
    expect(s.byType[EntryType.rule], 0);
    expect(s.byStatus[EntryStatus.canon], 1);
    // ไลรา is linked via its alias; ท่าเรือ via title; เซเรน by nobody. A self-link doesn't count.
    expect(s.orphans.map((e) => e.title), ['เซเรน']);
    // Counted per entry, not per occurrence.
    expect(s.brokenLinks, {'ผี': 1});
  });

  test('deleting a world removes its entries and relations only', () async {
    final a = await repo.createWorld('a');
    final b = await repo.createWorld('b');
    final x = await repo.createEntry(worldId: a.id, type: EntryType.place, title: 'x');
    final y = await repo.createEntry(worldId: a.id, type: EntryType.place, title: 'y');
    await repo.addRelation(from: x.id, to: y.id, type: 't');
    await repo.createEntry(worldId: b.id, type: EntryType.place, title: 'keep');

    await repo.deleteWorld(a.id);

    expect(await repo.entriesOfWorld(a.id), isEmpty);
    expect((await repo.entriesOfWorld(b.id)).length, 1);
    expect(await db.select(db.relations).get(), isEmpty);
    expect((await repo.worlds()).map((w) => w.name), ['b']);
  });
}
