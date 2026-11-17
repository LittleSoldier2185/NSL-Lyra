import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';
import 'image_store.dart';
import 'repository.dart';

const syncFormat = 'nsl-writer-tools-sync';
const syncBundleFormat = 'nsl-writer-tools-sync-bundle';
const syncVersion = 1;

/// Thrown with a Thai, user-facing message when sync data cannot be used.
class SyncException implements Exception {
  SyncException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// What a merge changed on THIS device.
class SyncReport {
  SyncReport(this.worldId, this.worldName);
  final String worldId;
  final String worldName;
  bool createdWorld = false;
  int entriesAdded = 0;
  int entriesUpdated = 0;
  int entriesDeleted = 0;
  int relationsChanged = 0;
  int timelineChanged = 0;

  /// The world was deleted on the other device and has been deleted here too.
  bool worldDeleted = false;

  /// Losing versions kept as "(ขัดแย้ง)" copies so no text is lost.
  int conflicts = 0;

  /// Entries renamed because two devices created the same title independently.
  int renamed = 0;

  bool get changed =>
      createdWorld ||
      worldDeleted ||
      entriesAdded + entriesUpdated + entriesDeleted + relationsChanged + timelineChanged + conflicts + renamed > 0;

  String get summary {
    if (!changed) return '“$worldName”: ข้อมูลตรงกันอยู่แล้ว';
    if (worldDeleted) return '“$worldName”: ลบแล้ว (ถูกลบจากอีกเครื่อง)';
    final parts = <String>[
      if (createdWorld) 'สร้างโลกใหม่',
      if (entriesAdded > 0) 'เพิ่ม $entriesAdded รายการ',
      if (entriesUpdated > 0) 'อัปเดต $entriesUpdated รายการ',
      if (entriesDeleted > 0) 'ลบ $entriesDeleted รายการ',
      if (relationsChanged > 0) 'ความสัมพันธ์ $relationsChanged',
      if (timelineChanged > 0) 'เส้นเวลา $timelineChanged',
      if (conflicts > 0) 'ชนกัน $conflicts (เก็บสำเนา “ขัดแย้ง” ไว้)',
      if (renamed > 0) 'เปลี่ยนชื่อที่ซ้ำ $renamed',
    ];
    return '“$worldName”: ${parts.join(', ')}';
  }
}

int _s(DateTime d) => d.millisecondsSinceEpoch ~/ 1000; // the database keeps whole seconds

class _Tl {
  _Tl(this.event, this.people);
  final TimelineEvent event;
  final Set<String> people;
}

class _Snapshot {
  _Snapshot({
    required this.world,
    required this.entries,
    required this.relations,
    required this.timeline,
    required this.tombstones,
  });
  final World world;
  final List<Entry> entries;
  final List<Relation> relations;
  final List<_Tl> timeline;
  final List<Tombstone> tombstones;
}

/// Merges worlds between devices.
///
/// Every record carries a `modified` stamp and deletions leave tombstones, so two copies of a
/// world can be merged in either direction and converge. The newest edit wins; when the loser
/// had been edited since the last sync its text is kept as a conflict copy. Relies on device
/// clocks being roughly right.
class SyncService {
  SyncService(this.repo);
  final Repository repo;
  AppDatabase get _db => repo.db;

  // ======================= export =======================

  /// Every world on this device, as one string to hand to another device.
  Future<String> exportBundle() async {
    final snaps = <Map<String, dynamic>>[];
    for (final w in await repo.worlds()) {
      final snap = await _readLocal(w.id);
      snaps.add(_encode(snap, await repo.images.exportData(snap.entries.map((e) => e.imagePath))));
    }
    final gone = await (_db.select(_db.tombstones)..where((t) => t.kind.equals('world'))).get();
    return const JsonEncoder.withIndent(' ').convert({
      'format': syncBundleFormat,
      'version': syncVersion,
      'exportedAt': repo.now().toUtc().toIso8601String(),
      'snapshots': snaps,
      'deletedWorlds': [
        for (final t in gone) {'id': t.recordId, 'deletedAt': _iso(t.deletedAt)},
      ],
    });
  }

  // ======================= merge =======================

