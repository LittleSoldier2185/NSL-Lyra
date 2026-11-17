import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/wiki_links.dart';
import '../data/database.dart';
import '../data/repository.dart';
import '../providers.dart';
import '../theme.dart';
import 'actions.dart';
import 'entry_image.dart';

/// One paragraph of body text with tappable [[links]].
class LinkedParagraph extends ConsumerStatefulWidget {
  const LinkedParagraph({super.key, required this.text, required this.style, required this.onOpen});
  final String text;
  final TextStyle style;
  final void Function(Entry) onOpen;

  @override
  ConsumerState<LinkedParagraph> createState() => _LinkedParagraphState();
}

class _LinkedParagraphState extends ConsumerState<LinkedParagraph> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final all = ref.watch(allEntriesProvider);
    final repo = ref.read(repositoryProvider);
    final spans = <InlineSpan>[];
    for (final seg in parseBody(widget.text)) {
      if (!seg.isLink) {
        spans.add(TextSpan(text: seg.text));
        continue;
      }
      final target = repo.resolveLink(all, seg.text);
      final rec = TapGestureRecognizer()
        ..onTap = () async {
          if (target != null) {
            widget.onOpen(target);
          } else {
            final created = await createFromBrokenLink(context, ref, seg.text);
            if (created != null && context.mounted) widget.onOpen(created);
          }
        };
      _recognizers.add(rec);
      spans.add(TextSpan(
        text: seg.text,
        recognizer: rec,
        mouseCursor: SystemMouseCursors.click,
        style: target != null
            ? TextStyle(color: C.accent, decoration: TextDecoration.underline, decorationColor: C.accentLine)
            : TextStyle(color: C.inkFaint, decoration: TextDecoration.underline, decorationStyle: TextDecorationStyle.dashed, decorationColor: Color(0xFFB5AB9C)),
      ));
    }
    return Text.rich(TextSpan(children: spans, style: widget.style));
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final EntryStatus status;

  @override
  Widget build(BuildContext context) {
    final m = statusMeta[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: m.bg, borderRadius: BorderRadius.circular(4)),
      child: Text(m.label, style: T.ui(12, w: FontWeight.w500, color: m.fg)),
    );
  }
}

/// Main reading view for an entry. [mobile] switches to the compact layout.
class EntryContent extends ConsumerWidget {
  const EntryContent({super.key, required this.entry, required this.onOpen, this.mobile = false, this.tabBar, this.showBody = true});
  final Entry entry;
  final void Function(Entry) onOpen;
  final bool mobile;

