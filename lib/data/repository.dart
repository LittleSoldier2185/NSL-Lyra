import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../core/calendar.dart';
import '../core/wiki_links.dart';
import 'database.dart';
import 'image_store.dart';

class Backlink {
  const Backlink(this.entry, this.snippet);
  final Entry entry;
  final String snippet;
}

class RelationView {
  const RelationView({required this.relation, required this.other, required this.label});
  final Relation relation;
  final Entry other;

  /// Label from the viewpoint of the entry being displayed.
  final String label;
}

class TimelineItem {
  const TimelineItem({required this.entry, required this.start, this.end, this.participantIds = const []});
  final Entry entry;
  final WorldDate start;
  final WorldDate? end;
  final List<String> participantIds;
}

class Repository {
  /// [clock] is injectable so tests can simulate two devices with different times.
  Repository(this.db, {DateTime Function()? clock, ImageStore? images})
      : _clock = clock ?? DateTime.now,
        images = images ?? ImageStore();
  final AppDatabase db;

  /// Where entry pictures are kept (see [ImageStore]).
  final ImageStore images;
  final DateTime Function() _clock;

  DateTime? _floor;

  /// Current time for sync stamps. Never earlier than the floor set after a sync, so an edit made
  /// in the same second a sync finished is still stamped as later than that sync.
  DateTime now() {
    final c = _clock();
    final f = _floor;
    return f != null && c.isBefore(f) ? f : c;
  }

  /// Called by sync: from now on, stamps are at least [t].
  void stampsNoEarlierThan(DateTime t) {
    if (_floor == null || t.isAfter(_floor!)) _floor = t;
  }

  Future<void> _tombstone(String kind, String id, String worldId) => db.into(db.tombstones).insertOnConflictUpdate(
      TombstonesCompanion.insert(kind: kind, recordId: id, worldId: worldId, deletedAt: now()));

  // ---- Timeline ----

  /// Sets (or, with [start] null, removes) the entry's place on the timeline.
  /// Does nothing (and keeps the sync stamp) when the stored value is already identical.
  Future<void> setTimeline(String entryId, {WorldDate? start, WorldDate? end, List<String> participants = const []}) {
    return db.transaction(() async {
      final people = participants.toSet().where((id) => id != entryId).toSet();
      final existing = await (db.select(db.timelineEvents)..where((t) => t.entryId.equals(entryId))).getSingleOrNull();
      final existingPeople = {
        for (final p in await (db.select(db.eventParticipants)..where((p) => p.eventEntryId.equals(entryId))).get()) p.participantId,
      };
      if (start == null) {
        if (existing == null) return;
        final worldId = (await (db.select(db.entries)..where((e) => e.id.equals(entryId))).getSingle()).worldId;
        await (db.delete(db.eventParticipants)..where((p) => p.eventEntryId.equals(entryId))).go();
        await (db.delete(db.timelineEvents)..where((t) => t.entryId.equals(entryId))).go();
        await _tombstone('timeline', entryId, worldId);
        return;
      }
      if (existing != null &&
          existing.startYear == start.year &&
          existing.startMonth == start.month &&
          existing.startDay == start.day &&
          existing.endYear == end?.year &&
          existing.endMonth == end?.month &&
          existing.endDay == end?.day &&
          existingPeople.length == people.length &&
          existingPeople.containsAll(people)) {
        return;
      }
      await (db.delete(db.eventParticipants)..where((p) => p.eventEntryId.equals(entryId))).go();
      await db.into(db.timelineEvents).insertOnConflictUpdate(TimelineEventsCompanion.insert(
            entryId: entryId,
            startYear: start.year,
            startMonth: Value(start.month),
            startDay: Value(start.day),
            endYear: Value(end?.year),
            endMonth: Value(end?.month),
            endDay: Value(end?.day),
            modified: Value(now()),
          ));
      for (final id in people) {
        await db.into(db.eventParticipants).insert(EventParticipantsCompanion.insert(eventEntryId: entryId, participantId: id));
      }
    });
  }

