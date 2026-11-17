import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('create, backlinks via title and alias, cascade delete', () async {
    final w = await repo.createWorld('หมู่เกาะเงาจันทร์');
    final lyra = await repo.createEntry(
        worldId: w.id, type: EntryType.character, title: 'ไลรา วาเลน', aliases: ['นกกระเรียนเงิน']);
    final seren = await repo.createEntry(
        worldId: w.id,
        type: EntryType.character,
        title: 'เซเรน ดาห์',
        body: 'ศัตรูของ [[นกกระเรียนเงิน]] มาตลอด');
    await repo.addRelation(from: lyra.id, to: seren.id, type: 'ศัตรู', inverseType: 'ศัตรู');

    final all = await repo.watchEntries(w.id).first;
    final bl = repo.backlinksFor(all, lyra);
    expect(bl.single.entry.id, seren.id);
    expect(repo.resolveLink(all, 'นกกระเรียนเงิน')?.id, lyra.id);
    expect(repo.resolveLink(all, 'ไม่มี'), isNull);

    await repo.deleteEntry(lyra.id);
    expect(await repo.watchRelationsOf(seren.id).first, isEmpty);
  });

  test('renaming an entry rewrites links elsewhere, not the other entry\'s timestamp', () async {
    final w = await repo.createWorld('w');
    final a = await repo.createEntry(worldId: w.id, type: EntryType.place, title: 'ท่าเรือ');
    final b = await repo.createEntry(worldId: w.id, type: EntryType.character, title: 'ไลรา', body: 'อยู่ที่ [[ท่าเรือ]] และ [[อื่น]]');
    final before = (await repo.watchEntries(w.id).first).firstWhere((e) => e.id == b.id).updated;

    await repo.updateEntry(a.id, title: 'ท่าเรือโคราล');

    final after = (await repo.watchEntries(w.id).first).firstWhere((e) => e.id == b.id);
    expect(after.body, 'อยู่ที่ [[ท่าเรือโคราล]] และ [[อื่น]]');
    expect(after.updated, before);
  });

  test('rename also fixes self-links in the body being saved', () async {
    final w = await repo.createWorld('w');
    final a = await repo.createEntry(worldId: w.id, type: EntryType.place, title: 'เก่า');
    await repo.updateEntry(a.id, title: 'ใหม่', body: 'ดู [[เก่า]]');
    final got = (await repo.watchEntries(w.id).first).single;
    expect(got.body, 'ดู [[ใหม่]]');
  });

  test('titleTaken and uniqueTitle consider titles and aliases', () async {
    final w = await repo.createWorld('w');
    final e = await repo.createEntry(worldId: w.id, type: EntryType.item, title: 'รายการใหม่', aliases: ['ชื่อเล่น']);
    expect(await repo.titleTaken(w.id, 'รายการใหม่'), isTrue);
    expect(await repo.titleTaken(w.id, 'ชื่อเล่น'), isTrue);
    expect(await repo.titleTaken(w.id, 'รายการใหม่', exceptId: e.id), isFalse);
    expect(await repo.uniqueTitle(w.id, 'รายการใหม่'), 'รายการใหม่ 2');
    expect(await repo.uniqueTitle(w.id, 'ว่าง'), 'ว่าง');
  });

  test('search matches body and tags', () async {
    final w = await repo.createWorld('w');
    await repo.createEntry(
        worldId: w.id, type: EntryType.place, title: 'ท่าเรือ', body: 'เมืองปะการัง', tags: ['เมืองท่า']);
    final all = await repo.watchEntries(w.id).first;
    expect(repo.search(all, 'ปะการัง'), hasLength(1));
    expect(repo.search(all, 'เมืองท่า'), hasLength(1));
    expect(repo.search(all, 'xyz'), isEmpty);
  });
}
