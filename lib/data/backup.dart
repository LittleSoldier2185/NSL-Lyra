import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/calendar.dart';
import 'database.dart';
import 'repository.dart';

const backupFormat = 'nsl-writer-tools';
const backupVersion = 2;

/// Thrown with a Thai, user-facing message when a backup cannot be read.
class BackupException implements Exception {
  BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ImportResult {
  const ImportResult({required this.world, required this.entries, required this.relations, required this.skipped});
  final World world;
  final int entries;
  final int relations;

  /// Relations dropped because an endpoint was missing from the file.
  final int skipped;
}

/// JSON backup (one world per file) and Markdown export.
class BackupService {
  BackupService(this.repo);
  final Repository repo;
  AppDatabase get _db => repo.db;

  // ---------- JSON ----------

  Future<Map<String, dynamic>> exportWorld(World given) async {
    // Re-read so a stale World object can never export an outdated calendar or name.
    final world = await (_db.select(_db.worlds)..where((w) => w.id.equals(given.id))).getSingle();
    final entries = await repo.entriesOfWorld(world.id);
    final relations = await repo.relationsOfWorld(world.id);
    final pictures = await repo.images.exportData(entries.map((e) => e.imagePath));
    return {
      'format': backupFormat,
      'version': backupVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'world': {'name': world.name, 'calendarConfig': world.calendarConfig, 'created': world.created.toUtc().toIso8601String()},
      'entries': [
        for (final e in entries)
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
            // Added later: the picture itself (base64), so a backup restores it on any device.
            if (pictures.containsKey(e.imagePath)) 'imageData': pictures[e.imagePath],
            'created': e.created.toUtc().toIso8601String(),
            'updated': e.updated.toUtc().toIso8601String(),
          },
      ],
      'relations': [
        for (final r in relations)
          {'from': r.fromEntry, 'to': r.toEntry, 'type': r.type, 'inverseType': r.inverseType, 'note': r.note},
      ],
      // Added in format version 2.
      'timeline': [
        for (final t in await repo.timelineOfWorld(world.id))
          {
            'entry': t.entry.id,
            'start': _dateJson(t.start),
            'end': t.end == null ? null : _dateJson(t.end!),
            'participants': t.participantIds,
          },
      ],
    };
  }

  static Map<String, int> _dateJson(WorldDate d) => {
        'year': d.year,
        if (d.month != null) 'month': d.month!,
        if (d.day != null) 'day': d.day!,
      };

  static WorldDate _dateFrom(Object? j) {
    final m = j as Map;
    return WorldDate(m['year'] as int, m['month'] as int?, m['day'] as int?);
  }

  String encode(Map<String, dynamic> backup) => const JsonEncoder.withIndent('  ').convert(backup);

