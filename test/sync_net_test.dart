import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_writer_tools/data/database.dart';
import 'package:nsl_writer_tools/data/repository.dart';
import 'package:nsl_writer_tools/data/seed.dart';
import 'package:nsl_writer_tools/data/sync.dart';
import 'package:nsl_writer_tools/data/sync_net.dart';

/// Real sockets on 127.0.0.1 between two in-memory devices.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase dbA, dbB;
  late Repository a, b;
  late SyncServer server;
  late SyncClient client;

  setUp(() async {
    dbA = AppDatabase.forTesting(NativeDatabase.memory());
    dbB = AppDatabase.forTesting(NativeDatabase.memory());
    a = Repository(dbA);
    b = Repository(dbB);
    // `b` is the device that listens; `a` is the phone that connects.
    server = SyncServer(SyncService(b));
    await server.start(port: 0, code: '123456', bindTo: InternetAddress.loopbackIPv4);
    client = SyncClient(SyncService(a));
  });
  tearDown(() async {
    await server.stop();
    await dbA.close();
    await dbB.close();
  });

  String addr() => '127.0.0.1:${server.port}';

  test('a sync moves data both ways in one go', () async {
    final w = await a.createWorld('จากมือถือ');
    await a.createEntry(worldId: w.id, type: EntryType.place, title: 'only on phone');
    final w2 = await b.createWorld('จากพีซี');
    await b.createEntry(worldId: w2.id, type: EntryType.place, title: 'only on pc');

    final events = <SyncEvent>[];
    final sub = server.events.listen(events.add);
    final result = await client.sync(address: addr(), code: '123456');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();

    expect((await a.worlds()).map((x) => x.name).toSet(), {'จากมือถือ', 'จากพีซี'});
    expect((await b.worlds()).map((x) => x.name).toSet(), {'จากมือถือ', 'จากพีซี'});
    expect(result.here.where((r) => r.createdWorld), hasLength(1)); // the phone received the PC's world
    expect(result.there.single, contains('จากมือถือ'));
    expect(events.where((e) => !e.isError), isNotEmpty);

    // Both devices now agree on every world.
    for (final r in [a, b]) {
      for (final world in await r.worlds()) {
        expect(await r.entriesOfWorld(world.id), isNotEmpty);
      }
    }
  });

  test('syncing the full sample world, then again, changes nothing the second time', () async {
    final w = await a.createWorld('หมู่เกาะเงาจันทร์');
    await seedSampleWorld(a, w.id);
    await client.sync(address: addr(), code: '123456');
    final wb = (await b.worlds()).single.id;
    expect(await b.entriesOfWorld(wb), hasLength((await a.entriesOfWorld(w.id)).length));
    expect(await b.relationsOfWorld(wb), hasLength((await a.relationsOfWorld(w.id)).length));
    expect(await b.timelineOfWorld(wb), isNotEmpty);

    final again = await client.sync(address: addr(), code: '123456');
    expect(again.here.every((r) => !r.changed), isTrue);
  });

  test('edits on each side travel on the next sync', () async {
    final w = await a.createWorld('w');
    final e = await a.createEntry(worldId: w.id, type: EntryType.place, title: 'x', body: 'one');
    await client.sync(address: addr(), code: '123456');

    await Future<void>.delayed(const Duration(milliseconds: 1100)); // stamps are whole seconds
    final onB = (await b.entriesOfWorld(w.id)).single;
    await b.updateEntry(onB.id, body: 'edited on pc');
    await client.sync(address: addr(), code: '123456');
    expect((await a.entriesOfWorld(w.id)).single.body, 'edited on pc');

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await a.updateEntry(e.id, summary: 'edited on phone');
    await client.sync(address: addr(), code: '123456');
    expect((await b.entriesOfWorld(w.id)).single.summary, 'edited on phone');
  });

  group('errors are readable, and nothing is changed', () {
    test('wrong code', () async {
      await a.createWorld('w');
      await expectLater(
          client.sync(address: addr(), code: '000000'), throwsA(isA<SyncException>().having((e) => e.message, 'message', contains('รหัสไม่ถูกต้อง'))));
      expect(await b.worlds(), isEmpty);
    });

    test('five wrong codes lock the server out, even for the right code', () async {
      await a.createWorld('w');
      for (var i = 0; i < 5; i++) {
        await expectLater(client.sync(address: addr(), code: '00000$i'), throwsA(isA<SyncException>()));
      }
      await expectLater(client.sync(address: addr(), code: '123456'),
          throwsA(isA<SyncException>().having((e) => e.message, 'message', contains('รอสักครู่'))));
      expect(await b.worlds(), isEmpty);
    });

    test('nobody listening', () async {
      final port = server.port;
      await server.stop();
      await expectLater(client.sync(address: '127.0.0.1:$port', code: '123456'),
          throwsA(isA<SyncException>().having((e) => e.message, 'message', contains('เชื่อมต่อไม่ได้'))));
    });

    test('something else is listening', () async {
      final other = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      other.listen((r) async {
        r.response.write('hello');
        await r.response.close();
      });
      await expectLater(client.sync(address: '127.0.0.1:${other.port}', code: '1'), throwsA(isA<SyncException>()));
      await other.close(force: true);
    });

    test('garbage sent to /sync with a valid signature is refused cleanly', () async {
      // Craft a correctly signed but meaningless body: the server must answer 400, not crash.
      final http = HttpClient();
      final body = utf8.encode('not json at all');
      final ts = DateTime.now().millisecondsSinceEpoch.toString();
      final req = await http.post('127.0.0.1', server.port, '/sync');
      req.headers
        ..set('x-nsl-ts', ts)
        ..set('x-nsl-sig', _signForTest('123456', ts, body));
      req.add(body);
      final resp = await req.close();
      await resp.drain<void>();
      expect(resp.statusCode, 400);
      http.close(force: true);
      expect(server.running, isTrue);
    });

    test('an old signed request is rejected (replay window)', () async {
      final http = HttpClient();
      final body = utf8.encode('{}');
      final ts = DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch.toString();
      final req = await http.post('127.0.0.1', server.port, '/sync');
      req.headers
        ..set('x-nsl-ts', ts)
        ..set('x-nsl-sig', _signForTest('123456', ts, body));
      req.add(body);
      final resp = await req.close();
      await resp.drain<void>();
      expect(resp.statusCode, 401);
      http.close(force: true);
    });
  });

  test('requests from outside the local network are refused', () {
    expect(isLocalAddress(InternetAddress('192.168.1.5')), isTrue);
    expect(isLocalAddress(InternetAddress('10.0.0.7')), isTrue);
    expect(isLocalAddress(InternetAddress('172.20.1.1')), isTrue);
    expect(isLocalAddress(InternetAddress('127.0.0.1')), isTrue);
    expect(isLocalAddress(InternetAddress('172.32.0.1')), isFalse);
    expect(isLocalAddress(InternetAddress('8.8.8.8')), isFalse);
    expect(isLocalAddress(InternetAddress('203.0.113.9')), isFalse);
  });

  test('the server stops by itself when idle', () async {
    await server.stop();
    final idle = SyncServer(SyncService(b), idleTimeout: const Duration(milliseconds: 150));
    await idle.start(port: 0, bindTo: InternetAddress.loopbackIPv4);
    expect(idle.running, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(idle.running, isFalse);
  });

  test('addresses are parsed forgivingly, and bad ones explain themselves', () {
    expect(SyncClient.parseAddress('192.168.1.20'), ('192.168.1.20', syncDefaultPort));
    expect(SyncClient.parseAddress(' 192.168.1.20:9000 '), ('192.168.1.20', 9000));
    expect(SyncClient.parseAddress('http://192.168.1.20:9000/'), ('192.168.1.20', 9000));
    for (final bad in ['', '   ', 'a b', '1.2.3.4:abc', '1.2.3.4:99999']) {
      expect(() => SyncClient.parseAddress(bad), throwsA(isA<SyncException>()), reason: bad);
    }
    expect(() => client.sync(address: '1.2.3.4', code: ''), throwsA(isA<SyncException>()));
  });
}

// Same HMAC as the app uses, written out independently so the test checks the wire format.
String _signForTest(String code, String ts, List<int> body) =>
    Hmac(sha256, utf8.encode(code)).convert([...utf8.encode('$ts\n'), ...body]).toString();