  /// Android: tab switcher shown under the summary; with [showBody] false
  /// only the header and tab bar render (the caller shows the other tab).
  final Widget? tabBar;
  final bool showBody;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = typeMeta[entry.type]!;
    final aliases = decodeList(entry.aliases);
    final tags = decodeList(entry.tags);
    final fields = decodeMap(entry.fields).entries.where((f) => f.value.trim().isNotEmpty).toList();
    final paras = entry.body.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).toList();
    final timeline = ref.watch(timelineProvider).value ?? const <TimelineItem>[];
    final cal = ref.watch(calendarProvider);
    final byId = {for (final e in ref.watch(allEntriesProvider)) e.id: e};
    final own = timeline.where((t) => t.entry.id == entry.id).firstOrNull;
    final involvedIn = timeline.where((t) => t.participantIds.contains(entry.id)).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 10, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(meta.label, style: T.ui(12, w: FontWeight.w600, color: meta.color)),
        StatusBadge(entry.status),
        if (!mobile) Text('แก้ไข ${relativeTime(entry.updated)}', style: T.ui(12, color: C.inkFaint)),
      ]),
      const SizedBox(height: 10),
      Text(entry.title, style: T.serif(mobile ? 28 : 38, w: FontWeight.w700, h: mobile ? 1.3 : 1.25)),
      if (aliases.isNotEmpty && !mobile) ...[
        const SizedBox(height: 10),
        Text('หรือ ${aliases.join(', ')}', style: T.ui(14, color: C.inkSoft)),
      ],
      if (entry.imagePath != null) ...[
        const SizedBox(height: 14),
        Semantics(
          label: 'รูปของ ${entry.title} — แตะเพื่อขยาย',
          button: true,
          child: GestureDetector(
            onTap: () => showImageViewer(context, entry.imagePath!, entry.title),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                height: mobile ? 220 : 340,
                decoration: BoxDecoration(color: C.bgPanel, border: Border.all(color: C.border), borderRadius: BorderRadius.circular(10)),
                child: EntryImage(entry.imagePath!, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ],
      if (entry.summary.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(entry.summary, style: T.serif(mobile ? 15 : 17, color: C.summary, h: 1.7)),
      ],
      if (tags.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final t in tags)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: C.bgChip, borderRadius: BorderRadius.circular(4)),
              child: Text('#$t', style: T.ui(12, color: C.inkSoft)),
            ),
        ]),
      ],
      if (own != null) ...[
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('◷  ', style: TextStyle(color: C.accent)),
          Expanded(child: Text(cal.formatSpan(own.start, own.end), style: T.ui(14, w: FontWeight.w500, color: C.accent))),
        ]),
        if (own.participantIds.any(byId.containsKey)) ...[
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text('ผู้เกี่ยวข้อง', style: T.ui(12, color: C.inkFaint)),
            for (final id in own.participantIds)
              if (byId[id] != null)
                GestureDetector(
                  onTap: () => onOpen(byId[id]!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: C.accentTint, borderRadius: BorderRadius.circular(4)),
                    child: Text(byId[id]!.title, style: T.ui(12, color: C.accent)),
                  ),
                ),
          ]),
        ],
      ],
      if (tabBar != null) ...[
        const SizedBox(height: 14),
        tabBar!,
        const SizedBox(height: 14),
      ],
      if (showBody && fields.isNotEmpty) ...[
        SizedBox(height: mobile ? 0 : 22),
        _FieldsGrid(fields: fields, columns: mobile ? 2 : 3, framed: !mobile),
      ],
      if (showBody) SizedBox(height: mobile ? 14 : 22),
      if (!showBody)
        const SizedBox.shrink()
      else if (paras.isEmpty)
        Text('ยังไม่มีรายละเอียด', style: T.ui(14, color: C.inkFaint))
      else
        for (final p in paras)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: LinkedParagraph(text: p.trim(), onOpen: onOpen, style: T.serif(mobile ? 15 : 16, color: C.body, h: mobile ? 1.8 : 1.85)),
          ),
      if (showBody) ...[
        const SizedBox(height: 8),
        RelationsSection(entry: entry, onOpen: onOpen),
        if (involvedIn.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('เหตุการณ์ที่เกี่ยวข้อง', style: T.ui(13, w: FontWeight.w600, color: C.inkSoft)),
          const SizedBox(height: 6),
          for (final t in involvedIn)
            InkWell(
              onTap: () => onOpen(t.entry),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: mobile ? 120 : 170, child: Text(cal.formatSpan(t.start, t.end), style: T.ui(12, color: C.inkFaint))),
                  Expanded(child: Text(t.entry.title, style: T.ui(14, w: FontWeight.w600, color: typeMeta[t.entry.type]!.color))),
                ]),
              ),
            ),
        ],
      ],
    ]);
  }
}

class _FieldsGrid extends StatelessWidget {
  const _FieldsGrid({required this.fields, required this.columns, required this.framed});
  final List<MapEntry<String, String>> fields;
  final int columns;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final rows = <List<MapEntry<String, String>>>[];
    for (var i = 0; i < fields.length; i += columns) {
      rows.add(fields.sublist(i, (i + columns).clamp(0, fields.length)));
    }
    final grid = Column(children: [
      for (final r in rows)
        Padding(
          padding: EdgeInsets.symmetric(vertical: framed ? 12 : 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < columns; i++)
              Expanded(
                child: i < r.length
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r[i].key, style: T.ui(11, color: C.inkFaint)),
                        const SizedBox(height: 2),
                        Text(r[i].value, style: T.ui(14, w: FontWeight.w500)),
                      ])
                    : const SizedBox(),
              ),
          ]),
        ),
    ]);
    if (!framed) return grid;
    return Container(
      decoration: BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: C.line))),
      child: grid,
    );
  }
}

class RelationsSection extends ConsumerWidget {
  const RelationsSection({super.key, required this.entry, required this.onOpen});
  final Entry entry;
  final void Function(Entry) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rels = ref.watch(relationsOfProvider(entry.id)).value ?? const [];
    final all = ref.watch(allEntriesProvider);
    final byId = {for (final e in all) e.id: e};

    final rows = <Widget>[];
    for (final r in rels) {
      final outgoing = r.fromEntry == entry.id;
      final other = byId[outgoing ? r.toEntry : r.fromEntry];
      if (other == null) continue;
      final label = outgoing ? r.type : (r.inverseType.isEmpty ? r.type : r.inverseType);
      rows.add(InkWell(
        onTap: () => onOpen(other),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.lineSoft))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            SizedBox(width: 110, child: Text(label, style: T.ui(12, color: C.inkFaint))),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(other.title, style: T.ui(14, w: FontWeight.w600, color: typeMeta[other.type]!.color)),
                Text(r.note.isEmpty ? typeMeta[other.type]!.label : r.note, style: T.ui(12, color: C.inkSoft)),
              ]),
            ),
            InkWell(
              onTap: () => ref.read(repositoryProvider).deleteRelation(r.id),
              child: Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 20, color: C.inkSoft)),
            ),
          ]),
        ),
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ความสัมพันธ์', style: T.ui(13, w: FontWeight.w600, color: C.inkSoft)),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(border: Border.all(color: C.line), borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          ...rows,
          InkWell(
            onTap: () => showAddRelationDialog(context, ref, entry),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text('+ เพิ่มความสัมพันธ์', style: T.ui(13, color: C.accent)),
            ),
          ),
        ]),
      ),
    ]);
  }
}

