import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_writer_tools/data/auto_backup.dart';
import 'package:nsl_writer_tools/data/backup.dart';
import 'package:nsl_writer_tools/data/database.dart';
import 'package:nsl_writer_tools/data/repository.dart';
import 'package:nsl_writer_tools/data/seed.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late Repository repo;
  late Directory dir;
  var now = DateTime(2026, 10, 12, 9);

  AutoBackup backup({int keep = 10}) => AutoBackup(repo, dir: () async => dir, keep: keep, clock: () => now);
  void later([int seconds = 60]) => now = now.add(Duration(seconds: seconds));

  setUp(() async {
    now = DateTime(2026, 10, 12, 9);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db, clock: () => now);
    dir = await Directory.systemTemp.createTemp('auto_backup');
  });
  tearDown(() async {
    await db.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Future<List<File>> filesIn() async => [await for (final f in dir.list()) if (f is File) f];

  test('first run writes one importable file per world', () async {
    final w1 = await repo.createWorld('หมู่เกาะเงาจันทร์');
    await seedSampleWorld(repo, w1.id);
    await repo.createWorld('โลกที่สอง');

    final written = await backup().run();
    expect(written.length, 2);
    expect((await filesIn()).length, 2);
    expect(written.map((f) => f.path.split(Platform.pathSeparator).last).every((n) => n.endsWith('.json') && n.contains('20261012-090000')), isTrue);

    // A backup restores through the normal import (always as a new world).
    final text = await written.firstWhere((f) => f.path.contains('หมู่เกาะเงาจันทร์')).readAsString();
    final r = await BackupService(repo).importWorld(text);
    expect(r.entries, greaterThan(0));
    expect((await repo.worlds()).length, 3);
  });

  test('nothing is written again until something changes', () async {
    final w = await repo.createWorld('โลก');
    final e = await repo.createEntry(worldId: w.id, type: EntryType.character, title: 'อาริน');
    expect((await backup().run()).length, 1);

    later();
    expect(await backup().run(), isEmpty, reason: 'identical to the newest backup');
    expect((await filesIn()).length, 1);

    later();
    await repo.updateEntry(e.id, summary: 'แก้ไขแล้ว');
    final again = await backup().run();
    expect(again.length, 1);
    expect((await filesIn()).length, 2);
    expect(jsonDecode(await again.single.readAsString())['entries'].single['summary'], 'แก้ไขแล้ว');
  });

  test('only the newest few are kept per world, whatever the world is called now', () async {
    final w = await repo.createWorld('ชื่อแรก');
    final other = await repo.createWorld('อีกโลก');
    for (var i = 0; i < 6; i++) {
      later();
      if (i == 3) await repo.renameWorld(w.id, 'ชื่อใหม่');
      await repo.createEntry(worldId: w.id, type: EntryType.place, title: 'ที่ $i');
      await backup(keep: 3).run();
    }
    final mine = await backup().filesOf(w.id);
    expect(mine.length, 3);
    // Newest first, and the survivors are the last three runs (even across the rename).
    final names = mine.map((f) => f.path.split(Platform.pathSeparator).last).toList();
    expect(names.first, contains('ชื่อใหม่'));
    expect(names.map((n) => n.substring(n.length - 20)).toList(), (List.of(names.map((n) => n.substring(n.length - 20)))..sort((a, b) => b.compareTo(a))));
    // The other world was written once (never changed) and is untouched by the pruning.
    expect((await backup().filesOf(other.id)).length, 1);
  });

  test('a deleted world keeps its backups', () async {
    final w = await repo.createWorld('จะลบ');
    await repo.createWorld('คงอยู่');
    await backup().run();
    await repo.deleteWorld(w.id);
    later();
    await backup().run();
    expect((await backup().filesOf(w.id)).length, 1);
  });

  test('an unreadable newest backup does not stop a fresh one', () async {
    await repo.createWorld('โลก');
    final first = (await backup().run()).single;
    await first.writeAsString('not json');
    later();
    final again = await backup().run();
    expect(again.length, 1);
    expect(jsonDecode(await again.single.readAsString())['format'], isNotNull);
  });

  test('a folder that cannot be created never throws', () async {
    await repo.createWorld('โลก');
    final blocker = File('${dir.path}/blocker')..writeAsStringSync('x');
    final broken = AutoBackup(repo, dir: () async => Directory('${blocker.path}/inside'), clock: () => now);
    expect(await broken.run(), isEmpty);
    final failing = AutoBackup(repo, dir: () async => throw const FileSystemException('no folder'), clock: () => now);
    expect(await failing.run(), isEmpty);
  });
}
