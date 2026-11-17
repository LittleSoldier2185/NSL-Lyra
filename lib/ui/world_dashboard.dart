import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/stats.dart';
import '../data/database.dart';
import '../providers.dart';
import '../theme.dart';
import 'actions.dart';
import 'entry_list.dart';

final statsProvider = Provider<WorldStats>((ref) => computeStats(ref.watch(allEntriesProvider)));

/// Overview of the active world plus world management (switch / new / rename / delete).
class WorldDashboard extends ConsumerWidget {
  const WorldDashboard({super.key, required this.onOpen, this.onNewEntry, this.onOpenTimeline, this.onOpenGraph});
  final void Function(Entry) onOpen;
  final VoidCallback? onNewEntry;
  final VoidCallback? onOpenTimeline;
  final VoidCallback? onOpenGraph;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final world = ref.watch(activeWorldProvider);
    final stats = ref.watch(statsProvider);
    final worldCount = ref.watch(worldsProvider).value?.length ?? 0;
    if (world == null) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('โลก', style: T.ui(12, color: C.inkFaint)),
      Text(world.name, style: T.serif(32, w: FontWeight.w700, h: 1.25)),
      const SizedBox(height: 4),
      Text('${stats.total} รายการ · $worldCount โลกในเครื่อง', style: T.ui(14, color: C.inkSoft)),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: [
        if (onOpenTimeline != null) _pill('เส้นเวลา', onOpenTimeline!, icon: Icons.timeline),
        if (onOpenGraph != null) _pill('กราฟ', onOpenGraph!, icon: Icons.hub_outlined),
        _pill('สลับโลก', () => showWorldDialog(context, ref)),
        _pill('+ โลกใหม่', () => createWorldFlow(context, ref)),
        _pill('เปลี่ยนชื่อ', () => renameWorldFlow(context, ref, world)),
        _pill('ลบโลกนี้', () => deleteWorldFlow(context, ref, world), danger: true),
      ]),
      const SizedBox(height: 28),
      if (stats.total == 0) ...[
        Text('โลกนี้ยังว่างอยู่', style: T.serif(18, w: FontWeight.w600)),
        const SizedBox(height: 10),
        if (onNewEntry != null) FilledButton(onPressed: onNewEntry, child: const Text('+ สร้างรายการแรก')),
      ] else ...[
        _section('ตามประเภท'),
        _TypeBars(stats: stats),
        const SizedBox(height: 22),
        _section('ตามสถานะ'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in EntryStatus.values)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: statusMeta[s]!.bg, borderRadius: BorderRadius.circular(8)),
              child: Text('${statusMeta[s]!.label}  ${stats.byStatus[s]}', style: T.ui(14, w: FontWeight.w500, color: statusMeta[s]!.fg)),
            ),
        ]),
        const SizedBox(height: 22),
        _section('แก้ไขล่าสุด'),
        for (final e in stats.recent) _row(e, relativeTime(e.updated), () => onOpen(e)),
        if (stats.brokenLinks.isNotEmpty) ...[
          const SizedBox(height: 22),
          _section('ลิงก์ที่ยังไม่มีรายการ (${stats.brokenLinks.length})'),
          for (final b in (stats.brokenLinks.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(8))
            InkWell(
              onTap: () async {
                final e = await createFromBrokenLink(context, ref, b.key);
                if (e != null) onOpen(e);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Expanded(child: Text('[[${b.key}]]', style: T.mono(13, color: C.inkSoft))),
                  Text('ใช้ใน ${b.value} รายการ', style: T.ui(12, color: C.inkFaint)),
                  const SizedBox(width: 10),
                  Text('สร้าง', style: T.ui(12, color: C.accent)),
                ]),
              ),
            ),
        ],
        if (stats.orphans.isNotEmpty) ...[
          const SizedBox(height: 22),
          _section('รายการกำพร้า — ยังไม่มีใครอ้างถึง (${stats.orphans.length})'),
          for (final e in stats.orphans.take(8)) _row(e, typeMeta[e.type]!.label, () => onOpen(e)),
        ],
      ],
    ]);
  }

  Widget _section(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s, style: T.ui(13, w: FontWeight.w600, color: C.inkSoft)),
      );

  Widget _pill(String label, VoidCallback onTap, {bool danger = false, IconData? icon}) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: danger ? C.accentLine : C.lineInput),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 18, color: C.inkSoft), const SizedBox(width: 6)],
          Text(label, style: T.ui(13, color: danger ? C.accent : C.ink)),
        ]),
      );

  Widget _row(Entry e, String trailing, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            TypeGlyph(e.type, size: 26),
            const SizedBox(width: 10),
            Expanded(child: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(14, w: FontWeight.w500))),
            Text(trailing, style: T.ui(12, color: C.inkFaint)),
          ]),
        ),
      );
}

class _TypeBars extends StatelessWidget {
  const _TypeBars({required this.stats});
  final WorldStats stats;

  @override
  Widget build(BuildContext context) {
    final max = stats.byType.values.fold<int>(1, (a, b) => b > a ? b : a);
    return Column(children: [
      for (final t in EntryType.values)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(width: 84, child: Text(typeMeta[t]!.label, style: T.ui(13, color: C.inkSoft))),
            Expanded(
              child: LayoutBuilder(builder: (_, c) {
                final n = stats.byType[t]!;
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: n == 0 ? 0 : (c.maxWidth * n / max).clamp(6, c.maxWidth),
                    height: 12,
                    decoration: BoxDecoration(color: typeMeta[t]!.color, borderRadius: BorderRadius.circular(3)),
                  ),
                );
              }),
            ),
            SizedBox(width: 28, child: Text('${stats.byType[t]}', textAlign: TextAlign.right, style: T.ui(13, w: FontWeight.w500))),
          ]),
        ),
    ]);
  }
}