const _relationPresets = <(String, String)>[
  ('พี่น้อง', 'พี่น้อง'),
  ('ศัตรู', 'ศัตรู'),
  ('สังกัด', 'สมาชิก'),
  ('อาศัยอยู่ที่', 'ผู้อยู่อาศัย'),
  ('ครอบครอง', 'เจ้าของ'),
  ('ตั้งอยู่ที่', 'ที่ตั้งของ'),
];

Future<void> showAddRelationDialog(BuildContext context, WidgetRef ref, Entry from) async {
  final others = ref.read(allEntriesProvider).where((e) => e.id != from.id).toList();
  if (others.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ต้องมีรายการอื่นก่อนจึงจะเชื่อมได้')));
    return;
  }
  Entry? target;
  final type = TextEditingController();
  final inverse = TextEditingController();
  final note = TextEditingController();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      return AlertDialog(
        title: Text('เพิ่มความสัมพันธ์', style: T.serif(18, w: FontWeight.w700)),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              DropdownButtonFormField<Entry>(
                initialValue: target,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'เชื่อมกับ'),
                items: [for (final e in others) DropdownMenuItem(value: e, child: Text('${e.title} · ${typeMeta[e.type]!.label}', overflow: TextOverflow.ellipsis))],
                onChanged: (v) => setState(() => target = v),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final p in _relationPresets)
                  ActionChip(
                    label: Text(p.$1),
                    onPressed: () => setState(() {
                      type.text = p.$1;
                      inverse.text = p.$2;
                    }),
                  ),
              ]),
              TextField(controller: type, decoration: InputDecoration(labelText: 'ชนิด (จาก ${from.title})')),
              TextField(controller: inverse, decoration: const InputDecoration(labelText: 'ชนิดจากอีกฝั่ง')),
              TextField(controller: note, decoration: const InputDecoration(labelText: 'โน้ต')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('เพิ่ม')),
        ],
      );
    }),
  );
  if (ok == true && target != null && type.text.trim().isNotEmpty) {
    await ref.read(repositoryProvider).addRelation(
          from: from.id,
          to: target!.id,
          type: type.text.trim(),
          inverseType: inverse.text.trim(),
          note: note.text.trim(),
        );
  }
}

/// Entries that link to [entry] (right column on PC, second tab on Android).
class BacklinksList extends ConsumerWidget {
  const BacklinksList({super.key, required this.entry, required this.onOpen, this.shrink = false});
  final Entry entry;
  final void Function(Entry) onOpen;
  final bool shrink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allEntriesProvider);
    final backlinks = ref.read(repositoryProvider).backlinksFor(all, entry);

    if (backlinks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: C.border), borderRadius: BorderRadius.circular(8)),
        child: Text('ยังไม่มีรายการใดอ้างถึง — อาจเป็นรายการกำพร้า', style: T.ui(13, color: C.inkFaint, h: 1.6)),
      );
    }
    return Column(children: [
      for (final b in backlinks)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onOpen(b.entry),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: C.bg, border: Border.all(color: C.line), borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: typeMeta[b.entry.type]!.color, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(b.entry.title, style: T.ui(13, w: FontWeight.w600))),
                ]),
                const SizedBox(height: 6),
                Text(b.snippet, style: T.serif(13, color: C.snippet, h: 1.6)),
              ]),
            ),
          ),
        ),
    ]);
  }
}

/// Right-hand column on PC.
class BacklinksPanel extends ConsumerWidget {
  const BacklinksPanel({super.key, required this.entry, required this.onOpen});
  final Entry entry;
  final void Function(Entry) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(repositoryProvider).backlinksFor(ref.watch(allEntriesProvider), entry).length;
    return Container(
      width: 300,
      decoration: BoxDecoration(color: C.bgPanel, border: Border(left: BorderSide(color: C.line))),
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 20), children: [
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Expanded(child: Text('Backlinks', style: T.serif(15, w: FontWeight.w600))),
          Text('$n รายการอ้างถึง', style: T.ui(12, color: C.inkFaint)),
        ]),
        const SizedBox(height: 14),
        BacklinksList(entry: entry, onOpen: onOpen),
      ]),
    );
  }
}

/// Small helper used by both shells for the empty selection state.
class NoSelection extends StatelessWidget {
  const NoSelection({super.key});
  @override
  Widget build(BuildContext context) =>
      Center(child: Text('เลือกรายการทางซ้าย หรือกด Ctrl N เพื่อสร้างใหม่', style: T.ui(14, color: C.inkFaint)));
}