  /// Merges a bundle (or a single world snapshot) into this device.
  Future<List<SyncReport>> mergeBundle(String json) async {
    final Object? root;
    try {
      root = jsonDecode(json);
    } on FormatException {
      throw SyncException('ไฟล์นี้ไม่ใช่ข้อมูลซิงก์ที่อ่านได้');
    }
    if (root is! Map) throw SyncException('ไฟล์นี้ไม่ใช่ข้อมูลซิงก์ของ NSL Writer Tools');
    final version = root['version'];
    if (version is! int || version > syncVersion) {
      throw SyncException('ข้อมูลซิงก์นี้มาจากแอปเวอร์ชันใหม่กว่า — กรุณาอัปเดตแอปก่อน');
    }
    final List snaps;
    var deleted = <String, DateTime>{};
    if (root['format'] == syncBundleFormat) {
      snaps = root['snapshots'] as List? ?? const [];
      try {
        deleted = {
          for (final d in ((root['deletedWorlds'] ?? const []) as List).cast<Map>())
            d['id'] as String: _t(d['deletedAt']),
        };
      } on TypeError {
        throw SyncException('ข้อมูลซิงก์เสียหายหรือไม่ครบ');
      } on FormatException {
        throw SyncException('ข้อมูลซิงก์เสียหายหรือไม่ครบ');
      }
    } else if (root['format'] == syncFormat) {
      snaps = [root];
    } else {
      throw SyncException('ไฟล์นี้ไม่ใช่ข้อมูลซิงก์ของ NSL Writer Tools');
    }
    final parsed = <_Snapshot>[];
    try {
      for (final s in snaps) {
        parsed.add(_decode(s as Map));
      }
    } on TypeError {
      throw SyncException('ข้อมูลซิงก์เสียหายหรือไม่ครบ');
    } on FormatException {
      throw SyncException('ข้อมูลซิงก์เสียหายหรือไม่ครบ');
    }
    // Pictures first, so an entry that arrives never points at a file we have not stored yet.
    for (final s in snaps) {
      for (final e in ((s as Map)['entries'] as List).cast<Map>()) {
        await repo.images.importData(e['imagePath'] as String?, e['imageData']);
      }
    }
    final reports = <SyncReport>[];
    for (final p in parsed) {
      final gone = await _worldTombstone(p.world.id);
      if (gone != null) {
        // Deleted here. Only an edit made on the other device after that brings it back.
        if (_s(_activity(p)) <= _s(gone.deletedAt)) continue;
        await (_db.delete(_db.tombstones)..where((t) => t.kind.equals('world') & t.recordId.equals(p.world.id))).go();
      }
      reports.add(await _mergeWorld(p));
    }
    for (final d in deleted.entries) {
      final r = await _applyWorldDeletion(d.key, d.value);
      if (r != null) reports.add(r);
    }
    return reports;
  }

  Future<Tombstone?> _worldTombstone(String worldId) => (_db.select(_db.tombstones)
        ..where((t) => t.kind.equals('world') & t.recordId.equals(worldId)))
      .getSingleOrNull();

  /// When anything in the world last changed (deleted records count too).
  DateTime _activity(_Snapshot s) {
    var latest = s.world.modified;
    void see(DateTime d) {
      if (d.isAfter(latest)) latest = d;
    }

    for (final e in s.entries) {
      see(e.modified);
    }
    for (final r in s.relations) {
      see(r.modified);
    }
    for (final t in s.timeline) {
      see(t.event.modified);
    }
    for (final t in s.tombstones) {
      see(t.deletedAt);
    }
    return latest;
  }

  /// The other device deleted a world. Delete it here too unless it was edited here after that,
  /// or it is the only world left on this device (the app always keeps one).
  Future<SyncReport?> _applyWorldDeletion(String worldId, DateTime at) async {
    final mine = await _worldTombstone(worldId);
    final world = await (_db.select(_db.worlds)..where((w) => w.id.equals(worldId))).getSingleOrNull();
    if (world == null) {
      // Not here (never had it, or already deleted): remember it so it travels on.
      if (mine == null || _s(at) > _s(mine.deletedAt)) {
        await _db.into(_db.tombstones).insertOnConflictUpdate(
            Tombstone(kind: 'world', recordId: worldId, worldId: worldId, deletedAt: at));
      }
      return null;
    }
    if (_s(_activity(await _readLocal(worldId))) > _s(at)) return null; // edited here since
    if ((await repo.worlds()).length <= 1) return null;
    final report = SyncReport(worldId, world.name)..worldDeleted = true;
    await _db.transaction(() async {
      await (_db.delete(_db.worlds)..where((w) => w.id.equals(worldId))).go();
      await (_db.delete(_db.tombstones)..where((t) => t.worldId.equals(worldId))).go();
      await _db.into(_db.tombstones).insertOnConflictUpdate(
          Tombstone(kind: 'world', recordId: worldId, worldId: worldId, deletedAt: at));
    });
    return report;
  }

