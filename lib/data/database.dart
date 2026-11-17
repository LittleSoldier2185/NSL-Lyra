import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

enum EntryType { character, place, org, event, item, rule, species }

enum EntryStatus { idea, draft, canon }

class Worlds extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get calendarConfig => text().withDefault(const Constant('{}'))();
  DateTimeColumn get created => dateTime()();

  /// Sync stamp: moves whenever the name or calendar changes.
  DateTimeColumn get modified => dateTime().withDefault(Constant(DateTime.fromMillisecondsSinceEpoch(0)))();

  /// When this world was last merged with a sync file (null = never).
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get worldId => text().references(Worlds, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => textEnum<EntryType>()();
  TextColumn get title => text()();
  // JSON array of strings
  TextColumn get aliases => text().withDefault(const Constant('[]'))();
  TextColumn get summary => text().withDefault(const Constant(''))();
  // Markdown with [[title]] links
  TextColumn get body => text().withDefault(const Constant(''))();
  TextColumn get status => textEnum<EntryStatus>().withDefault(const Constant('draft'))();
  // JSON array of strings
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  // JSON object of type-specific fields
  TextColumn get fields => text().withDefault(const Constant('{}'))();
  // Relative path inside the app folder, so export/import works across devices
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get created => dateTime()();
  DateTimeColumn get updated => dateTime()();

  /// Sync stamp. Unlike `updated` (what the user sees as "last edited") this also moves when a
  /// rename elsewhere rewrites `[[links]]` in this entry, so sync never misses that change.
  DateTimeColumn get modified => dateTime().withDefault(Constant(DateTime.fromMillisecondsSinceEpoch(0)))();

  @override
  Set<Column> get primaryKey => {id};
}

class Relations extends Table {
  TextColumn get id => text()();
  @ReferenceName('outgoingRelations')
  TextColumn get fromEntry => text().references(Entries, #id, onDelete: KeyAction.cascade)();
  @ReferenceName('incomingRelations')
  TextColumn get toEntry => text().references(Entries, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  // Label shown from the other side, e.g. "ลูกสาวของ" / "พ่อของ"
  TextColumn get inverseType => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get modified => dateTime().withDefault(Constant(DateTime.fromMillisecondsSinceEpoch(0)))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A dated span on the world timeline. One per entry (usually an event, but
/// a birth or founding date on any entry works). Month and day are optional
/// so "year 401" and "year 401, month 3, day 12" are both valid.
class TimelineEvents extends Table {
  TextColumn get entryId => text().references(Entries, #id, onDelete: KeyAction.cascade)();
  IntColumn get startYear => integer()();
  IntColumn get startMonth => integer().nullable()();
  IntColumn get startDay => integer().nullable()();
  IntColumn get endYear => integer().nullable()();
  IntColumn get endMonth => integer().nullable()();
  IntColumn get endDay => integer().nullable()();
  DateTimeColumn get modified => dateTime().withDefault(Constant(DateTime.fromMillisecondsSinceEpoch(0)))();

  @override
  Set<Column> get primaryKey => {entryId};
}

/// Entries (characters, places…) involved in a timeline event.
class EventParticipants extends Table {
  @ReferenceName('participations')
  TextColumn get eventEntryId => text().references(Entries, #id, onDelete: KeyAction.cascade)();
  @ReferenceName('participantOf')
  TextColumn get participantId => text().references(Entries, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {eventEntryId, participantId};
}

/// Records that something was deleted, so a sync can tell "deleted here" from "never seen here".
/// [kind] is 'entry', 'relation' or 'timeline' (the entry whose date was cleared).
class Tombstones extends Table {
  TextColumn get kind => text()();
  TextColumn get recordId => text()();
  TextColumn get worldId => text()();
  DateTimeColumn get deletedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {kind, recordId};
}

@DriftDatabase(tables: [Worlds, Entries, Relations, TimelineEvents, EventParticipants, Tombstones])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  /// For tests: pass an in-memory executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(timelineEvents);
            await m.createTable(eventParticipants);
          }
          if (from < 3) {
            await m.addColumn(worlds, worlds.modified);
            await m.addColumn(worlds, worlds.lastSyncAt);
            await m.addColumn(entries, entries.modified);
            await m.addColumn(relations, relations.modified);
            // From v1 the table was just created above, already including `modified`.
            if (from >= 2) await m.addColumn(timelineEvents, timelineEvents.modified);
            await m.createTable(tombstones);
            // Existing data counts as last changed when it was last edited.
            await customStatement('UPDATE worlds SET modified = created');
            await customStatement('UPDATE entries SET modified = updated');
            await customStatement(
                'UPDATE relations SET modified = COALESCE((SELECT updated FROM entries WHERE entries.id = relations.from_entry), 0)');
            await customStatement(
                'UPDATE timeline_events SET modified = COALESCE((SELECT updated FROM entries WHERE entries.id = timeline_events.entry_id), 0)');
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'nsl_writer_tools.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