  /// Imports [json] as a NEW world (fresh ids, so importing twice or onto the
  /// device it came from never overwrites anything).
  Future<ImportResult> importWorld(String json) async {
    final Object? root;
    try {
      root = jsonDecode(json);
    } on FormatException {
      throw BackupException('ไฟล์นี้ไม่ใช่ JSON ที่อ่านได้');
    }
    if (root is! Map || root['format'] != backupFormat) {
      throw BackupException('ไฟล์นี้ไม่ใช่ไฟล์สำรองของ NSL Writer Tools');
    }
    final version = root['version'];
    if (version is! int || version > backupVersion) {
      throw BackupException('ไฟล์สำรองนี้สร้างจากแอปเวอร์ชันใหม่กว่า — กรุณาอัปเดตแอปก่อนนำเข้า');
    }

    try {
      final worldJson = root['world'] as Map;
      final entriesJson = (root['entries'] as List).cast<Map>();
      final relationsJson = ((root['relations'] ?? const []) as List).cast<Map>();
      final timelineJson = ((root['timeline'] ?? const []) as List).cast<Map>(); // absent in v1 files

      return await _db.transaction(() async {
        final existing = (await repo.worlds()).map((w) => w.name).toSet();
        var name = (worldJson['name'] as String).trim();
        if (name.isEmpty) name = 'โลกที่นำเข้า';
        if (existing.contains(name)) {
          final base = '$name (นำเข้า)';
          name = base;
          for (var n = 2; existing.contains(name); n++) {
            name = '$base $n';
          }
        }
        final world = await repo.createWorld(name);
        await (_db.update(_db.worlds)..where((w) => w.id.equals(world.id)))
            .write(WorldsCompanion(calendarConfig: Value((worldJson['calendarConfig'] as String?) ?? '{}'), modified: Value(repo.now())));

        final idMap = <String, String>{};
        for (final e in entriesJson) {
          final newId = Repository.newId();
          final pictureName = e['imagePath'] as String?;
          final hasPicture = await repo.images.importData(pictureName, e['imageData']);
          idMap[e['id'] as String] = newId;
          await _db.into(_db.entries).insert(EntriesCompanion.insert(
                id: newId,
                worldId: world.id,
                type: _enum(EntryType.values, e['type'], EntryType.character),
                title: e['title'] as String,
                aliases: Value(jsonEncode(_strings(e['aliases']))),
                summary: Value((e['summary'] as String?) ?? ''),
                body: Value((e['body'] as String?) ?? ''),
                status: Value(_enum(EntryStatus.values, e['status'], EntryStatus.draft)),
                tags: Value(jsonEncode(_strings(e['tags']))),
                fields: Value(jsonEncode(_stringMap(e['fields']))),
                imagePath: Value(hasPicture ? pictureName : null),
                created: DateTime.parse(e['created'] as String).toLocal(),
                updated: DateTime.parse(e['updated'] as String).toLocal(),
                modified: Value(DateTime.parse(e['updated'] as String).toLocal()),
              ));
        }

        var relCount = 0, skipped = 0;
        for (final r in relationsJson) {
          final from = idMap[r['from']], to = idMap[r['to']];
          if (from == null || to == null) {
            skipped++;
            continue;
          }
          await repo.addRelation(
            from: from,
            to: to,
            type: r['type'] as String,
            inverseType: (r['inverseType'] as String?) ?? '',
            note: (r['note'] as String?) ?? '',
          );
          relCount++;
        }
        for (final t in timelineJson) {
          final entry = idMap[t['entry']];
          if (entry == null) continue;
          await repo.setTimeline(
            entry,
            start: _dateFrom(t['start']),
            end: t['end'] == null ? null : _dateFrom(t['end']),
            participants: [for (final p in (t['participants'] as List? ?? const [])) if (idMap[p] != null) idMap[p]!],
          );
        }
        // Re-read: `world` predates the calendar config written above.
        final fresh = await (_db.select(_db.worlds)..where((w) => w.id.equals(world.id))).getSingle();
        return ImportResult(world: fresh, entries: idMap.length, relations: relCount, skipped: skipped);
      });
    } on BackupException {
      rethrow;
    } on TypeError {
      throw BackupException('โครงสร้างไฟล์สำรองไม่ถูกต้องหรือข้อมูลบางส่วนหายไป');
    } on FormatException {
      throw BackupException('โครงสร้างไฟล์สำรองไม่ถูกต้องหรือข้อมูลบางส่วนหายไป');
    }
  }

  static T _enum<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  static List<String> _strings(Object? v) => v is List ? v.map((e) => e.toString()).toList() : const [];

  static Map<String, String> _stringMap(Object? v) =>
      v is Map ? v.map((k, val) => MapEntry(k.toString(), val.toString())) : const {};

  // ---------- Markdown ----------

