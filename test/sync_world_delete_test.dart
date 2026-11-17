import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_writer_tools/data/database.dart';
import 'package:nsl_writer_tools/data/seed.dart';

import 'sync_test.dart' show Device, syncBoth;

/// Deleting a whole world used to stay local (it came back from the other device).
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final t0 = DateTime(2026, 10, 12, 9);

  /// Two devices that both have two worlds: "หลัก" and "ทดลอง".
  Future<(Device, Device, String)> twoWithTwoWorlds() async {
    final a = Device('A', t0), b = Device('B', t0);
    final main = await a.repo.createWorld('หลัก');
    await seedSampleWorld(a.repo, main.id);
    final extra = await a.repo.createWorld('ทดลอง');
    await a.repo.createEntry(worldId: extra.id, type: EntryType.place, title: 'เมืองทดลอง', summary: 'x');
    a.tick();
    await syncBoth(a, b);
    expect((await b.repo.worlds()).length, 2);
    return (a, b, extra.id);
  }

  Future<bool> hasWorld(Device d, String id) async => (await d.repo.worlds()).any((w) => w.id == id);

  test('a world deleted on one device is deleted on the other', () async {
    final (a, b, extraId) = await twoWithTwoWorlds();
    a.tick(10);
    await a.repo.deleteWorld(extraId);
    a.tick();
    final (_, bReports) = await syncBoth(a, b);

    expect(await hasWorld(a, extraId), isFalse);
    expect(await hasWorld(b, extraId), isFalse);
    expect(bReports.where((r) => r.worldDeleted).map((r) => r.worldId), [extraId]);
    expect(bReports.firstWhere((r) => r.worldDeleted).summary, contains('ถูกลบจากอีกเครื่อง'));
    expect(await a.fingerprint(), await b.fingerprint());
    // The deleted world's entries are gone too, and syncing again changes nothing.
    expect(await b.db.select(b.db.entries).get().then((l) => l.where((e) => e.worldId == extraId)), isEmpty);
    final (again, _) = await syncBoth(a, b);
    expect(again.where((r) => r.changed), isEmpty);
    await a.close();
    await b.close();
  });

  test('deletion works in the other direction as well', () async {
    final (a, b, extraId) = await twoWithTwoWorlds();
    b.tick(10);
    await b.repo.deleteWorld(extraId);
    b.tick();
    await syncBoth(a, b);
    expect(await hasWorld(a, extraId), isFalse);
    expect(await hasWorld(b, extraId), isFalse);
    await a.close();
    await b.close();
  });

  test('an edit made on the other device after the deletion keeps the world, and it returns', () async {
    final (a, b, extraId) = await twoWithTwoWorlds();
    a.tick(10);
    await a.repo.deleteWorld(extraId);
    b.at(a.nowForTest().add(const Duration(seconds: 30)));
    final e = (await b.repo.entriesOfWorld(extraId)).single;
    await b.repo.updateEntry(e.id, summary: 'แก้หลังจากอีกเครื่องลบไปแล้ว');
    b.tick();
    a.at(b.nowForTest());
    await syncBoth(a, b);

    expect(await hasWorld(b, extraId), isTrue);
    expect(await hasWorld(a, extraId), isTrue, reason: 'the edit wins over the older deletion');
    expect((await a.repo.entriesOfWorld(extraId)).single.summary, 'แก้หลังจากอีกเครื่องลบไปแล้ว');
    expect(await a.fingerprint(), await b.fingerprint());
    // No stale deletion marker is left to delete it again later.
    for (final d in [a, b]) {
      expect(await d.db.select(d.db.tombstones).get().then((l) => l.where((t) => t.kind == 'world')), isEmpty);
    }
    final (again, _) = await syncBoth(a, b);
    expect(again.where((r) => r.changed), isEmpty);
    expect(await hasWorld(a, extraId), isTrue);
    await a.close();
    await b.close();
  });

  test('a world edited here after the other device deleted it survives', () async {
    final (a, b, extraId) = await twoWithTwoWorlds();
    a.tick(10);
    await a.repo.deleteWorld(extraId);
    // B edits later, so the edit is newer than the deletion even though B hears of it afterwards.
    b.at(a.nowForTest().add(const Duration(minutes: 5)));
    final e = (await b.repo.entriesOfWorld(extraId)).single;
    await b.repo.updateEntry(e.id, summary: 'ใหม่กว่า');
    // Only A -> B (A's deletion reaches B first).
    await b.sync.mergeBundle(await a.sync.exportBundle());
    expect(await hasWorld(b, extraId), isTrue);
    await a.close();
    await b.close();
  });

  test('the last world on a device is never deleted by a sync', () async {
    final (a, b, extraId) = await twoWithTwoWorlds();
    final mainId = (await a.repo.worlds()).firstWhere((w) => w.id != extraId).id;
    a.tick(10);
    await a.repo.deleteWorld(extraId); // A keeps only the main world
    b.at(a.nowForTest());
    await b.repo.deleteWorld(mainId); // B keeps only the extra one
    a.tick();
    b.tick();
    await syncBoth(a, b);
    await syncBoth(a, b);
    // Each device is left with its one world instead of none (the app always keeps one).
    expect((await a.repo.worlds()).length, 1);
    expect((await b.repo.worlds()).length, 1);
    await a.close();
    await b.close();
  });

  test('a deletion travels through a third device that never had the world', () async {
    final (a, b, extraId) = await twoWithTwoWorlds();
    final c = Device('C', t0.add(const Duration(minutes: 1)));
    await syncBoth(b, c);
    expect(await hasWorld(c, extraId), isTrue);
    a.tick(10);
    await a.repo.deleteWorld(extraId);
    a.tick();
    await syncBoth(a, b);
    b.tick();
    c.at(b.nowForTest());
    await syncBoth(b, c);
    expect(await hasWorld(c, extraId), isFalse);
    await a.close();
    await b.close();
    await c.close();
  });

  test('the repository leaves a world tombstone and drops the world\'s own tombstones', () async {
    final a = Device('A', t0);
    final w = await a.repo.createWorld('หลัก');
    final extra = await a.repo.createWorld('ทดลอง');
    final e = await a.repo.createEntry(worldId: extra.id, type: EntryType.place, title: 'x');
    a.tick();
    await a.repo.deleteEntry(e.id);
    a.tick();
    await a.repo.deleteWorld(extra.id);
    final tombs = await a.db.select(a.db.tombstones).get();
    expect(tombs.map((t) => '${t.kind}:${t.recordId}'), ['world:${extra.id}']);
    expect((await a.repo.worlds()).single.id, w.id);
    await a.close();
  });
}