  /// Server side of a Wi-Fi sync: merge what the other device sent, then answer with
  /// everything this device has so the other side ends up identical.
  Future<(List<SyncReport>, String)> exchange(String clientBundle) async {
    final reports = await mergeBundle(clientBundle);
    return (reports, await exportBundle());
  }

  Future<SyncReport> _mergeWorld(_Snapshot remote) {
    return _db.transaction(() async {
      var world = await (_db.select(_db.worlds)..where((w) => w.id.equals(remote.world.id))).getSingleOrNull();
      final report = SyncReport(remote.world.id, remote.world.name);
      if (world == null) {
        await _db.into(_db.worlds).insert(remote.world.copyWith(lastSyncAt: const Value(null)));
        world = remote.world;
        report.createdWorld = true;
      } else if (_s(remote.world.modified) > _s(world.modified)) {
        await (_db.update(_db.worlds)..where((w) => w.id.equals(world!.id))).write(WorldsCompanion(
          name: Value(remote.world.name),
          calendarConfig: Value(remote.world.calendarConfig),
          modified: Value(remote.world.modified),
        ));
      }
      final wid = remote.world.id;
      final local = await _readLocal(wid);
      final lastSync = world.lastSyncAt == null ? null : _s(world.lastSyncAt!);
      // Strictly after the previous sync. (Edits in the same second as a sync's end are pushed
      // past it by Repository.stampsNoEarlierThan, so nothing is missed.)
      bool editedSinceSync(DateTime modified) => lastSync == null || _s(modified) > lastSync;

      final localTomb = {for (final t in local.tombstones) '${t.kind}|${t.recordId}': t};
      final remoteTomb = {for (final t in remote.tombstones) '${t.kind}|${t.recordId}': t};

      // ---------- entries ----------
      final lE = {for (final e in local.entries) e.id: e};
      final rE = {for (final e in remote.entries) e.id: e};
      for (final id in {...lE.keys, ...rE.keys}) {
        final l = lE[id], r = rE[id];
        if (l != null && r != null) {
          if (_entryKey(l) == _entryKey(r)) continue;
          final remoteWins = _remoteWins(r.modified, l.modified, _entryKey(r), _entryKey(l));
          final loser = remoteWins ? l : r;
          if (editedSinceSync(loser.modified) && await _keepConflictCopy(wid, loser)) report.conflicts++;
          if (remoteWins) {
            await _db.into(_db.entries).insertOnConflictUpdate(r);
            report.entriesUpdated++;
          }
        } else if (l != null) {
          final t = remoteTomb['entry|$id'];
          if (t != null && _s(t.deletedAt) >= _s(l.modified)) {
            await (_db.delete(_db.entries)..where((e) => e.id.equals(id))).go();
            report.entriesDeleted++;
          }
        } else if (r != null) {
          final t = localTomb['entry|$id'];
          if (t != null && _s(t.deletedAt) >= _s(r.modified)) continue; // deleted here after that edit
          await _db.into(_db.entries).insertOnConflictUpdate(r);
          report.entriesAdded++;
        }
      }

      // ---------- relations ----------
      final liveIds = {for (final e in await repo.entriesOfWorld(wid)) e.id};
      final lR = {for (final r in local.relations) r.id: r};
      final rR = {for (final r in remote.relations) r.id: r};
      for (final id in {...lR.keys, ...rR.keys}) {
        final l = lR[id], r = rR[id];
        if (l != null && r != null) {
          if (_relKey(l) == _relKey(r)) continue;
          if (_remoteWins(r.modified, l.modified, _relKey(r), _relKey(l))) {
            await _db.into(_db.relations).insertOnConflictUpdate(r);
            report.relationsChanged++;
          }
        } else if (l != null) {
          final t = remoteTomb['relation|$id'];
          if (t != null && _s(t.deletedAt) >= _s(l.modified)) {
            await (_db.delete(_db.relations)..where((x) => x.id.equals(id))).go();
            report.relationsChanged++;
          }
        } else if (r != null) {
          final t = localTomb['relation|$id'];
          if (t != null && _s(t.deletedAt) >= _s(r.modified)) continue;
          if (!liveIds.contains(r.fromEntry) || !liveIds.contains(r.toEntry)) continue; // an endpoint was deleted
          await _db.into(_db.relations).insertOnConflictUpdate(r);
          report.relationsChanged++;
        }
      }

      // ---------- timeline ----------
      final lT = {for (final t in local.timeline) t.event.entryId: t};
      final rT = {for (final t in remote.timeline) t.event.entryId: t};
      for (final id in {...lT.keys, ...rT.keys}) {
        final l = lT[id], r = rT[id];
        if (l != null && r != null) {
          if (_tlKey(l) == _tlKey(r)) continue;
          if (_remoteWins(r.event.modified, l.event.modified, _tlKey(r), _tlKey(l))) {
            await _writeTimeline(r, liveIds);
            report.timelineChanged++;
          }
        } else if (l != null) {
          final t = remoteTomb['timeline|$id'];
          if (t != null && _s(t.deletedAt) >= _s(l.event.modified)) {
            await _clearTimeline(id);
            report.timelineChanged++;
          }
        } else if (r != null) {
          final t = localTomb['timeline|$id'];
          if (t != null && _s(t.deletedAt) >= _s(r.event.modified)) continue;
          if (!liveIds.contains(id)) continue;
          await _writeTimeline(r, liveIds);
          report.timelineChanged++;
        }
      }

      // ---------- tombstones travel on ----------
      for (final t in remote.tombstones) {
        final mine = localTomb['${t.kind}|${t.recordId}'];
        if (mine == null || _s(t.deletedAt) > _s(mine.deletedAt)) {
          await _db.into(_db.tombstones).insertOnConflictUpdate(t);
        }
      }

      report.renamed += await _resolveTitleClashes(wid);
      await _dropSupersededTombstones(wid);
      final end = repo.now();
      await (_db.update(_db.worlds)..where((w) => w.id.equals(wid))).write(WorldsCompanion(lastSyncAt: Value(end)));
      repo.stampsNoEarlierThan(DateTime.fromMillisecondsSinceEpoch((_s(end) + 1) * 1000));
      return report;
    });
  }