  /// Markdown for one entry, Obsidian-friendly: YAML front matter, then the
  /// body with `[[links]]` untouched. [relations] are (label, other title, note).
  static String entryToMarkdown(Entry e, List<(String, String, String)> relations, {bool frontMatter = true, int heading = 1}) {
    final b = StringBuffer();
    if (frontMatter) {
      b
        ..writeln('---')
        ..writeln('type: ${jsonEncode(e.type.name)}')
        ..writeln('status: ${jsonEncode(e.status.name)}')
        ..writeln('aliases: ${jsonEncode(decodeList(e.aliases))}')
        ..writeln('tags: ${jsonEncode(decodeList(e.tags))}')
        ..writeln('created: ${e.created.toUtc().toIso8601String()}')
        ..writeln('updated: ${e.updated.toUtc().toIso8601String()}')
        ..writeln('---')
        ..writeln();
    }
    b.writeln('${'#' * heading} ${e.title}\n');
    if (!frontMatter) {
      final meta = ['ประเภท: ${_typeLabel(e.type)}', 'สถานะ: ${e.status.name}'];
      final aliases = decodeList(e.aliases);
      if (aliases.isNotEmpty) meta.add('ชื่อเรียกอื่น: ${aliases.join(', ')}');
      final tags = decodeList(e.tags);
      if (tags.isNotEmpty) meta.add('แท็ก: ${tags.map((t) => '#$t').join(' ')}');
      b.writeln('*${meta.join(' · ')}*\n');
    }
    if (e.summary.isNotEmpty) b.writeln('> ${e.summary.replaceAll('\n', '\n> ')}\n');
    final fields = decodeMap(e.fields).entries.where((f) => f.value.isNotEmpty);
    if (fields.isNotEmpty) {
      for (final f in fields) {
        b.writeln('- **${f.key}:** ${f.value}');
      }
      b.writeln();
    }
    if (e.body.trim().isNotEmpty) b.writeln('${e.body.trim()}\n');
    if (relations.isNotEmpty) {
      b.writeln('${'#' * (heading + 1)} ความสัมพันธ์\n');
      for (final r in relations) {
        b.writeln('- ${r.$1} [[${r.$2}]]${r.$3.isEmpty ? '' : ' — ${r.$3}'}');
      }
      b.writeln();
    }
    return b.toString();
  }

  static String _typeLabel(EntryType t) => const {
        EntryType.character: 'ตัวละคร',
        EntryType.place: 'สถานที่',
        EntryType.org: 'องค์กร',
        EntryType.event: 'เหตุการณ์',
        EntryType.item: 'ไอเทม',
        EntryType.rule: 'กฎของโลก',
        EntryType.species: 'เผ่าพันธุ์',
      }[t]!;

  /// Relations of [entry] as (label seen from entry, other title, note).
  List<(String, String, String)> relationLines(Entry entry, List<Relation> all, Map<String, Entry> byId) {
    final out = <(String, String, String)>[];
    for (final r in all) {
      if (r.fromEntry == entry.id) {
        final o = byId[r.toEntry];
        if (o != null) out.add((r.type, o.title, r.note));
      } else if (r.toEntry == entry.id) {
        final o = byId[r.fromEntry];
        if (o != null) out.add((r.inverseType.isEmpty ? r.type : r.inverseType, o.title, r.note));
      }
    }
    return out;
  }

  Future<String> entryMarkdown(Entry e) async {
    final entries = await repo.entriesOfWorld(e.worldId);
    final rels = await repo.relationsOfWorld(e.worldId);
    return entryToMarkdown(e, relationLines(e, rels, {for (final x in entries) x.id: x}));
  }

  /// Whole world in one Markdown document, grouped by type.
  Future<String> worldMarkdown(World world) async {
    final entries = await repo.entriesOfWorld(world.id);
    final rels = await repo.relationsOfWorld(world.id);
    final byId = {for (final e in entries) e.id: e};
    final b = StringBuffer('# ${world.name}\n\n');
    for (final t in EntryType.values) {
      final group = entries.where((e) => e.type == t).toList();
      if (group.isEmpty) continue;
      b.writeln('## ${_typeLabel(t)}\n');
      for (final e in group) {
        b.writeln(entryToMarkdown(e, relationLines(e, rels, byId), frontMatter: false, heading: 3));
      }
    }
    return b.toString();
  }
}

/// A file name that is safe on Windows and Android.
String safeFileName(String s) {
  final cleaned = s.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_').trim();
  return cleaned.isEmpty ? 'export' : cleaned;
}
