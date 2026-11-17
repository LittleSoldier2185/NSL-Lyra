import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../providers.dart';
import '../theme.dart';
import 'entry_image.dart';
import 'actions.dart';

class TypeChips extends ConsumerWidget {
  const TypeChips({super.key, this.mobile = false});
  final bool mobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allEntriesProvider);
    final current = ref.watch(typeFilterProvider);

    Widget chip(EntryType? t, String label, int count) {
      final on = current == t;
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => ref.read(typeFilterProvider.notifier).set(t),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: mobile ? 12 : 9, vertical: mobile ? 7 : 4),
          decoration: BoxDecoration(
            color: on ? C.ink : Colors.transparent,
            border: Border.all(color: on ? C.ink : C.lineInput),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: T.ui(mobile ? 13 : 12, color: on ? C.bg : C.chipText)),
            if (!mobile) ...[
              const SizedBox(width: 5),
              Text('$count', style: T.ui(12, color: (on ? C.bg : C.chipText).withValues(alpha: .6))),
            ],
          ]),
        ),
      );
    }

    final chips = [
      chip(null, 'ทั้งหมด', all.length),
      for (final t in EntryType.values) chip(t, typeMeta[t]!.label, all.where((e) => e.type == t).length),
    ];

    if (mobile) {
      return SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: chips.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) => chips[i],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Wrap(spacing: 6, runSpacing: 6, children: chips),
    );
  }
}

const _any = '\u0000any';

/// Status / tag filters and sort order.
class FilterBar extends ConsumerWidget {
  const FilterBar({super.key, this.mobile = false});
  final bool mobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(statusFilterProvider);
    final tag = ref.watch(tagFilterProvider);
    final sort = ref.watch(sortProvider);
    final tags = ref.watch(allTagsProvider);
    final count = ref.watch(filteredEntriesProvider).length;
    final active = status != null || tag != null || ref.watch(typeFilterProvider) != null || ref.watch(queryProvider).isNotEmpty;

    Widget menu<V>({required String label, required bool on, required List<PopupMenuEntry<V>> items, required void Function(V) onSelected}) {
      return PopupMenuButton<V>(
        tooltip: '',
        onSelected: onSelected,
        itemBuilder: (_) => items,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: on ? C.accentTint : Colors.transparent,
            border: Border.all(color: on ? C.accentLine : C.lineInput),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('$label ▾', style: T.ui(12, color: on ? C.accent : C.inkSoft)),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(mobile ? 16 : 14, 0, mobile ? 16 : 14, 8),
      child: Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        // A null menu value means "dismissed", so "all" uses a sentinel instead.
        menu<Object>(
          label: status == null ? 'สถานะ' : statusMeta[status]!.label,
          on: status != null,
          items: [
            const PopupMenuItem<Object>(value: _any, child: Text('ทุกสถานะ')),
            for (final s in EntryStatus.values) PopupMenuItem<Object>(value: s, child: Text(statusMeta[s]!.label)),
          ],
          onSelected: (v) => ref.read(statusFilterProvider.notifier).set(v is EntryStatus ? v : null),
        ),
        if (tags.isNotEmpty)
          menu<Object>(
            label: tag == null ? 'แท็ก' : '#$tag',
            on: tag != null,
            items: [
              const PopupMenuItem<Object>(value: _any, child: Text('ทุกแท็ก')),
              for (final t in tags) PopupMenuItem<Object>(value: t, child: Text('#$t')),
            ],
            onSelected: (v) => ref.read(tagFilterProvider.notifier).set(v is String && v != _any ? v : null),
          ),
        menu<EntrySort>(
          label: sort == EntrySort.updated ? 'แก้ไขล่าสุด' : 'ชื่อ ก–ฮ',
          on: false,
          items: const [
            PopupMenuItem(value: EntrySort.updated, child: Text('แก้ไขล่าสุด')),
            PopupMenuItem(value: EntrySort.name, child: Text('ชื่อ ก–ฮ')),
          ],
          onSelected: ref.read(sortProvider.notifier).set,
        ),
        Text('$count รายการ', style: T.ui(11, color: C.inkFaint)),
        if (active)
          InkWell(
            onTap: () {
              ref.read(statusFilterProvider.notifier).set(null);
              ref.read(tagFilterProvider.notifier).set(null);
              ref.read(typeFilterProvider.notifier).set(null);
              ref.read(queryProvider.notifier).set('');
            },
            child: Text('ล้างตัวกรอง', style: T.ui(11, color: C.accent)),
          ),
      ]),
    );
  }
}

class TypeGlyph extends StatelessWidget {
  const TypeGlyph(this.type, {super.key, this.size = 30, this.imagePath});
  final EntryType type;
  final double size;

  /// If set, the entry's picture is shown instead of the letter.
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final m = typeMeta[type]!;
    final radius = BorderRadius.circular(size > 32 ? 8 : 7);
    if (imagePath != null) {
      return ClipRRect(
        borderRadius: radius,
        child: EntryImage(imagePath!, width: size, height: size, cacheWidth: (size * 3).round()),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: m.color, borderRadius: BorderRadius.circular(size > 32 ? 8 : 7)),
      child: Text(m.glyph, style: T.serif(size * .47, w: FontWeight.w600, color: C.bg)),
    );
  }
}

class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.entry, required this.onTap, this.selected = false, this.mobile = false});
  final Entry entry;
  final VoidCallback onTap;
  final bool selected;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final sub = '${typeMeta[entry.type]!.label} · ${entry.summary}';
    final content = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TypeGlyph(entry.type, size: mobile ? 36 : 30, imagePath: entry.imagePath),
      SizedBox(width: mobile ? 12 : 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(entry.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(mobile ? 15 : 14, w: FontWeight.w600)),
            ),
            if (!mobile) ...[
              const SizedBox(width: 8),
              Text(relativeTime(entry.updated), style: T.ui(11, color: C.inkFaint)),
            ],
          ]),
          const SizedBox(height: 2),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(12, color: C.inkSoft)),
        ]),
      ),
    ]);

    if (mobile) {
      return InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.lineSoft))),
          child: content,
        ),
      );
    }
    return Material(
      color: selected ? C.selected : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        hoverColor: C.hover,
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(10), child: content),
      ),
    );
  }
}

/// Scrollable list of the filtered entries, or an empty-state message.
class EntryListView extends ConsumerWidget {
  const EntryListView({super.key, required this.onOpen, this.mobile = false});
  final void Function(Entry) onOpen;
  final bool mobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(filteredEntriesProvider);
    final q = ref.watch(queryProvider);
    final selected = ref.watch(selectedIdProvider);
    final total = ref.watch(allEntriesProvider).length;

    if (list.isEmpty) {
      final text = total == 0 ? 'ยังไม่มีรายการ — กด + เพื่อสร้างรายการแรก' : 'ไม่พบรายการที่ตรงกับ “$q”';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Text(text, textAlign: TextAlign.center, style: T.ui(13, color: C.inkFaint)),
      );
    }
    return ListView.builder(
      padding: mobile ? EdgeInsets.zero : const EdgeInsets.fromLTRB(8, 0, 8, 12),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final e = list[i];
        return Padding(
          padding: EdgeInsets.only(bottom: mobile ? 0 : 2),
          child: EntryTile(entry: e, mobile: mobile, selected: e.id == selected, onTap: () => onOpen(e)),
        );
      },
    );
  }
}