  /// Timeline of a world, oldest first.
  Future<List<TimelineItem>> timelineOfWorld(String worldId) async {
    final rows = await (db.select(db.timelineEvents).join([
      innerJoin(db.entries, db.entries.id.equalsExp(db.timelineEvents.entryId)),
    ])
          ..where(db.entries.worldId.equals(worldId)))
        .get();
    final parts = await (db.select(db.eventParticipants).join([
      innerJoin(db.entries, db.entries.id.equalsExp(db.eventParticipants.eventEntryId)),
    ])
          ..where(db.entries.worldId.equals(worldId)))
        .map((r) => r.readTable(db.eventParticipants))
        .get();
    final byEvent = <String, List<String>>{};
    for (final p in parts) {
      byEvent.putIfAbsent(p.eventEntryId, () => []).add(p.participantId);
    }
    final items = [
      for (final r in rows)
        () {
          final t = r.readTable(db.timelineEvents);
          return TimelineItem(
            entry: r.readTable(db.entries),
            start: WorldDate(t.startYear, t.startMonth, t.startDay),
            end: t.endYear == null ? null : WorldDate(t.endYear!, t.endMonth, t.endDay),
            participantIds: byEvent[t.entryId] ?? const [],
          );
        }(),
    ];
    items.sort((a, b) {
      final c = a.start.compareTo(b.start);
      return c != 0 ? c : a.entry.title.compareTo(b.entry.title);
    });
    return items;
  }

  Stream<List<TimelineItem>> watchTimeline(String worldId) => db
      .customSelect('SELECT 1', readsFrom: {db.timelineEvents, db.eventParticipants, db.entries})
      .watch()
      .asyncMap((_) => timelineOfWorld(worldId));

  Future<void> setCalendar(String worldId, CalendarConfig cfg) =>
      (db.update(db.worlds)..where((w) => w.id.equals(worldId)))
          .write(WorldsCompanion(calendarConfig: Value(cfg.encode()), modified: Value(now())));

  static int _seq = 0;
  static final _rng = math.Random.secure();