  /// Newest stamp wins; on an exact tie the larger content wins, so every device picks the same one.
  bool _remoteWins(DateTime remote, DateTime local, String remoteKey, String localKey) {
    final c = _s(remote).compareTo(_s(local));
    return c != 0 ? c > 0 : remoteKey.compareTo(localKey) > 0;
  }

  /// Keeps [loser] as an extra entry. The id depends only on the lost version, so every device
  /// makes the very same copy and they never multiply. Returns false if it already exists.
  Future<bool> _keepConflictCopy(String worldId, Entry loser) async {
    final id = 'cc-${loser.id}-${_s(loser.modified)}';
    final exists = await (_db.select(_db.entries)..where((e) => e.id.equals(id))).getSingleOrNull();
    if (exists != null) return false;
    await _db.into(_db.entries).insert(loser.copyWith(id: id, worldId: worldId, title: '${loser.title} (ขัดแย้ง)'));
    return true;
  }

  Future<void> _clearTimeline(String entryId) async {
    await (_db.delete(_db.eventParticipants)..where((p) => p.eventEntryId.equals(entryId))).go();
    await (_db.delete(_db.timelineEvents)..where((t) => t.entryId.equals(entryId))).go();
  }

  Future<void> _writeTimeline(_Tl t, Set<String> liveIds) async {
    await _clearTimeline(t.event.entryId);
    await _db.into(_db.timelineEvents).insertOnConflictUpdate(t.event);
    for (final p in t.people) {
      if (p != t.event.entryId && liveIds.contains(p)) {
        await _db.into(_db.eventParticipants)
            .insert(EventParticipantsCompanion.insert(eventEntryId: t.event.entryId, participantId: p));
      }
    }
  }

