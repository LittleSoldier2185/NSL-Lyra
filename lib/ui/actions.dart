import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../providers.dart';
import '../theme.dart';

/// Default type-specific field names offered for a new entry.
const defaultFieldKeys = <EntryType, List<String>>{
  EntryType.character: ['อายุ', 'อาชีพ', 'เป้าหมาย'],
  EntryType.place: ['ภูมิอากาศ', 'ประชากร', 'ปกครองโดย'],
  EntryType.org: ['ก่อตั้ง', 'สมาชิก', 'ฐาน'],
  EntryType.event: ['วันที่', 'ระยะเวลา', 'ผลกระทบ'],
  EntryType.item: ['วัสดุ', 'เจ้าของ', 'ที่มา'],
  EntryType.rule: ['ความถี่', 'ระยะเวลา', 'ผลกระทบ'],
  EntryType.species: ['อายุขัย', 'ถิ่นที่อยู่', 'ภาษา'],
};

String relativeTime(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'เมื่อสักครู่';
  if (d.inMinutes < 60) return '${d.inMinutes} นาที';
  if (d.inHours < 24) return '${d.inHours} ชม.';
  if (d.inDays == 1) return 'เมื่อวาน';
  if (d.inDays < 7) return '${d.inDays} วัน';
  if (d.inDays < 30) return '${d.inDays ~/ 7} สัปดาห์';
  return '${d.inDays ~/ 30} เดือน';
}

/// Creates a blank entry in the active world and selects it.
/// Returns null when no world is active yet.
Future<Entry?> createNewEntry(WidgetRef ref, {EntryType? type, String title = 'รายการใหม่', bool select = true}) async {
  final world = ref.read(activeWorldProvider);
  if (world == null) return null;
  final t = type ?? ref.read(typeFilterProvider) ?? EntryType.character;
  final repo = ref.read(repositoryProvider);
  final e = await repo.createEntry(
        worldId: world.id,
        type: t,
        title: await repo.uniqueTitle(world.id, title),
        fields: {for (final k in defaultFieldKeys[t]!) k: ''},
      );
  if (select) ref.read(selectedIdProvider.notifier).set(e.id);
  return e;
}

/// Asks which type a missing `[[name]]` should become, then creates it.
Future<Entry?> createFromBrokenLink(BuildContext context, WidgetRef ref, String name) async {
  final type = await showDialog<EntryType>(
    context: context,
    builder: (_) => SimpleDialog(
      title: Text('สร้าง “$name”', style: T.serif(18, w: FontWeight.w700)),
      children: [
        for (final t in EntryType.values)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, t),
            child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: typeMeta[t]!.color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Text(typeMeta[t]!.label, style: T.ui(15)),
            ]),
          ),
      ],
    ),
  );
  if (type == null) return null;
  return createNewEntry(ref, type: type, title: name);
}

/// Selects [e] and leaves edit mode.
void openEntry(WidgetRef ref, Entry e) {
  ref.read(editingProvider.notifier).set(false);
  ref.read(selectedIdProvider.notifier).set(e.id);
}

Future<void> showWorldDialog(BuildContext context, WidgetRef ref) async {
  final worlds = ref.read(worldsProvider).value ?? const [];
  final active = ref.read(activeWorldProvider);
  final picked = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text('สลับโลก', style: T.serif(18, w: FontWeight.w700)),
      children: [
        for (final w in worlds)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, w.id),
            child: Row(children: [
              Icon(w.id == active?.id ? Icons.check : null, size: 18, color: C.accent),
              const SizedBox(width: 8),
              Text(w.name, style: T.ui(15, w: w.id == active?.id ? FontWeight.w600 : FontWeight.w400)),
            ]),
          ),
        const Divider(),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, '\u0000new'),
          child: Text('+ โลกใหม่', style: T.ui(15, color: C.accent)),
        ),
      ],
    ),
  );
  if (picked == null) return;
  if (picked == '\u0000new') {
    if (!context.mounted) return;
    await createWorldFlow(context, ref);
  } else {
    switchWorld(ref, picked);
  }
}

/// Makes [id] the active world and clears selection and filters.
void switchWorld(WidgetRef ref, String? id) {
  ref.read(worldChoiceProvider.notifier).set(id);
  ref.read(selectedIdProvider.notifier).set(null);
  ref.read(editingProvider.notifier).set(false);
  ref.read(mainViewProvider.notifier).set(MainView.overview);
  ref.read(timelineFilterProvider.notifier).set(null);
  ref.read(typeFilterProvider.notifier).set(null);
  ref.read(statusFilterProvider.notifier).set(null);
  ref.read(tagFilterProvider.notifier).set(null);
  ref.read(queryProvider.notifier).set('');
}

Future<void> createWorldFlow(BuildContext context, WidgetRef ref) async {
  final name = await askText(context, 'ชื่อโลกใหม่');
  if (name == null || name.trim().isEmpty) return;
  final w = await ref.read(repositoryProvider).createWorld(name.trim());
  switchWorld(ref, w.id);
}

Future<void> renameWorldFlow(BuildContext context, WidgetRef ref, World world) async {
  final name = await askText(context, 'เปลี่ยนชื่อโลก', initial: world.name);
  if (name == null || name.trim().isEmpty || name.trim() == world.name) return;
  await ref.read(repositoryProvider).renameWorld(world.id, name.trim());
}

/// Deletes [world] after confirmation. The last remaining world cannot be deleted.
Future<void> deleteWorldFlow(BuildContext context, WidgetRef ref, World world) async {
  final m = ScaffoldMessenger.of(context);
  final worlds = ref.read(worldsProvider).value ?? const [];
  if (worlds.length <= 1) {
    m.showSnackBar(const SnackBar(content: Text('ลบโลกสุดท้ายไม่ได้ — สร้างโลกใหม่ก่อน')));
    return;
  }
  final count = ref.read(allEntriesProvider).length;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('ลบโลก “${world.name}” ?', style: T.serif(18, w: FontWeight.w700)),
      content: Text('จะลบทั้ง $count รายการและความสัมพันธ์ทั้งหมดในโลกนี้ กู้คืนไม่ได้ — ส่งออกเป็น JSON ไว้ก่อนได้ที่ตั้งค่า'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: C.accent),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('ลบโลก'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  switchWorld(ref, null);
  await ref.read(repositoryProvider).deleteWorld(world.id);
}

Future<String?> askText(BuildContext context, String title, {String initial = ''}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: T.serif(18, w: FontWeight.w700)),
      content: TextField(controller: c, autofocus: true, onSubmitted: (v) => Navigator.pop(ctx, v)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('ตกลง')),
      ],
    ),
  );
}

Future<bool> confirmDelete(BuildContext context, Entry e) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('ลบ “${e.title}” ?', style: T.serif(18, w: FontWeight.w700)),
      content: const Text('ลบแล้วกู้คืนไม่ได้ ความสัมพันธ์ของรายการนี้จะถูกลบด้วย'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ลบ')),
      ],
    ),
  );
  return ok ?? false;
}
