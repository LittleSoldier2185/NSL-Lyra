import '../data/database.dart';
import '../data/repository.dart';
import 'wiki_links.dart';

class WorldStats {
  const WorldStats({
    required this.total,
    required this.byType,
    required this.byStatus,
    required this.recent,
    required this.orphans,
    required this.brokenLinks,
  });

  final int total;
  final Map<EntryType, int> byType;
  final Map<EntryStatus, int> byStatus;

  /// Most recently edited first.
  final List<Entry> recent;

  /// Entries that no other entry links to.
  final List<Entry> orphans;

  /// `[[names]]` that match no entry, with how many entries use each.
  final Map<String, int> brokenLinks;
}

/// Link targets resolve by title first, then alias (same as the reader).
WorldStats computeStats(List<Entry> entries, {int recentCount = 6}) {
  final byName = <String, Entry>{};
  for (final e in entries) {
    for (final a in decodeList(e.aliases)) {
      byName.putIfAbsent(a, () => e);
    }
  }
  for (final e in entries) {
    byName[e.title] = e; // titles win over aliases
  }

  final linkedTo = <String>{};
  final broken = <String, int>{};
  for (final e in entries) {
    for (final name in extractLinks(e.body)) {
      final target = byName[name];
      if (target == null) {
        broken[name] = (broken[name] ?? 0) + 1;
      } else if (target.id != e.id) {
        linkedTo.add(target.id);
      }
    }
  }

  final sorted = [...entries]..sort((a, b) => b.updated.compareTo(a.updated));
  return WorldStats(
    total: entries.length,
    byType: {for (final t in EntryType.values) t: entries.where((e) => e.type == t).length},
    byStatus: {for (final s in EntryStatus.values) s: entries.where((e) => e.status == s).length},
    recent: sorted.take(recentCount).toList(),
    orphans: entries.where((e) => !linkedTo.contains(e.id)).toList(),
    brokenLinks: broken,
  );
}