  /// Unique across devices too: time + counter + random, since synced devices create ids independently.
  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(_seq++).toRadixString(36)}${_rng.nextInt(1 << 30).toRadixString(36)}';

  // ---- Worlds ----
  Future<List<World>> worlds() =>
      (db.select(db.worlds)..orderBy([(w) => OrderingTerm.asc(w.created)])).get();

  Future<List<Entry>> entriesOfWorld(String worldId) =>
      (db.select(db.entries)..where((e) => e.worldId.equals(worldId))..orderBy([(e) => OrderingTerm.asc(e.created)])).get();

  Future<List<Relation>> relationsOfWorld(String worldId) {
    final q = db.select(db.relations).join([
      innerJoin(db.entries, db.entries.id.equalsExp(db.relations.fromEntry)),
    ])
      ..where(db.entries.worldId.equals(worldId));
    return q.map((r) => r.readTable(db.relations)).get();
  }

  Stream<List<Relation>> watchRelationsOfWorld(String worldId) => db
      .customSelect('SELECT 1', readsFrom: {db.relations, db.entries})
      .watch()
      .asyncMap((_) => relationsOfWorld(worldId));

  Stream<List<World>> watchWorlds() =>
      (db.select(db.worlds)..orderBy([(w) => OrderingTerm.asc(w.created)])).watch();

  Future<World> createWorld(String name) async {
    final t = now();
    final w = WorldsCompanion.insert(id: newId(), name: name, created: t, modified: Value(t));
    await db.into(db.worlds).insert(w);
    return (db.select(db.worlds)..where((t) => t.id.equals(w.id.value))).getSingle();
  }

  Future<void> renameWorld(String id, String name) =>
      (db.update(db.worlds)..where((t) => t.id.equals(id))).write(WorldsCompanion(name: Value(name), modified: Value(now())));

  /// Deletes a world and leaves one 'world' tombstone, so a sync deletes it on the other
  /// device too (unless it was edited there after this moment).
  Future<void> deleteWorld(String id) => db.transaction(() async {
        await (db.delete(db.worlds)..where((t) => t.id.equals(id))).go();
        // The per-record tombstones of a world that no longer exists mean nothing.
        await (db.delete(db.tombstones)..where((t) => t.worldId.equals(id))).go();
        await _tombstone('world', id, id);
      });

  // ---- Entries ----
  Stream<List<Entry>> watchEntries(String worldId) => (db.select(db.entries)
        ..where((e) => e.worldId.equals(worldId))
        ..orderBy([(e) => OrderingTerm.desc(e.updated)]))
      .watch();

  Stream<Entry?> watchEntry(String id) =>
      (db.select(db.entries)..where((e) => e.id.equals(id))).watchSingleOrNull();

  Future<Entry> createEntry({
    required String worldId,
    required EntryType type,
    required String title,
    String summary = '',
    String body = '',
    EntryStatus status = EntryStatus.draft,
    List<String> aliases = const [],
    List<String> tags = const [],
    Map<String, String> fields = const {},
  }) async {
    final stamp = now();
    final id = newId();
    await db.into(db.entries).insert(EntriesCompanion.insert(
          id: id,
          worldId: worldId,
          type: type,
          title: title,
          aliases: Value(jsonEncode(aliases)),
          summary: Value(summary),
          body: Value(body),
          status: Value(status),
          tags: Value(jsonEncode(tags)),
          fields: Value(jsonEncode(fields)),
          created: stamp,
          updated: stamp,
          modified: Value(stamp),
        ));
    return (db.select(db.entries)..where((t) => t.id.equals(id))).getSingle();
  }

  /// True if another entry in the world already uses [title] as its title or alias.
  Future<bool> titleTaken(String worldId, String title, {String? exceptId}) async {
    final rows = await (db.select(db.entries)..where((e) => e.worldId.equals(worldId))).get();
    return rows.any((e) => e.id != exceptId && (e.title == title || decodeList(e.aliases).contains(title)));
  }

  /// [base], or "[base] 2", "[base] 3"… if that title is already used.
  Future<String> uniqueTitle(String worldId, String base) async {
    var candidate = base;
    for (var n = 2; await titleTaken(worldId, candidate); n++) {
      candidate = '$base $n';
    }
    return candidate;
  }

  /// Updates only the provided values and bumps `updated`.
  /// Changing [title] rewrites `[[old]]` links in the world's other entries
  /// (and in [body]); callers must check [titleTaken] first.
  ///
  /// [expectedModified] is the `modified` stamp the caller last saw (an open editor). If the
  /// stored entry has moved on since (a sync brought in another version) and this update would
  /// overwrite it, that version is first kept as a "(ขัดแย้ง)" copy — the person typing wins,
  /// nothing is lost. Returns the entry as stored afterwards (null if it no longer exists) and
  /// the title of the conflict copy, if one was made.
  Future<({Entry? entry, String? conflictCopy})> updateEntry(
    String id, {
    EntryType? type,
    String? title,
    String? summary,
    String? body,
    EntryStatus? status,
    List<String>? aliases,
    List<String>? tags,
    Map<String, String>? fields,
    Value<String?> imagePath = const Value.absent(),
    DateTime? expectedModified,
  }) {
    return db.transaction(() async {
      final current = await (db.select(db.entries)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (current == null) return (entry: null, conflictCopy: null);
      var newBody = body;
      final renaming = title != null && title != current.title;
      if (renaming) newBody = newBody == null ? null : renameLinkTarget(newBody, current.title, title);
      final unchanged = (type == null || type == current.type) &&
          !renaming &&
          (summary == null || summary == current.summary) &&
          (newBody == null || newBody == current.body) &&
          (status == null || status == current.status) &&
          (aliases == null || jsonEncode(aliases) == current.aliases) &&
          (tags == null || jsonEncode(tags) == current.tags) &&
          (fields == null || jsonEncode(fields) == current.fields) &&
          !imagePath.present;
      if (unchanged) return (entry: current, conflictCopy: null); // an autosave with no real change must not look like a new edit
      String? copy;
      if (expectedModified != null && _secs(current.modified) != _secs(expectedModified)) {
        copy = await _keepConflictCopy(current);
      }
      if (renaming) await _renameLinks(current.worldId, current.id, current.title, title);
      await _writeEntry(id, type, title, summary, newBody, status, aliases, tags, fields, imagePath);
      final stored = await (db.select(db.entries)..where((t) => t.id.equals(id))).getSingleOrNull();
      return (entry: stored, conflictCopy: copy);
    });
  }

  static int _secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  /// Keeps [e] as an extra entry. The id depends only on that version, so the same copy made by
  /// a sync on another device is the same row. Returns the copy's title, or null if it exists.
  Future<String?> _keepConflictCopy(Entry e) async {
    final id = 'cc-${e.id}-${_secs(e.modified)}';
    final exists = await (db.select(db.entries)..where((x) => x.id.equals(id))).getSingleOrNull();
    if (exists != null) return null;
    final title = await uniqueTitle(e.worldId, '${e.title} (ขัดแย้ง)');
    await db.into(db.entries).insert(e.copyWith(id: id, title: title));
    return title;
  }

  Future<void> _renameLinks(String worldId, String exceptId, String from, String to) async {
    final rows = await (db.select(db.entries)..where((e) => e.worldId.equals(worldId) & e.id.equals(exceptId).not())).get();
    for (final e in rows) {
      final next = renameLinkTarget(e.body, from, to);
      if (next != e.body) {
        // `updated` stays: a rename elsewhere is not an edit the user made to this entry.
        // `modified` moves, so a sync still carries the rewritten links.
        await (db.update(db.entries)..where((t) => t.id.equals(e.id)))
            .write(EntriesCompanion(body: Value(next), modified: Value(now())));
      }
    }
  }

  Future<void> _writeEntry(
    String id,
    EntryType? type,
    String? title,
    String? summary,
    String? body,
    EntryStatus? status,
    List<String>? aliases,
    List<String>? tags,
    Map<String, String>? fields,
    Value<String?> imagePath,
  ) {
    return (db.update(db.entries)..where((t) => t.id.equals(id))).write(EntriesCompanion(
      type: type == null ? const Value.absent() : Value(type),
      title: title == null ? const Value.absent() : Value(title),
      summary: summary == null ? const Value.absent() : Value(summary),
      body: body == null ? const Value.absent() : Value(body),
      status: status == null ? const Value.absent() : Value(status),
      aliases: aliases == null ? const Value.absent() : Value(jsonEncode(aliases)),
      tags: tags == null ? const Value.absent() : Value(jsonEncode(tags)),
      fields: fields == null ? const Value.absent() : Value(jsonEncode(fields)),
      imagePath: imagePath,
      updated: Value(now()),
      modified: Value(now()),
    ));
  }

  Future<void> deleteEntry(String id) => db.transaction(() async {
        final e = await (db.select(db.entries)..where((t) => t.id.equals(id))).getSingleOrNull();
        if (e == null) return;
        await (db.delete(db.entries)..where((t) => t.id.equals(id))).go();
        await _tombstone('entry', id, e.worldId);
      });

  /// Removes picture files that no entry uses (after entries were deleted or pictures replaced).
  Future<int> pruneImages() async {
    final used = {
      for (final e in await db.select(db.entries).get())
        if (e.imagePath != null) e.imagePath!,
    };
    return images.prune(used);
  }

  Future<Entry> duplicateEntry(String id) async {
    final e = await (db.select(db.entries)..where((t) => t.id.equals(id))).getSingle();
    final copy = await _duplicate(e);
    if (e.imagePath != null) {
      await updateEntry(copy.id, imagePath: Value(e.imagePath));
      return await (db.select(db.entries)..where((t) => t.id.equals(copy.id))).getSingle();
    }
    return copy;
  }

  Future<Entry> _duplicate(Entry e) {
    return createEntry(
      worldId: e.worldId,
      type: e.type,
      title: '${e.title} (สำเนา)',
      summary: e.summary,
      body: e.body,
      status: e.status,
      aliases: decodeList(e.aliases),
      tags: decodeList(e.tags),
      fields: decodeMap(e.fields),
    );
  }

  // ---- Links ----

  /// Resolves a `[[name]]` target against titles, then aliases.
  Entry? resolveLink(List<Entry> all, String name) {
    for (final e in all) {
      if (e.title == name) return e;
    }
    for (final e in all) {
      if (decodeList(e.aliases).contains(name)) return e;
    }
    return null;
  }

  /// Entries in the same world whose body links to [target] (by title or alias).
  List<Backlink> backlinksFor(List<Entry> all, Entry target) {
    final names = {target.title, ...decodeList(target.aliases)};
    final out = <Backlink>[];
    for (final e in all) {
      if (e.id == target.id) continue;
      final hit = extractLinks(e.body).where(names.contains).toList();
      if (hit.isEmpty) continue;
      out.add(Backlink(e, backlinkSnippet(e.body, hit.first) ?? ''));
    }
    return out;
  }

  // ---- Relations ----
  Future<void> addRelation({
    required String from,
    required String to,
    required String type,
    String inverseType = '',
    String note = '',
  }) =>
      db.into(db.relations).insert(RelationsCompanion.insert(
            id: newId(),
            fromEntry: from,
            toEntry: to,
            type: type,
            inverseType: Value(inverseType),
            note: Value(note),
            modified: Value(now()),
          ));

  Future<void> deleteRelation(String id) => db.transaction(() async {
        final r = await (db.select(db.relations)..where((t) => t.id.equals(id))).getSingleOrNull();
        if (r == null) return;
        final from = await (db.select(db.entries)..where((e) => e.id.equals(r.fromEntry))).getSingle();
        await (db.delete(db.relations)..where((t) => t.id.equals(id))).go();
        await _tombstone('relation', id, from.worldId);
      });

  Stream<List<Relation>> watchRelationsOf(String entryId) => (db.select(db.relations)
        ..where((r) => r.fromEntry.equals(entryId) | r.toEntry.equals(entryId)))
      .watch();

  // ---- Search ----

  /// Case-insensitive match on title, aliases, summary, body and tags.
  /// FTS5 can replace this when worlds get large; Thai has no word spaces,
  /// so plain substring matching is the safest baseline.
  List<Entry> search(List<Entry> all, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((e) {
      final hay = [e.title, e.aliases, e.summary, e.body, e.tags].join('\n').toLowerCase();
      return hay.contains(q);
    }).toList();
  }
}

List<String> decodeList(String json) =>
    (jsonDecode(json) as List).map((e) => e.toString()).toList();

Map<String, String> decodeMap(String json) =>
    (jsonDecode(json) as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