  /// Links resolve by title, so after a merge no two entries may share one. The newest-created
  /// entry gets renamed (ties broken by id), which every device decides the same way.
  Future<int> _resolveTitleClashes(String worldId) async {
    final all = await repo.entriesOfWorld(worldId);
    final byTitle = <String, List<Entry>>{};
    for (final e in all) {
      byTitle.putIfAbsent(e.title, () => []).add(e);
    }
    var renamed = 0;
    for (final group in byTitle.values.where((g) => g.length > 1)) {
      group.sort((a, b) {
        final c = _s(a.created).compareTo(_s(b.created));
        return c != 0 ? c : a.id.compareTo(b.id);
      });
      for (final e in group.skip(1)) {
        final title = await repo.uniqueTitle(worldId, e.title);
        await (_db.update(_db.entries)..where((x) => x.id.equals(e.id)))
            .write(EntriesCompanion(title: Value(title), modified: Value(repo.now())));
        renamed++;
      }
    }
    return renamed;
  }

  /// A tombstone is only meaningful while nothing newer was written to the same record.
  Future<void> _dropSupersededTombstones(String worldId) async {
    final tombs = await (_db.select(_db.tombstones)..where((t) => t.worldId.equals(worldId))).get();
    if (tombs.isEmpty) return;
    final entries = {for (final e in await repo.entriesOfWorld(worldId)) e.id: e.modified};
    final rels = {for (final r in await repo.relationsOfWorld(worldId)) r.id: r.modified};
    final tls = {for (final t in await _timelineOf(worldId)) t.event.entryId: t.event.modified};
    for (final t in tombs) {
      final live = switch (t.kind) { 'entry' => entries[t.recordId], 'relation' => rels[t.recordId], _ => tls[t.recordId] };
      if (live != null && _s(live) > _s(t.deletedAt)) {
        await (_db.delete(_db.tombstones)..where((x) => x.kind.equals(t.kind) & x.recordId.equals(t.recordId))).go();
      }
    }
  }

  // ======================= comparing =======================

