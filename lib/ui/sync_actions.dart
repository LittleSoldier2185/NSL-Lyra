import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync.dart';
import '../data/sync_net.dart';
import '../data/sync_prefs.dart';
import '../providers.dart';
import '../theme.dart';

final syncServiceProvider = Provider<SyncService>((ref) => SyncService(ref.watch(repositoryProvider)));

String _stamp() {
  final n = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${n.year}${two(n.month)}${two(n.day)}';
}

// ---------------------------------------------------------------- files

// The messenger is captured before any await, so no BuildContext is used afterwards.
void showToast(ScaffoldMessengerState m, String msg) => m
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(msg)));

Future<void> exportSyncFile(BuildContext context, WidgetRef ref) async {
  final m = ScaffoldMessenger.of(context);
  final text = await ref.read(syncServiceProvider).exportBundle();
  try {
    final uri = await FilePicker.saveFile(
      dialogTitle: 'บันทึกไฟล์ซิงก์',
      fileName: 'nsl_sync_${_stamp()}.nslsync.json',
      bytes: utf8.encode(text),
      mimeType: 'application/json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    showToast(m, uri == null ? 'ยกเลิกการส่งออก' : 'ส่งออกไฟล์ซิงก์แล้ว');
  } catch (e) {
    showToast(m, 'ส่งออกไม่สำเร็จ: $e');
  }
}

/// Pick a sync file from another device and merge it in.
Future<void> mergeSyncFile(BuildContext context, WidgetRef ref) async {
  final m = ScaffoldMessenger.of(context);
  final String text;
  try {
    final file = await FilePicker.pickFile(dialogTitle: 'เลือกไฟล์ซิงก์', type: FileType.custom, allowedExtensions: ['json']);
    if (file == null) return;
    text = utf8.decode(await file.readAsBytes());
  } catch (e) {
    showToast(m, 'เปิดไฟล์ไม่สำเร็จ: $e');
    return;
  }
  try {
    final reports = await ref.read(syncServiceProvider).mergeBundle(text);
    if (!context.mounted) return;
    await _showResult(context, title: 'รวมข้อมูลแล้ว', here: reports.map((r) => r.summary).toList(), footer: 'ส่งไฟล์ซิงก์กลับไปอีกเครื่องด้วย “ส่งออกไฟล์ซิงก์” เพื่อให้ข้อมูลตรงกันทั้งสองเครื่อง');
  } on SyncException catch (e) {
    showToast(m, e.message);
  } catch (e) {
    showToast(m, 'รวมข้อมูลไม่สำเร็จ: $e');
  }
}

Future<void> _showResult(BuildContext context, {required String title, required List<String> here, List<String> there = const [], String? footer}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: T.serif(18, w: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (here.isNotEmpty) ...[
              Text('เครื่องนี้', style: T.ui(12, w: FontWeight.w600, color: C.inkFaint)),
              for (final s in here) Padding(padding: const EdgeInsets.only(top: 4), child: Text(s, style: T.ui(14, h: 1.5))),
            ],
            if (there.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('อีกเครื่อง', style: T.ui(12, w: FontWeight.w600, color: C.inkFaint)),
              for (final s in there) Padding(padding: const EdgeInsets.only(top: 4), child: Text(s, style: T.ui(14, h: 1.5))),
            ],
            if (footer != null) ...[
              const SizedBox(height: 14),
              Text(footer, style: T.ui(12, color: C.inkSoft, h: 1.5)),
            ],
          ]),
        ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('ตกลง'))],
    ),
  );
}

// ---------------------------------------------------------------- Wi-Fi: this device waits

Future<void> showHostDialog(BuildContext context) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _HostDialog(),
    );

class _HostDialog extends ConsumerStatefulWidget {
  const _HostDialog();

  @override
  ConsumerState<_HostDialog> createState() => _HostDialogState();
}

