import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'sync.dart';

const syncDefaultPort = 48765;
const _protocol = 1;
const _maxBody = 64 * 1024 * 1024;

/// True for addresses that can only be reached from the local network (or this machine).
bool isLocalAddress(InternetAddress a) {
  if (a.isLoopback || a.isLinkLocal) return true;
  if (a.type != InternetAddressType.IPv4) return false;
  final b = a.rawAddress;
  return b[0] == 10 || (b[0] == 172 && b[1] >= 16 && b[1] <= 31) || (b[0] == 192 && b[1] == 168);
}

/// This device's LAN addresses, most likely home-Wi-Fi ones (192.168.x.x) first.
Future<List<String>> localAddresses() async {
  final out = <String>[];
  for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
    for (final a in i.addresses) {
      if (!a.isLoopback && isLocalAddress(a)) out.add(a.address);
    }
  }
  out.sort((x, y) => (y.startsWith('192.168.') ? 1 : 0).compareTo(x.startsWith('192.168.') ? 1 : 0));
  return out;
}

String _sign(String code, String timestamp, List<int> body) {
  final h = Hmac(sha256, utf8.encode(code));
  return h.convert([...utf8.encode('$timestamp\n'), ...body]).toString();
}

bool _sameString(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

/// Something that happened on the server, for the "waiting for the other device" screen.
class SyncEvent {
  SyncEvent(this.time, this.message, {this.isError = false});
  final DateTime time;
  final String message;
  final bool isError;
}

/// Lets another device on the same network merge its data with this one.
///
/// Requests are signed with the pairing code (HMAC), so the code is never sent in the clear and
/// guessing is throttled. The data itself is NOT encrypted: use it on a network you trust.
class SyncServer {
  SyncServer(this.service, {this.idleTimeout = const Duration(minutes: 15), this.requireLocal = true});
  final SyncService service;
  final Duration idleTimeout;

  /// Refuse callers that are not on a private network. Only turned off by tests.
  final bool requireLocal;

  HttpServer? _server;
  String _code = '';
  Timer? _idle;
  final _events = StreamController<SyncEvent>.broadcast();
  Future<void> _queue = Future.value(); // merges run one at a time
  final _failures = <DateTime>[];

  bool get running => _server != null;
  int get port => _server?.port ?? 0;
  String get code => _code;
  Stream<SyncEvent> get events => _events.stream;

  /// Starts listening. Uses [port] if free, otherwise any free port.
  Future<void> start({int port = syncDefaultPort, String? code, InternetAddress? bindTo}) async {
    if (running) return;
    _code = code ?? (100000 + Random.secure().nextInt(900000)).toString();
    final address = bindTo ?? InternetAddress.anyIPv4;
    try {
      _server = await HttpServer.bind(address, port);
    } on SocketException {
      _server = await HttpServer.bind(address, 0);
    }
    _server!.listen(_handle, onError: (_) {});
    _touch();
  }

  Future<void> stop() async {
    _idle?.cancel();
    final s = _server;
    _server = null;
    await s?.close(force: true);
  }

  void _touch() {
    _idle?.cancel();
    _idle = Timer(idleTimeout, () {
      _emit('หยุดรับซิงก์อัตโนมัติ (ไม่มีการใช้งานนาน ${idleTimeout.inMinutes} นาที)');
      stop();
    });
  }

  void _emit(String m, {bool error = false}) {
    if (!_events.isClosed) _events.add(SyncEvent(DateTime.now(), m, isError: error));
  }

  Future<void> _reply(HttpResponse r, int status, Object body) async {
    r.statusCode = status;
    r.headers.contentType = ContentType.json;
    r.write(jsonEncode(body));
    await r.close();
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    try {
      final remote = req.connectionInfo?.remoteAddress;
      if (requireLocal && (remote == null || !isLocalAddress(remote))) {
        await _reply(res, 403, {'error': 'อนุญาตเฉพาะเครือข่ายในบ้าน'});
        return;
      }
      _touch();

      if (req.method == 'GET' && req.uri.path == '/ping') {
        await _reply(res, 200, {'app': 'nsl-writer-tools', 'protocol': _protocol});
        return;
      }
      if (req.method != 'POST' || req.uri.path != '/sync') {
        await _reply(res, 404, {'error': 'not found'});
        return;
      }

      // Throttle guessing: after 5 bad signatures in a minute, refuse everything for a while.
      final now = DateTime.now();
      _failures.removeWhere((t) => now.difference(t) > const Duration(minutes: 1));
      if (_failures.length >= 5) {
        await _reply(res, 429, {'error': 'ใส่รหัสผิดหลายครั้ง — รอสักครู่แล้วลองใหม่'});
        return;
      }

      final length = req.contentLength;
      if (length > _maxBody) {
        await _reply(res, 413, {'error': 'ข้อมูลใหญ่เกินไป'});
        return;
      }
      final bytes = <int>[];
      await for (final chunk in req) {
        bytes.addAll(chunk);
        if (bytes.length > _maxBody) {
          await _reply(res, 413, {'error': 'ข้อมูลใหญ่เกินไป'});
          return;
        }
      }

      final ts = req.headers.value('x-nsl-ts') ?? '';
      final sig = req.headers.value('x-nsl-sig') ?? '';
      final sentAt = int.tryParse(ts);
      final fresh = sentAt != null && (now.millisecondsSinceEpoch - sentAt).abs() < const Duration(minutes: 10).inMilliseconds;
      if (!fresh || !_sameString(sig, _sign(_code, ts, bytes))) {
        _failures.add(now);
        _emit('มีอุปกรณ์เชื่อมต่อด้วยรหัสไม่ถูกต้อง', error: true);
        await _reply(res, 401, {'error': 'รหัสไม่ถูกต้อง'});
        return;
      }

      final String reply;
      final List<SyncReport> reports;
      try {
        final job = _queue.then((_) => service.exchange(utf8.decode(bytes)));
        _queue = job.then((_) {}, onError: (_) {});
        (reports, reply) = await job;
      } on SyncException catch (e) {
        _emit('ซิงก์ไม่สำเร็จ: ${e.message}', error: true);
        await _reply(res, 400, {'error': e.message});
        return;
      }
      _emit('ซิงก์กับ ${remote?.address ?? 'อุปกรณ์อื่น'}: ${reports.map((r) => r.summary).join(' · ')}');
      await _reply(res, 200, {
        'bundle': reply,
        'reports': [for (final r in reports) r.summary],
      });
    } catch (e) {
      _emit('ข้อผิดพลาด: $e', error: true);
      try {
        await _reply(res, 500, {'error': 'เกิดข้อผิดพลาดในเครื่องที่รับ'});
      } catch (_) {}
    }
  }
}

class ClientSyncResult {
  ClientSyncResult({required this.here, required this.there});

  /// What changed on THIS device.
  final List<SyncReport> here;

  /// What changed on the other device (as it reported).
  final List<String> there;
}

/// Syncs this device with another one running a [SyncServer].
class SyncClient {
  SyncClient(this.service);
  final SyncService service;

  /// "192.168.1.20" or "192.168.1.20:8765".
  static (String, int) parseAddress(String input) {
    var s = input.trim().replaceFirst(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/+$'), '');
    var port = syncDefaultPort;
    final colon = s.lastIndexOf(':');
    if (colon > 0) {
      final p = int.tryParse(s.substring(colon + 1));
      if (p == null || p < 1 || p > 65535) throw SyncException('เลขพอร์ตไม่ถูกต้อง');
      port = p;
      s = s.substring(0, colon);
    }
    if (s.isEmpty || RegExp(r'\s').hasMatch(s)) throw SyncException('ใส่ที่อยู่ของอีกเครื่อง เช่น 192.168.1.20');
    return (s, port);
  }

  Future<ClientSyncResult> sync({required String address, required String code, Duration timeout = const Duration(seconds: 30)}) async {
    final (host, port) = parseAddress(address);
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) throw SyncException('ใส่รหัสจับคู่ที่แสดงบนอีกเครื่อง');

    final http = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      // 1. Is anything there, and is it us?
      try {
        final ping = await (await http.get(host, port, '/ping')).close().timeout(const Duration(seconds: 8));
        final body = await ping.transform(utf8.decoder).join();
        if (ping.statusCode != 200 || (jsonDecode(body) as Map)['app'] != 'nsl-writer-tools') {
          throw SyncException('ที่อยู่นี้ไม่ใช่แอป NSL Writer Tools');
        }
      } on SyncException {
        rethrow;
      } on SocketException {
        throw SyncException('เชื่อมต่อไม่ได้ — ตรวจว่าอยู่ Wi-Fi เดียวกัน และอีกเครื่องกด “รับซิงก์” ค้างไว้อยู่');
      } on TimeoutException {
        throw SyncException('เชื่อมต่อไม่ได้ (หมดเวลา) — ตรวจที่อยู่ และว่า Wi-Fi ไม่ได้แยกอุปกรณ์ออกจากกัน');
      } on FormatException {
        throw SyncException('ที่อยู่นี้ไม่ใช่แอป NSL Writer Tools');
      } on HttpException {
        throw SyncException('ที่อยู่นี้ไม่ใช่แอป NSL Writer Tools');
      }

      // 2. Send ours, get theirs.
      final payload = utf8.encode(await service.exportBundle());
      final ts = DateTime.now().millisecondsSinceEpoch.toString();
      final Map reply;
      try {
        final req = await http.post(host, port, '/sync');
        req.headers
          ..contentType = ContentType.json
          ..set('x-nsl-ts', ts)
          ..set('x-nsl-sig', _sign(cleanCode, ts, payload));
        req.contentLength = payload.length;
        req.add(payload);
        final resp = await req.close().timeout(timeout);
        final text = await resp.transform(utf8.decoder).join().timeout(timeout);
        final Map parsed = jsonDecode(text) as Map;
        if (resp.statusCode == 401) throw SyncException('รหัสไม่ถูกต้อง — ดูรหัสบนอีกเครื่องอีกครั้ง');
        if (resp.statusCode != 200) throw SyncException((parsed['error'] as String?) ?? 'อีกเครื่องปฏิเสธการซิงก์ (${resp.statusCode})');
        reply = parsed;
      } on SyncException {
        rethrow;
      } on TimeoutException {
        throw SyncException('อีกเครื่องตอบช้าเกินไป ลองใหม่อีกครั้ง');
      } on SocketException {
        throw SyncException('การเชื่อมต่อขาดหาย ลองใหม่อีกครั้ง');
      } on FormatException {
        throw SyncException('คำตอบจากอีกเครื่องอ่านไม่ได้');
      }

      // 3. Merge what they have into ours. (They already merged ours.)
      final here = await service.mergeBundle(reply['bundle'] as String);
      return ClientSyncResult(here: here, there: [for (final r in (reply['reports'] as List? ?? const [])) r.toString()]);
    } finally {
      http.close(force: true);
    }
  }
}