  /// Content of an entry for equality. Field order must not matter (two devices may have typed
  /// them in a different order).
  String _entryKey(Entry e) => jsonEncode([
        e.type.name,
        e.title,
        decodeList(e.aliases),
        e.summary,
        e.body,
        e.status.name,
        decodeList(e.tags),
        (decodeMap(e.fields).entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((x) => [x.key, x.value]).toList(),
        e.imagePath,
      ]);

  String _relKey(Relation r) => jsonEncode([r.fromEntry, r.toEntry, r.type, r.inverseType, r.note]);

  String _tlKey(_Tl t) {
    final e = t.event;
    return jsonEncode([e.startYear, e.startMonth, e.startDay, e.endYear, e.endMonth, e.endDay, t.people.toList()..sort()]);
  }

  // ======================= reading / encoding =======================

  Future<List<_Tl>> _timelineOf(String worldId) async {
    final events = await (_db.select(_db.timelineEvents).join([
      innerJoin(_db.entries, _db.entries.id.equalsExp(_db.timelineEvents.entryId)),
    ])
          ..where(_db.entries.worldId.equals(worldId)))
        .map((r) => r.readTable(_db.timelineEvents))
        .get();
    final parts = await (_db.select(_db.eventParticipants).join([
      innerJoin(_db.entries, _db.entries.id.equalsExp(_db.eventParticipants.eventEntryId)),
    ])
          ..where(_db.entries.worldId.equals(worldId)))
        .map((r) => r.readTable(_db.eventParticipants))
        .get();
    final byEvent = <String, Set<String>>{};
    for (final p in parts) {
      byEvent.putIfAbsent(p.eventEntryId, () => {}).add(p.participantId);
    }
    return [for (final e in events) _Tl(e, byEvent[e.entryId] ?? {})];
  }

  Future<_Snapshot> _readLocal(String worldId) async {
    final world = await (_db.select(_db.worlds)..where((w) => w.id.equals(worldId))).getSingle();
    return _Snapshot(
      world: world,
      entries: await repo.entriesOfWorld(worldId),
      relations: await repo.relationsOfWorld(worldId),
      timeline: await _timelineOf(worldId),
      tombstones: await (_db.select(_db.tombstones)..where((t) => t.worldId.equals(worldId))).get(),
    );
  }

  static String _iso(DateTime d) => d.toUtc().toIso8601String();

  Map<String, dynamic> _encode(_Snapshot s, Map<String, String> pictures) => {
        'format': syncFormat,
        'version': syncVersion,
        'world': {
          'id': s.world.id,
          'name': s.world.name,
          'calendarConfig': s.world.calendarConfig,
          'created': _iso(s.world.created),
          'modified': _iso(s.world.modified),
        },
        'entries': [
          for (final e in s.entries)
            {
              'id': e.id,
              'type': e.type.name,
              'title': e.title,
              'aliases': decodeList(e.aliases),
              'summary': e.summary,
              'body': e.body,
              'status': e.status.name,
              'tags': decodeList(e.tags),
              'fields': decodeMap(e.fields),
              'imagePath': e.imagePath,
              if (pictures.containsKey(e.imagePath)) 'imageData': pictures[e.imagePath],
              'created': _iso(e.created),
              'updated': _iso(e.updated),
              'modified': _iso(e.modified),
            },
        ],
        'relations': [
          for (final r in s.relations)
            {'id': r.id, 'from': r.fromEntry, 'to': r.toEntry, 'type': r.type, 'inverseType': r.inverseType, 'note': r.note, 'modified': _iso(r.modified)},
        ],
        'timeline': [
          for (final t in s.timeline)
            {
              'entry': t.event.entryId,
              'start': {'year': t.event.startYear, 'month': t.event.startMonth, 'day': t.event.startDay},
              'end': t.event.endYear == null
                  ? null
                  : {'year': t.event.endYear, 'month': t.event.endMonth, 'day': t.event.endDay},
              'participants': t.people.toList()..sort(),
              'modified': _iso(t.event.modified),
            },
        ],
        'tombstones': [
          for (final t in s.tombstones) {'kind': t.kind, 'id': t.recordId, 'deletedAt': _iso(t.deletedAt)},
        ],
      };

  static DateTime _t(Object? v) => DateTime.parse(v as String).toLocal();

  static T _enum<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  _Snapshot _decode(Map j) {
    final w = j['world'] as Map;
    final wid = w['id'] as String;
    final world = World(
      id: wid,
      name: w['name'] as String,
      calendarConfig: (w['calendarConfig'] as String?) ?? '{}',
      created: _t(w['created']),
      modified: _t(w['modified']),
      lastSyncAt: null,
    );
    List<String> strs(Object? v) => v is List ? v.map((e) => e.toString()).toList() : const [];
    final entries = [
      for (final e in (j['entries'] as List).cast<Map>())
        Entry(
          id: e['id'] as String,
          worldId: wid,
          type: _enum(EntryType.values, e['type'], EntryType.character),
          title: e['title'] as String,
          aliases: jsonEncode(strs(e['aliases'])),
          summary: (e['summary'] as String?) ?? '',
          body: (e['body'] as String?) ?? '',
          status: _enum(EntryStatus.values, e['status'], EntryStatus.draft),
          tags: jsonEncode(strs(e['tags'])),
          fields: jsonEncode(e['fields'] is Map ? (e['fields'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())) : {}),
          imagePath: ImageStore.validName(e['imagePath'] as String?) ? e['imagePath'] as String : null,
          created: _t(e['created']),
          updated: _t(e['updated']),
          modified: _t(e['modified']),
        ),
    ];
    final relations = [
      for (final r in ((j['relations'] ?? const []) as List).cast<Map>())
        Relation(
          id: r['id'] as String,
          fromEntry: r['from'] as String,
          toEntry: r['to'] as String,
          type: r['type'] as String,
          inverseType: (r['inverseType'] as String?) ?? '',
          note: (r['note'] as String?) ?? '',
          modified: _t(r['modified']),
        ),
    ];
    final timeline = <_Tl>[];
    for (final t in ((j['timeline'] ?? const []) as List).cast<Map>()) {
      final s = t['start'] as Map, e = t['end'] as Map?;
      timeline.add(_Tl(
        TimelineEvent(
          entryId: t['entry'] as String,
          startYear: s['year'] as int,
          startMonth: s['month'] as int?,
          startDay: s['day'] as int?,
          endYear: e?['year'] as int?,
          endMonth: e?['month'] as int?,
          endDay: e?['day'] as int?,
          modified: _t(t['modified']),
        ),
        strs(t['participants']).toSet(),
      ));
    }
    final tombstones = [
      for (final t in ((j['tombstones'] ?? const []) as List).cast<Map>())
        Tombstone(kind: t['kind'] as String, recordId: t['id'] as String, worldId: wid, deletedAt: _t(t['deletedAt'])),
    ];
    return _Snapshot(world: world, entries: entries, relations: relations, timeline: timeline, tombstones: tombstones);
  }
}
