import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/calendar.dart';
import '../data/database.dart';
import '../data/repository.dart';
import '../providers.dart';
import '../theme.dart';

/// The world timeline: dated entries grouped by year, filterable by who/what is involved.
class TimelineView extends ConsumerWidget {
  const TimelineView({super.key, required this.onOpen});
  final void Function(Entry) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(timelineProvider).value ?? const <TimelineItem>[];
    final cal = ref.watch(calendarProvider);
    final all = ref.watch(allEntriesProvider);
    final byId = {for (final e in all) e.id: e};
    final filter = ref.watch(timelineFilterProvider);
    final world = ref.watch(activeWorldProvider);

    // Anyone who appears in at least one event can be used as a filter.
    final involved = <String>{for (final i in items) ...i.participantIds}.where(byId.containsKey).toList()
      ..sort((a, b) => thaiCompare(byId[a]!.title, byId[b]!.title));
    final shown = filter == null
        ? items
        : items.where((i) => i.entry.id == filter || i.participantIds.contains(filter)).toList();

    final children = <Widget>[];
    int? year;
    for (final item in shown) {
      if (item.start.year != year) {
        year = item.start.year;
        children.add(Padding(
          padding: EdgeInsets.only(top: children.isEmpty ? 0 : 18, bottom: 6),
          child: Text('${cal.yearLabel.isEmpty ? '' : '${cal.yearLabel} '}$year', style: T.serif(18, w: FontWeight.w700, color: C.accent)),
        ));
      }
      children.add(_TimelineRow(item: item, cal: cal, byId: byId, onOpen: onOpen));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('เส้นเวลา', style: T.serif(32, w: FontWeight.w700))),
        if (world != null)
          TextButton(onPressed: () => showCalendarDialog(context, ref), child: Text('ตั้งค่าปฏิทิน', style: T.ui(13, color: C.accent))),
      ]),
      const SizedBox(height: 4),
      Text('${items.length} เหตุการณ์ที่มีวันที่', style: T.ui(14, color: C.inkSoft)),
      if (involved.isNotEmpty) ...[
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('เฉพาะที่เกี่ยวกับ', style: T.ui(13, color: C.inkSoft)),
          PopupMenuButton<Object>(
            tooltip: '',
            onSelected: (v) => ref.read(timelineFilterProvider.notifier).set(v is String && v != _all ? v : null),
            itemBuilder: (_) => [
              const PopupMenuItem<Object>(value: _all, child: Text('ทั้งหมด')),
              for (final id in involved) PopupMenuItem<Object>(value: id, child: Text(byId[id]!.title)),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: filter == null ? Colors.transparent : C.accentTint,
                border: Border.all(color: filter == null ? C.lineInput : C.accentLine),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${filter == null ? 'ทั้งหมด' : byId[filter]?.title ?? 'ทั้งหมด'} ▾',
                  style: T.ui(13, color: filter == null ? C.ink : C.accent)),
            ),
          ),
        ]),
      ],
      const SizedBox(height: 22),
      if (items.isEmpty)
        Text('ยังไม่มีเหตุการณ์บนเส้นเวลา — เปิดรายการ (เช่นเหตุการณ์หรือตัวละคร) กดแก้ไข แล้วเปิด “แสดงบนเส้นเวลา” ในส่วนเส้นเวลา',
            style: T.ui(14, color: C.inkFaint, h: 1.6))
      else if (shown.isEmpty)
        Text('ไม่มีเหตุการณ์ที่เกี่ยวกับรายการนี้', style: T.ui(14, color: C.inkFaint))
      else
        ...children,
    ]);
  }
}

const _all = '\u0000all';

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.cal, required this.byId, required this.onOpen});
  final TimelineItem item;
  final CalendarConfig cal;
  final Map<String, Entry> byId;
  final void Function(Entry) onOpen;

  @override
  Widget build(BuildContext context) {
    final e = item.entry;
    final color = typeMeta[e.type]!.color;
    final people = [for (final id in item.participantIds) if (byId[id] != null) byId[id]!];
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 18,
          child: Stack(alignment: Alignment.topCenter, children: [
            Positioned.fill(child: Center(child: Container(width: 2, color: C.line))),
            Positioned(top: 6, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle))),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onOpen(e),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 2, 6, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cal.formatSpan(item.start, item.end), style: T.ui(12, color: C.inkFaint)),
                const SizedBox(height: 2),
                Text(e.title, style: T.ui(15, w: FontWeight.w600, color: color)),
                if (e.summary.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(e.summary, style: T.serif(13, color: C.inkSoft, h: 1.6)),
                ],
                if (people.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    for (final p in people)
                      GestureDetector(
                        onTap: () => onOpen(p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: C.bgChip, borderRadius: BorderRadius.circular(4)),
                          child: Text(p.title, style: T.ui(12, color: C.inkSoft)),
                        ),
                      ),
                  ]),
                ],
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Edit the world's calendar naming: the word before the year, and month names.
Future<void> showCalendarDialog(BuildContext context, WidgetRef ref) async {
  final world = ref.read(activeWorldProvider);
  if (world == null) return;
  final cfg = ref.read(calendarProvider);
  final label = TextEditingController(text: cfg.yearLabel);
  final months = TextEditingController(text: cfg.months.join('\n'));
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('ปฏิทินของโลก', style: T.serif(18, w: FontWeight.w700)),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: label, decoration: const InputDecoration(labelText: 'คำนำหน้าปี (เช่น ปีที่, ศ.ก.)')),
            const SizedBox(height: 14),
            TextField(
              controller: months,
              minLines: 4,
              maxLines: 12,
              decoration: const InputDecoration(labelText: 'ชื่อเดือน — บรรทัดละเดือน เรียงตามลำดับ', alignLabelWithHint: true),
            ),
            const SizedBox(height: 8),
            Text('เว้นว่างไว้ได้ จะแสดงเป็น “เดือน 1, เดือน 2…” วันที่เก่าไม่หาย — เปลี่ยนแค่ชื่อที่แสดง',
                style: T.ui(12, color: C.inkFaint, h: 1.5)),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('บันทึก')),
      ],
    ),
  );
  if (ok != true) return;
  await ref.read(repositoryProvider).setCalendar(
        world.id,
        CalendarConfig(
          yearLabel: label.text.trim(),
          months: months.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        ),
      );
}

/// Android page wrapper.
class MobileTimelinePage extends ConsumerWidget {
  const MobileTimelinePage({super.key, required this.onOpen});
  final void Function(Entry) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(backgroundColor: C.bg, surfaceTintColor: Colors.transparent),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          child: TimelineView(onOpen: onOpen),
        ),
      );
}
