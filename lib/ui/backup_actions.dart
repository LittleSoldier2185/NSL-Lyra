import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backup.dart';
import '../data/database.dart';
import '../providers.dart';
import '../theme.dart';
import 'sync_actions.dart';

final backupServiceProvider = Provider<BackupService>((ref) => BackupService(ref.watch(repositoryProvider)));

String _stamp() {
  final n = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${n.year}${two(n.month)}${two(n.day)}';
}

// The messenger is captured before any await, so no BuildContext is used afterwards.
void _toast(ScaffoldMessengerState m, String msg) {
  m
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

Future<void> _save(ScaffoldMessengerState m, String fileName, String text, String ext, String mime) async {
  try {
    final uri = await FilePicker.saveFile(
      dialogTitle: 'บันทึกไฟล์',
      fileName: fileName,
      bytes: utf8.encode(text),
      mimeType: mime,
      type: FileType.custom,
      allowedExtensions: [ext],
    );
    _toast(m, uri == null ? 'ยกเลิกการส่งออก' : 'ส่งออกแล้ว');
  } catch (e) {
    _toast(m, 'ส่งออกไม่สำเร็จ: $e');
  }
}

Future<void> exportWorldJson(BuildContext context, WidgetRef ref) async {
  final m = ScaffoldMessenger.of(context);
  final world = ref.read(activeWorldProvider);
  if (world == null) return;
  final svc = ref.read(backupServiceProvider);
  final text = svc.encode(await svc.exportWorld(world));
  await _save(m, '${safeFileName(world.name)}_${_stamp()}.nsl.json', text, 'json', 'application/json');
}

Future<void> exportWorldMarkdown(BuildContext context, WidgetRef ref) async {
  final m = ScaffoldMessenger.of(context);
  final world = ref.read(activeWorldProvider);
  if (world == null) return;
  final text = await ref.read(backupServiceProvider).worldMarkdown(world);
  await _save(m, '${safeFileName(world.name)}.md', text, 'md', 'text/markdown');
}

Future<void> exportEntryMarkdown(BuildContext context, WidgetRef ref, Entry e) async {
  final m = ScaffoldMessenger.of(context);
  final text = await ref.read(backupServiceProvider).entryMarkdown(e);
  await _save(m, '${safeFileName(e.title)}.md', text, 'md', 'text/markdown');
}

/// Picks a backup file and imports it as a new world, then switches to it.
Future<void> importWorldJson(BuildContext context, WidgetRef ref) async {
  final m = ScaffoldMessenger.of(context);
  final String text;
  try {
    final file = await FilePicker.pickFile(
      dialogTitle: 'เลือกไฟล์สำรอง',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null) return;
    text = utf8.decode(await file.readAsBytes());
  } catch (e) {
    _toast(m, 'เปิดไฟล์ไม่สำเร็จ: $e');
    return;
  }
  try {
    final r = await ref.read(backupServiceProvider).importWorld(text);
    ref.read(worldChoiceProvider.notifier).set(r.world.id);
    ref.read(selectedIdProvider.notifier).set(null);
    ref.read(typeFilterProvider.notifier).set(null);
    ref.read(statusFilterProvider.notifier).set(null);
    ref.read(tagFilterProvider.notifier).set(null);
    ref.read(queryProvider.notifier).set('');
    final skipped = r.skipped == 0 ? '' : ' (ข้ามความสัมพันธ์ที่ไม่สมบูรณ์ ${r.skipped})';
    _toast(m, 'นำเข้า “${r.world.name}” แล้ว: ${r.entries} รายการ, ${r.relations} ความสัมพันธ์$skipped');
  } on BackupException catch (e) {
    _toast(m, e.message);
  } catch (e) {
    _toast(m, 'นำเข้าไม่สำเร็จ: $e');
  }
}

/// Writes the automatic backups right now and says where they are.
Future<void> backupNow(BuildContext context, WidgetRef ref) async {
  final m = ScaffoldMessenger.of(context);
  final auto = ref.read(autoBackupProvider);
  final files = await auto.run();
  final dir = await auto.folder().then<String>((d) => d.path, onError: (_) => '');
  _toast(m, files.isEmpty ? 'ไม่มีอะไรเปลี่ยนจากสำเนาล่าสุด\n$dir' : 'สำรองแล้ว ${files.length} โลก\n$dir');
}

/// Backup / export actions. Shown as a page on Android and a dialog on PC.
class SettingsPanel extends ConsumerWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final world = ref.watch(activeWorldProvider);
    final count = ref.watch(allEntriesProvider).length;

    Widget tile(IconData icon, String title, String sub, VoidCallback? onTap) => ListTile(
          leading: Icon(icon, color: C.accent),
          title: Text(title, style: T.ui(15, w: FontWeight.w500)),
          subtitle: Text(sub, style: T.ui(12, color: C.inkSoft)),
          onTap: onTap,
        );
    Widget heading(String s) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(s, style: T.ui(12, w: FontWeight.w600, color: C.inkFaint)),
        );

    final mode = ref.watch(themeModeProvider);
    return ListView(shrinkWrap: true, children: [
      heading('ธีม'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto, size: 18), label: Text('ตามระบบ', style: T.ui(13))),
            ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode_outlined, size: 18), label: Text('สว่าง', style: T.ui(13))),
            ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_outlined, size: 18), label: Text('กลางคืน', style: T.ui(13))),
          ],
          selected: {mode},
          onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
        ),
      ),
      heading('โลกปัจจุบัน'),
      ListTile(
        title: Text(world?.name ?? '…', style: T.serif(18, w: FontWeight.w700)),
        subtitle: Text('$count รายการ', style: T.ui(12, color: C.inkSoft)),
      ),
      heading('สำรองข้อมูล'),
      tile(Icons.upload_file, 'ส่งออกโลกนี้เป็น JSON', 'ไฟล์สำรองครบทุกรายการ ความสัมพันธ์ และลิงก์ — ย้ายระหว่าง PC กับ Android ได้',
          world == null ? null : () => exportWorldJson(context, ref)),
      tile(Icons.download, 'นำเข้าจากไฟล์ JSON', 'สร้างเป็นโลกใหม่ ไม่ทับข้อมูลเดิม', () => importWorldJson(context, ref)),
      tile(Icons.history, 'สำรองอัตโนมัติ', 'สำเนาล่าสุด 10 ครั้งต่อโลก เก็บในโฟลเดอร์ของแอปทุกครั้งที่เปิด — กดเพื่อสำรองตอนนี้และดูตำแหน่งไฟล์',
          () => backupNow(context, ref)),
      heading('ซิงก์ระหว่างเครื่อง (PC ↔ Android)'),
      tile(Icons.wifi_tethering, 'รับซิงก์ผ่าน Wi-Fi', 'เครื่องนี้รอให้อีกเครื่องเชื่อมต่อ — แสดงที่อยู่และรหัส', () => showHostDialog(context)),
      tile(Icons.sync, 'ซิงก์กับอีกเครื่อง', 'ใส่ที่อยู่และรหัสจากเครื่องที่กด “รับซิงก์” — รวมข้อมูลทุกโลกสองทาง', () => showConnectDialog(context)),
      tile(Icons.drive_file_move_outline, 'ส่งออกไฟล์ซิงก์', 'ทุกโลกในไฟล์เดียว ส่งต่อด้วย Drive, OneDrive หรือ USB ก็ได้', () => exportSyncFile(context, ref)),
      tile(Icons.merge_type, 'รวมจากไฟล์ซิงก์', 'เอาไฟล์ซิงก์จากอีกเครื่องมารวม (ไม่ทับ — รวมตามที่แก้ล่าสุด)', () => mergeSyncFile(context, ref)),
      heading('ส่งออกเพื่ออ่านหรือเผยแพร่'),
      tile(Icons.description_outlined, 'ส่งออกทั้งโลกเป็น Markdown', 'ไฟล์เดียว จัดกลุ่มตามประเภท',
          world == null ? null : () => exportWorldMarkdown(context, ref)),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Text('ส่งออกรายการเดียวเป็น Markdown ได้จากเมนูในหน้ารายการนั้น', style: T.ui(12, color: C.inkFaint)),
      ),
    ]);
  }
}

Future<void> showSettingsDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: C.bg,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 8, 0),
              child: Row(children: [
                Expanded(child: Text('ตั้งค่า', style: T.serif(20, w: FontWeight.w700))),
                const CloseButton(),
              ]),
            ),
            const Flexible(child: SettingsPanel()),
          ]),
        ),
      ),
    );

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: C.bg,
          surfaceTintColor: Colors.transparent,
          title: Text('ตั้งค่า', style: T.ui(16, w: FontWeight.w600)),
        ),
        body: const SettingsPanel(),
      );
}

