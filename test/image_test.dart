import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nsl_writer_tools/data/backup.dart';
import 'package:nsl_writer_tools/data/database.dart';
import 'package:nsl_writer_tools/data/image_store.dart';
import 'package:nsl_writer_tools/data/repository.dart';

import 'sync_test.dart' show Device, syncBoth;

/// A picture with a gradient (so JPEG has something to compress) and optionally a transparent half.
Uint8List png(int w, int h, {bool alpha = false, int shade = 120}) {
  final image = img.Image(width: w, height: h, numChannels: 4);
  for (final px in image) {
    px
      ..r = shade
      ..g = (px.x * 255 ~/ w)
      ..b = (px.y * 255 ~/ h)
      ..a = alpha && px.x < w ~/ 2 ? 0 : 255;
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory root;
  setUp(() async => root = await Directory.systemTemp.createTemp('images'));
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  ImageStore store([String sub = 'a']) => ImageStore(dir: Directory('${root.path}/$sub'));

  group('ImageStore', () {
    test('stores a picture under a content name and reads it back', () async {
      final s = store();
      final name = await s.addFromBytes(png(200, 100));
      expect(ImageStore.validName(name), isTrue);
      expect(name, endsWith('.jpg'), reason: 'opaque pictures become JPEG');
      final back = img.decodeImage((await s.read(name))!)!;
      expect((back.width, back.height), (200, 100));
      expect(await s.addFromBytes(png(200, 100)), name, reason: 'same picture, same file');
      expect((await (await s.folder()).list().toList()).length, 1);
    });

    test('big pictures are scaled down, keeping the shape', () async {
      final s = store();
      final wide = img.decodeImage((await s.read(await s.addFromBytes(png(3000, 1500))))!)!;
      expect((wide.width, wide.height), (ImageStore.maxSide, 640));
      final tall = img.decodeImage((await s.read(await s.addFromBytes(png(1000, 4000, shade: 30))))!)!;
      expect((tall.width, tall.height), (320, ImageStore.maxSide));
    });

    test('transparency is kept (PNG)', () async {
      final s = store();
      final name = await s.addFromBytes(png(64, 64, alpha: true));
      expect(name, endsWith('.png'));
      expect(img.decodeImage((await s.read(name))!)!.hasAlpha, isTrue);
    });

    test('something that is not a picture is refused with a Thai message', () async {
      final s = store();
      await expectLater(s.addFromBytes(Uint8List.fromList(utf8.encode('hello'))), throwsA(isA<ImageException>()));
      await expectLater(s.addFromBytes(Uint8List(0)), throwsA(isA<ImageException>()));
      expect(await (await s.folder()).list().toList(), isEmpty);
    });

    test('names from outside are only accepted for exactly their own bytes', () async {
      final a = store('a'), b = store('b');
      final name = await a.addFromBytes(png(50, 50));
      final bytes = (await a.read(name))!;
      expect(await b.saveFromOutside(name, bytes), isTrue);
      expect(await b.read(name), bytes);
      // Right shape of name, wrong bytes for it.
      final other = (name[0] == '0' ? '1' : '0') + name.substring(1);
      expect(await b.saveFromOutside(other, bytes), isFalse);
      // Path tricks, odd extensions, empty and oversized data.
      for (final bad in ['../evil.jpg', '..\\evil.png', 'a/b.jpg', 'abc.jpg', '0123456789abcdef.exe', '0123456789ABCDEF.jpg', '']) {
        expect(ImageStore.validName(bad), isFalse, reason: bad);
        expect(await b.saveFromOutside(bad, bytes), isFalse, reason: bad);
      }
      expect(await b.saveFromOutside(name, Uint8List(0)), isFalse);
      expect(await b.saveFromOutside(name, Uint8List(ImageStore.maxBytes + 1)), isFalse);
      expect((await (await b.folder()).list().toList()).length, 1);
    });

    test('importData: base64 in; bad base64 and unknown names out', () async {
      final a = store('a'), b = store('b');
      final name = await a.addFromBytes(png(40, 40));
      final data = (await a.exportData([name, null, 'nope']))[name]!;
      expect(await b.importData(name, data), isTrue);
      expect(await b.importData('0123456789abcdef.jpg', 'not base64!!'), isFalse);
      expect(await b.importData('0123456789abcdef.jpg', null), isFalse);
      expect(await b.importData(null, data), isFalse);
      expect(await b.importData(name, null), isTrue, reason: 'already stored');
    });

    test('prune removes only unreferenced pictures', () async {
      final s = store();
      final keep = await s.addFromBytes(png(30, 30, shade: 10));
      final drop = await s.addFromBytes(png(30, 30, shade: 200));
      await File('${(await s.folder()).path}/notes.txt').writeAsString('not ours');
      expect(await s.prune({keep}), 1);
      expect(await s.has(keep), isTrue);
      expect(await s.has(drop), isFalse);
      expect(File('${(await s.folder()).path}/notes.txt').existsSync(), isTrue);
    });
  });

  group('with entries', () {
    late AppDatabase db;
    late Repository repo;
    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = Repository(db, images: store());
    });
    tearDown(() => db.close());

    test('duplicate keeps the picture; pruneImages follows what entries use', () async {
      final w = await repo.createWorld('โลก');
      final e = await repo.createEntry(worldId: w.id, type: EntryType.character, title: 'อาริน');
      final name = await repo.images.addFromBytes(png(60, 60));
      await repo.updateEntry(e.id, imagePath: Value(name));
      final copy = await repo.duplicateEntry(e.id);
      expect(copy.imagePath, name);

      await repo.deleteEntry(e.id);
      expect(await repo.pruneImages(), 0, reason: 'the copy still uses it');
      await repo.deleteEntry(copy.id);
      expect(await repo.pruneImages(), 1);
      expect(await repo.images.has(name), isFalse);
    });

    test('a backup carries the picture and restores it on another device', () async {
      final w = await repo.createWorld('โลก');
      final e = await repo.createEntry(worldId: w.id, type: EntryType.place, title: 'เมือง');
      final name = await repo.images.addFromBytes(png(80, 40));
      await repo.updateEntry(e.id, imagePath: Value(name));
      final json = jsonEncode(await BackupService(repo).exportWorld(w));
      expect(jsonDecode(json)['entries'][0]['imageData'], isA<String>());

      final other = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(other.close);
      final repo2 = Repository(other, images: store('device2'));
      final r = await BackupService(repo2).importWorld(json);
      final restored = (await repo2.entriesOfWorld(r.world.id)).single;
      expect(restored.imagePath, name);
      expect(await repo2.images.has(name), isTrue);
    });

    test('a backup whose picture cannot be restored imports without it; tricky names are dropped', () async {
      final w = await repo.createWorld('โลก');
      await repo.createEntry(worldId: w.id, type: EntryType.place, title: 'ก');
      await repo.createEntry(worldId: w.id, type: EntryType.place, title: 'ข');
      final map = await BackupService(repo).exportWorld(w);
      final entries = (map['entries'] as List).cast<Map>();
      entries[0]['imagePath'] = '0123456789abcdef.jpg'; // no data, not stored here
      entries[1]
        ..['imagePath'] = '../../outside.jpg'
        ..['imageData'] = base64Encode([1, 2, 3]);
      final r = await BackupService(repo).importWorld(jsonEncode(map));
      final imported = await repo.entriesOfWorld(r.world.id);
      expect(imported.map((e) => e.imagePath), [null, null]);
    });
  });

  group('sync', () {
    final t0 = DateTime(2026, 10, 12, 9);

    test('a picture added on one device appears on the other, and both agree', () async {
      final a = Device('A', t0, images: Directory('${root.path}/A')), b = Device('B', t0, images: Directory('${root.path}/B'));
      final w = await a.repo.createWorld('โลก');
      final e = await a.repo.createEntry(worldId: w.id, type: EntryType.character, title: 'อาริน');
      a.tick();
      final name = await a.repo.images.addFromBytes(png(90, 90));
      await a.repo.updateEntry(e.id, imagePath: Value(name));
      a.tick();
      await syncBoth(a, b);

      final onB = (await b.repo.entriesOfWorld(w.id)).single;
      expect(onB.imagePath, name);
      expect(await b.repo.images.read(name), await a.repo.images.read(name));
      expect(await a.fingerprint(), await b.fingerprint());

      // Replacing it later travels back.
      b.at(a.nowForTest().add(const Duration(seconds: 30)));
      final newer = await b.repo.images.addFromBytes(png(90, 90, shade: 250));
      await b.repo.updateEntry(e.id, imagePath: Value(newer));
      b.tick();
      a.at(b.nowForTest());
      await syncBoth(b, a);
      expect((await a.repo.entriesOfWorld(w.id)).single.imagePath, newer);
      expect(await a.repo.images.has(newer), isTrue);
      await a.close();
      await b.close();
    });

    test('a sync file cannot plant files or point outside the images folder', () async {
      final a = Device('A', t0, images: Directory('${root.path}/A')), b = Device('B', t0, images: Directory('${root.path}/B'));
      final w = await a.repo.createWorld('โลก');
      await a.repo.createEntry(worldId: w.id, type: EntryType.character, title: 'อาริน');
      a.tick();
      final bundle = jsonDecode(await a.sync.exportBundle()) as Map;
      final entry = ((bundle['snapshots'] as List).first['entries'] as List).first as Map;
      entry['imagePath'] = '../../planted.jpg';
      entry['imageData'] = base64Encode(utf8.encode('payload'));
      await b.sync.mergeBundle(jsonEncode(bundle));

      expect((await b.repo.entriesOfWorld(w.id)).single.imagePath, isNull);
      expect(File('${root.path}/planted.jpg').existsSync(), isFalse);
      final bDir = Directory('${root.path}/B');
      expect(!bDir.existsSync() || (await bDir.list().toList()).isEmpty, isTrue);
      await a.close();
      await b.close();
    });
  });
}