class _HostDialogState extends ConsumerState<_HostDialog> {
  late final SyncServer _server = SyncServer(ref.read(syncServiceProvider));
  final _log = <SyncEvent>[];
  List<String> _addresses = const [];
  StreamSubscription<SyncEvent>? _sub;
  String? _error;
  bool _starting = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      _sub = _server.events.listen((e) {
        if (mounted) setState(() => _log.insert(0, e));
      });
      await _server.start();
      final addrs = await localAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = addrs;
        _starting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'เปิดรับซิงก์ไม่สำเร็จ: $e';
        _starting = false;
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _server.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stopped = !_starting && !_server.running && _error == null;
    return AlertDialog(
      title: Text('รับซิงก์ผ่าน Wi-Fi', style: T.serif(18, w: FontWeight.w700)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_starting) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
            else if (_error != null) Text(_error!, style: T.ui(14, color: C.accent))
            else ...[
              Text('บนอีกเครื่อง เลือก “ซิงก์กับอีกเครื่อง” แล้วใส่ที่อยู่และรหัสนี้', style: T.ui(13, color: C.inkSoft, h: 1.5)),
              const SizedBox(height: 14),
              Text('ที่อยู่', style: T.ui(12, color: C.inkFaint)),
              if (_addresses.isEmpty)
                Text('ไม่พบ Wi-Fi — เชื่อมต่อเครือข่ายก่อน', style: T.ui(14, color: C.accent))
              else
                for (final a in _addresses)
                  InkWell(
                    onTap: () => Clipboard.setData(ClipboardData(text: '$a:${_server.port}')),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      // Large text or a narrow phone must shrink this, never overflow: it has to be readable.
                      child: Row(children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('$a:${_server.port}', style: T.mono(18, w: FontWeight.w500, color: C.ink)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.copy, size: 18, color: C.inkSoft),
                      ]),
                    ),
                  ),
              const SizedBox(height: 12),
              Text('รหัสจับคู่', style: T.ui(12, color: C.inkFaint)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(_server.code, style: T.mono(34, w: FontWeight.w500, color: C.accent)),
              ),
              const SizedBox(height: 12),
              Text(
                stopped ? '● หยุดรับซิงก์แล้ว' : '● กำลังรอการเชื่อมต่อ…  เปิดหน้านี้ค้างไว้ และให้ทั้งสองเครื่องอยู่ Wi-Fi เดียวกัน',
                style: T.ui(13, color: stopped ? C.inkFaint : C.saved),
              ),
              if (_log.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final e in _log.take(6))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(e.message, style: T.ui(12, color: e.isError ? C.accent : C.inkSoft, h: 1.4)),
                  ),
              ],
              const SizedBox(height: 14),
              Text('ข้อมูลส่งผ่านเครือข่ายในบ้านแบบไม่เข้ารหัส ใช้เฉพาะ Wi-Fi ที่ไว้ใจได้', style: T.ui(11, color: C.inkFaint, h: 1.4)),
            ],
          ]),
        ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('หยุดรับซิงก์'))],
    );
  }
}

// ---------------------------------------------------------------- Wi-Fi: this device connects

Future<void> showConnectDialog(BuildContext context) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ConnectDialog(),
    );

class _ConnectDialog extends ConsumerStatefulWidget {
  const _ConnectDialog();

  @override
  ConsumerState<_ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends ConsumerState<_ConnectDialog> {
  final _address = TextEditingController();
  final _code = TextEditingController();
  final _prefs = SyncPrefs();
  bool _busy = false;
  String? _error;
  ClientSyncResult? _done;

  @override
  void initState() {
    super.initState();
    _prefs.lastAddress().then((a) {
      if (mounted && _address.text.isEmpty) _address.text = a;
    });
  }

  @override
  void dispose() {
    _address.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await SyncClient(ref.read(syncServiceProvider)).sync(address: _address.text, code: _code.text);
      await _prefs.saveLastAddress(_address.text.trim());
      if (mounted) setState(() => _done = r);
    } on SyncException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'ซิงก์ไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _done;
    return AlertDialog(
      title: Text(done == null ? 'ซิงก์กับอีกเครื่อง' : 'ซิงก์เสร็จแล้ว', style: T.serif(18, w: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: done != null
              ? Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('เครื่องนี้', style: T.ui(12, w: FontWeight.w600, color: C.inkFaint)),
                  for (final r in done.here) Padding(padding: const EdgeInsets.only(top: 4), child: Text(r.summary, style: T.ui(14, h: 1.5))),
                  if (done.here.isEmpty) Text('ไม่มีโลกให้ซิงก์', style: T.ui(14, color: C.inkFaint)),
                  const SizedBox(height: 14),
                  Text('อีกเครื่อง', style: T.ui(12, w: FontWeight.w600, color: C.inkFaint)),
                  for (final s in done.there) Padding(padding: const EdgeInsets.only(top: 4), child: Text(s, style: T.ui(14, h: 1.5))),
                ])
              : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('บนอีกเครื่อง เลือก “รับซิงก์ผ่าน Wi-Fi” ค้างไว้ แล้วใส่ที่อยู่และรหัสที่แสดง', style: T.ui(13, color: C.inkSoft, h: 1.5)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _address,
                    enabled: !_busy,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: 'ที่อยู่ เช่น 192.168.1.20:48765'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _code,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _go(),
                    decoration: const InputDecoration(labelText: 'รหัสจับคู่ 6 หลัก'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: T.ui(13, color: C.accent, h: 1.5)),
                  ],
                  if (_busy) ...[const SizedBox(height: 14), const LinearProgressIndicator()],
                ]),
        ),
      ),
      actions: [
        if (done == null) TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('ยกเลิก')),
        FilledButton(
          onPressed: _busy ? null : (done == null ? _go : () => Navigator.pop(context)),
          child: Text(done == null ? 'ซิงก์' : 'ตกลง'),
        ),
      ],
    );
  }
}
