// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $WorldsTable extends Worlds with TableInfo<$WorldsTable, World> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calendarConfigMeta = const VerificationMeta(
    'calendarConfig',
  );
  @override
  late final GeneratedColumn<String> calendarConfig = GeneratedColumn<String>(
    'calendar_config',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedMeta = const VerificationMeta(
    'modified',
  );
  @override
  late final GeneratedColumn<DateTime> modified = GeneratedColumn<DateTime>(
    'modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.fromMillisecondsSinceEpoch(0)),
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    calendarConfig,
    created,
    modified,
    lastSyncAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'worlds';
  @override
  VerificationContext validateIntegrity(
    Insertable<World> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('calendar_config')) {
      context.handle(
        _calendarConfigMeta,
        calendarConfig.isAcceptableOrUnknown(
          data['calendar_config']!,
          _calendarConfigMeta,
        ),
      );
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('modified')) {
      context.handle(
        _modifiedMeta,
        modified.isAcceptableOrUnknown(data['modified']!, _modifiedMeta),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  World map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return World(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      calendarConfig: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar_config'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created'],
      )!,
      modified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
    );
  }

  @override
  $WorldsTable createAlias(String alias) {
    return $WorldsTable(attachedDatabase, alias);
  }
}

class World extends DataClass implements Insertable<World> {
  final String id;
  final String name;
  final String calendarConfig;
  final DateTime created;

  /// Sync stamp: moves whenever the name or calendar changes.
  final DateTime modified;

  /// When this world was last merged with a sync file (null = never).
  final DateTime? lastSyncAt;
  const World({
    required this.id,
    required this.name,
    required this.calendarConfig,
    required this.created,
    required this.modified,
    this.lastSyncAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['calendar_config'] = Variable<String>(calendarConfig);
    map['created'] = Variable<DateTime>(created);
    map['modified'] = Variable<DateTime>(modified);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    return map;
  }

  WorldsCompanion toCompanion(bool nullToAbsent) {
    return WorldsCompanion(
      id: Value(id),
      name: Value(name),
      calendarConfig: Value(calendarConfig),
      created: Value(created),
      modified: Value(modified),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory World.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return World(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      calendarConfig: serializer.fromJson<String>(json['calendarConfig']),
      created: serializer.fromJson<DateTime>(json['created']),
      modified: serializer.fromJson<DateTime>(json['modified']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'calendarConfig': serializer.toJson<String>(calendarConfig),
      'created': serializer.toJson<DateTime>(created),
      'modified': serializer.toJson<DateTime>(modified),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
    };
  }

  World copyWith({
    String? id,
    String? name,
    String? calendarConfig,
    DateTime? created,
    DateTime? modified,
    Value<DateTime?> lastSyncAt = const Value.absent(),
  }) => World(
    id: id ?? this.id,
    name: name ?? this.name,
    calendarConfig: calendarConfig ?? this.calendarConfig,
    created: created ?? this.created,
    modified: modified ?? this.modified,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
  );
  World copyWithCompanion(WorldsCompanion data) {
    return World(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      calendarConfig: data.calendarConfig.present
          ? data.calendarConfig.value
          : this.calendarConfig,
      created: data.created.present ? data.created.value : this.created,
      modified: data.modified.present ? data.modified.value : this.modified,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('World(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('calendarConfig: $calendarConfig, ')
          ..write('created: $created, ')
          ..write('modified: $modified, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, calendarConfig, created, modified, lastSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is World &&
          other.id == this.id &&
          other.name == this.name &&
          other.calendarConfig == this.calendarConfig &&
          other.created == this.created &&
          other.modified == this.modified &&
          other.lastSyncAt == this.lastSyncAt);
}

class WorldsCompanion extends UpdateCompanion<World> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> calendarConfig;
  final Value<DateTime> created;
  final Value<DateTime> modified;
  final Value<DateTime?> lastSyncAt;
  final Value<int> rowid;
  const WorldsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.calendarConfig = const Value.absent(),
    this.created = const Value.absent(),
    this.modified = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorldsCompanion.insert({
    required String id,
    required String name,
    this.calendarConfig = const Value.absent(),
    required DateTime created,
    this.modified = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       created = Value(created);
  static Insertable<World> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? calendarConfig,
    Expression<DateTime>? created,
    Expression<DateTime>? modified,
    Expression<DateTime>? lastSyncAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (calendarConfig != null) 'calendar_config': calendarConfig,
      if (created != null) 'created': created,
      if (modified != null) 'modified': modified,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorldsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? calendarConfig,
    Value<DateTime>? created,
    Value<DateTime>? modified,
    Value<DateTime?>? lastSyncAt,
    Value<int>? rowid,
  }) {
    return WorldsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      calendarConfig: calendarConfig ?? this.calendarConfig,
      created: created ?? this.created,
      modified: modified ?? this.modified,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (calendarConfig.present) {
      map['calendar_config'] = Variable<String>(calendarConfig.value);
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    if (modified.present) {
      map['modified'] = Variable<DateTime>(modified.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorldsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('calendarConfig: $calendarConfig, ')
          ..write('created: $created, ')
          ..write('modified: $modified, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntriesTable extends Entries with TableInfo<$EntriesTable, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES worlds (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<EntryType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EntryType>($EntriesTable.$convertertype);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aliasesMeta = const VerificationMeta(
    'aliases',
  );
  @override
  late final GeneratedColumn<String> aliases = GeneratedColumn<String>(
    'aliases',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<EntryStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('draft'),
      ).withConverter<EntryStatus>($EntriesTable.$converterstatus);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _fieldsMeta = const VerificationMeta('fields');
  @override
  late final GeneratedColumn<String> fields = GeneratedColumn<String>(
    'fields',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedMeta = const VerificationMeta(
    'updated',
  );
  @override
  late final GeneratedColumn<DateTime> updated = GeneratedColumn<DateTime>(
    'updated',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedMeta = const VerificationMeta(
    'modified',
  );
  @override
  late final GeneratedColumn<DateTime> modified = GeneratedColumn<DateTime>(
    'modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.fromMillisecondsSinceEpoch(0)),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    worldId,
    type,
    title,
    aliases,
    summary,
    body,
    status,
    tags,
    fields,
    imagePath,
    created,
    updated,
    modified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Entry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('aliases')) {
      context.handle(
        _aliasesMeta,
        aliases.isAcceptableOrUnknown(data['aliases']!, _aliasesMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('fields')) {
      context.handle(
        _fieldsMeta,
        fields.isAcceptableOrUnknown(data['fields']!, _fieldsMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('updated')) {
      context.handle(
        _updatedMeta,
        updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    if (data.containsKey('modified')) {
      context.handle(
        _modifiedMeta,
        modified.isAcceptableOrUnknown(data['modified']!, _modifiedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}world_id'],
      )!,
      type: $EntriesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      aliases: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aliases'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      status: $EntriesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      fields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fields'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created'],
      )!,
      updated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated'],
      )!,
      modified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified'],
      )!,
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EntryType, String, String> $convertertype =
      const EnumNameConverter<EntryType>(EntryType.values);
  static JsonTypeConverter2<EntryStatus, String, String> $converterstatus =
      const EnumNameConverter<EntryStatus>(EntryStatus.values);
}

class Entry extends DataClass implements Insertable<Entry> {
  final String id;
  final String worldId;
  final EntryType type;
  final String title;
  final String aliases;
  final String summary;
  final String body;
  final EntryStatus status;
  final String tags;
  final String fields;
  final String? imagePath;
  final DateTime created;
  final DateTime updated;

  /// Sync stamp. Unlike `updated` (what the user sees as "last edited") this also moves when a
  /// rename elsewhere rewrites `[[links]]` in this entry, so sync never misses that change.
  final DateTime modified;
  const Entry({
    required this.id,
    required this.worldId,
    required this.type,
    required this.title,
    required this.aliases,
    required this.summary,
    required this.body,
    required this.status,
    required this.tags,
    required this.fields,
    this.imagePath,
    required this.created,
    required this.updated,
    required this.modified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['world_id'] = Variable<String>(worldId);
    {
      map['type'] = Variable<String>($EntriesTable.$convertertype.toSql(type));
    }
    map['title'] = Variable<String>(title);
    map['aliases'] = Variable<String>(aliases);
    map['summary'] = Variable<String>(summary);
    map['body'] = Variable<String>(body);
    {
      map['status'] = Variable<String>(
        $EntriesTable.$converterstatus.toSql(status),
      );
    }
    map['tags'] = Variable<String>(tags);
    map['fields'] = Variable<String>(fields);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['created'] = Variable<DateTime>(created);
    map['updated'] = Variable<DateTime>(updated);
    map['modified'] = Variable<DateTime>(modified);
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      worldId: Value(worldId),
      type: Value(type),
      title: Value(title),
      aliases: Value(aliases),
      summary: Value(summary),
      body: Value(body),
      status: Value(status),
      tags: Value(tags),
      fields: Value(fields),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      created: Value(created),
      updated: Value(updated),
      modified: Value(modified),
    );
  }

  factory Entry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      id: serializer.fromJson<String>(json['id']),
      worldId: serializer.fromJson<String>(json['worldId']),
      type: $EntriesTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      title: serializer.fromJson<String>(json['title']),
      aliases: serializer.fromJson<String>(json['aliases']),
      summary: serializer.fromJson<String>(json['summary']),
      body: serializer.fromJson<String>(json['body']),
      status: $EntriesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      tags: serializer.fromJson<String>(json['tags']),
      fields: serializer.fromJson<String>(json['fields']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      created: serializer.fromJson<DateTime>(json['created']),
      updated: serializer.fromJson<DateTime>(json['updated']),
      modified: serializer.fromJson<DateTime>(json['modified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'worldId': serializer.toJson<String>(worldId),
      'type': serializer.toJson<String>(
        $EntriesTable.$convertertype.toJson(type),
      ),
      'title': serializer.toJson<String>(title),
      'aliases': serializer.toJson<String>(aliases),
      'summary': serializer.toJson<String>(summary),
      'body': serializer.toJson<String>(body),
      'status': serializer.toJson<String>(
        $EntriesTable.$converterstatus.toJson(status),
      ),
      'tags': serializer.toJson<String>(tags),
      'fields': serializer.toJson<String>(fields),
      'imagePath': serializer.toJson<String?>(imagePath),
      'created': serializer.toJson<DateTime>(created),
      'updated': serializer.toJson<DateTime>(updated),
      'modified': serializer.toJson<DateTime>(modified),
    };
  }

  Entry copyWith({
    String? id,
    String? worldId,
    EntryType? type,
    String? title,
    String? aliases,
    String? summary,
    String? body,
    EntryStatus? status,
    String? tags,
    String? fields,
    Value<String?> imagePath = const Value.absent(),
    DateTime? created,
    DateTime? updated,
    DateTime? modified,
  }) => Entry(
    id: id ?? this.id,
    worldId: worldId ?? this.worldId,
    type: type ?? this.type,
    title: title ?? this.title,
    aliases: aliases ?? this.aliases,
    summary: summary ?? this.summary,
    body: body ?? this.body,
    status: status ?? this.status,
    tags: tags ?? this.tags,
    fields: fields ?? this.fields,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    created: created ?? this.created,
    updated: updated ?? this.updated,
    modified: modified ?? this.modified,
  );
  Entry copyWithCompanion(EntriesCompanion data) {
    return Entry(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      aliases: data.aliases.present ? data.aliases.value : this.aliases,
      summary: data.summary.present ? data.summary.value : this.summary,
      body: data.body.present ? data.body.value : this.body,
      status: data.status.present ? data.status.value : this.status,
      tags: data.tags.present ? data.tags.value : this.tags,
      fields: data.fields.present ? data.fields.value : this.fields,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      created: data.created.present ? data.created.value : this.created,
      updated: data.updated.present ? data.updated.value : this.updated,
      modified: data.modified.present ? data.modified.value : this.modified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('aliases: $aliases, ')
          ..write('summary: $summary, ')
          ..write('body: $body, ')
          ..write('status: $status, ')
          ..write('tags: $tags, ')
          ..write('fields: $fields, ')
          ..write('imagePath: $imagePath, ')
          ..write('created: $created, ')
          ..write('updated: $updated, ')
          ..write('modified: $modified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    worldId,
    type,
    title,
    aliases,
    summary,
    body,
    status,
    tags,
    fields,
    imagePath,
    created,
    updated,
    modified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.type == this.type &&
          other.title == this.title &&
          other.aliases == this.aliases &&
          other.summary == this.summary &&
          other.body == this.body &&
          other.status == this.status &&
          other.tags == this.tags &&
          other.fields == this.fields &&
          other.imagePath == this.imagePath &&
          other.created == this.created &&
          other.updated == this.updated &&
          other.modified == this.modified);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<String> id;
  final Value<String> worldId;
  final Value<EntryType> type;
  final Value<String> title;
  final Value<String> aliases;
  final Value<String> summary;
  final Value<String> body;
  final Value<EntryStatus> status;
  final Value<String> tags;
  final Value<String> fields;
  final Value<String?> imagePath;
  final Value<DateTime> created;
  final Value<DateTime> updated;
  final Value<DateTime> modified;
  final Value<int> rowid;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.aliases = const Value.absent(),
    this.summary = const Value.absent(),
    this.body = const Value.absent(),
    this.status = const Value.absent(),
    this.tags = const Value.absent(),
    this.fields = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.created = const Value.absent(),
    this.updated = const Value.absent(),
    this.modified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntriesCompanion.insert({
    required String id,
    required String worldId,
    required EntryType type,
    required String title,
    this.aliases = const Value.absent(),
    this.summary = const Value.absent(),
    this.body = const Value.absent(),
    this.status = const Value.absent(),
    this.tags = const Value.absent(),
    this.fields = const Value.absent(),
    this.imagePath = const Value.absent(),
    required DateTime created,
    required DateTime updated,
    this.modified = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       worldId = Value(worldId),
       type = Value(type),
       title = Value(title),
       created = Value(created),
       updated = Value(updated);
  static Insertable<Entry> custom({
    Expression<String>? id,
    Expression<String>? worldId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? aliases,
    Expression<String>? summary,
    Expression<String>? body,
    Expression<String>? status,
    Expression<String>? tags,
    Expression<String>? fields,
    Expression<String>? imagePath,
    Expression<DateTime>? created,
    Expression<DateTime>? updated,
    Expression<DateTime>? modified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (aliases != null) 'aliases': aliases,
      if (summary != null) 'summary': summary,
      if (body != null) 'body': body,
      if (status != null) 'status': status,
      if (tags != null) 'tags': tags,
      if (fields != null) 'fields': fields,
      if (imagePath != null) 'image_path': imagePath,
      if (created != null) 'created': created,
      if (updated != null) 'updated': updated,
      if (modified != null) 'modified': modified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? worldId,
    Value<EntryType>? type,
    Value<String>? title,
    Value<String>? aliases,
    Value<String>? summary,
    Value<String>? body,
    Value<EntryStatus>? status,
    Value<String>? tags,
    Value<String>? fields,
    Value<String?>? imagePath,
    Value<DateTime>? created,
    Value<DateTime>? updated,
    Value<DateTime>? modified,
    Value<int>? rowid,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      type: type ?? this.type,
      title: title ?? this.title,
      aliases: aliases ?? this.aliases,
      summary: summary ?? this.summary,
      body: body ?? this.body,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      fields: fields ?? this.fields,
      imagePath: imagePath ?? this.imagePath,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      modified: modified ?? this.modified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $EntriesTable.$convertertype.toSql(type.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (aliases.present) {
      map['aliases'] = Variable<String>(aliases.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $EntriesTable.$converterstatus.toSql(status.value),
      );
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (fields.present) {
      map['fields'] = Variable<String>(fields.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    if (updated.present) {
      map['updated'] = Variable<DateTime>(updated.value);
    }
    if (modified.present) {
      map['modified'] = Variable<DateTime>(modified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('aliases: $aliases, ')
          ..write('summary: $summary, ')
          ..write('body: $body, ')
          ..write('status: $status, ')
          ..write('tags: $tags, ')
          ..write('fields: $fields, ')
          ..write('imagePath: $imagePath, ')
          ..write('created: $created, ')
          ..write('updated: $updated, ')
          ..write('modified: $modified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RelationsTable extends Relations
    with TableInfo<$RelationsTable, Relation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RelationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromEntryMeta = const VerificationMeta(
    'fromEntry',
  );
  @override
  late final GeneratedColumn<String> fromEntry = GeneratedColumn<String>(
    'from_entry',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _toEntryMeta = const VerificationMeta(
    'toEntry',
  );
  @override
  late final GeneratedColumn<String> toEntry = GeneratedColumn<String>(
    'to_entry',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inverseTypeMeta = const VerificationMeta(
    'inverseType',
  );
  @override
  late final GeneratedColumn<String> inverseType = GeneratedColumn<String>(
    'inverse_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _modifiedMeta = const VerificationMeta(
    'modified',
  );
  @override
  late final GeneratedColumn<DateTime> modified = GeneratedColumn<DateTime>(
    'modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.fromMillisecondsSinceEpoch(0)),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fromEntry,
    toEntry,
    type,
    inverseType,
    note,
    modified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'relations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Relation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('from_entry')) {
      context.handle(
        _fromEntryMeta,
        fromEntry.isAcceptableOrUnknown(data['from_entry']!, _fromEntryMeta),
      );
    } else if (isInserting) {
      context.missing(_fromEntryMeta);
    }
    if (data.containsKey('to_entry')) {
      context.handle(
        _toEntryMeta,
        toEntry.isAcceptableOrUnknown(data['to_entry']!, _toEntryMeta),
      );
    } else if (isInserting) {
      context.missing(_toEntryMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('inverse_type')) {
      context.handle(
        _inverseTypeMeta,
        inverseType.isAcceptableOrUnknown(
          data['inverse_type']!,
          _inverseTypeMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('modified')) {
      context.handle(
        _modifiedMeta,
        modified.isAcceptableOrUnknown(data['modified']!, _modifiedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Relation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Relation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fromEntry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_entry'],
      )!,
      toEntry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_entry'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      inverseType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inverse_type'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      modified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified'],
      )!,
    );
  }

  @override
  $RelationsTable createAlias(String alias) {
    return $RelationsTable(attachedDatabase, alias);
  }
}

class Relation extends DataClass implements Insertable<Relation> {
  final String id;
  final String fromEntry;
  final String toEntry;
  final String type;
  final String inverseType;
  final String note;
  final DateTime modified;
  const Relation({
    required this.id,
    required this.fromEntry,
    required this.toEntry,
    required this.type,
    required this.inverseType,
    required this.note,
    required this.modified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['from_entry'] = Variable<String>(fromEntry);
    map['to_entry'] = Variable<String>(toEntry);
    map['type'] = Variable<String>(type);
    map['inverse_type'] = Variable<String>(inverseType);
    map['note'] = Variable<String>(note);
    map['modified'] = Variable<DateTime>(modified);
    return map;
  }

  RelationsCompanion toCompanion(bool nullToAbsent) {
    return RelationsCompanion(
      id: Value(id),
      fromEntry: Value(fromEntry),
      toEntry: Value(toEntry),
      type: Value(type),
      inverseType: Value(inverseType),
      note: Value(note),
      modified: Value(modified),
    );
  }

  factory Relation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Relation(
      id: serializer.fromJson<String>(json['id']),
      fromEntry: serializer.fromJson<String>(json['fromEntry']),
      toEntry: serializer.fromJson<String>(json['toEntry']),
      type: serializer.fromJson<String>(json['type']),
      inverseType: serializer.fromJson<String>(json['inverseType']),
      note: serializer.fromJson<String>(json['note']),
      modified: serializer.fromJson<DateTime>(json['modified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fromEntry': serializer.toJson<String>(fromEntry),
      'toEntry': serializer.toJson<String>(toEntry),
      'type': serializer.toJson<String>(type),
      'inverseType': serializer.toJson<String>(inverseType),
      'note': serializer.toJson<String>(note),
      'modified': serializer.toJson<DateTime>(modified),
    };
  }

  Relation copyWith({
    String? id,
    String? fromEntry,
    String? toEntry,
    String? type,
    String? inverseType,
    String? note,
    DateTime? modified,
  }) => Relation(
    id: id ?? this.id,
    fromEntry: fromEntry ?? this.fromEntry,
    toEntry: toEntry ?? this.toEntry,
    type: type ?? this.type,
    inverseType: inverseType ?? this.inverseType,
    note: note ?? this.note,
    modified: modified ?? this.modified,
  );
  Relation copyWithCompanion(RelationsCompanion data) {
    return Relation(
      id: data.id.present ? data.id.value : this.id,
      fromEntry: data.fromEntry.present ? data.fromEntry.value : this.fromEntry,
      toEntry: data.toEntry.present ? data.toEntry.value : this.toEntry,
      type: data.type.present ? data.type.value : this.type,
      inverseType: data.inverseType.present
          ? data.inverseType.value
          : this.inverseType,
      note: data.note.present ? data.note.value : this.note,
      modified: data.modified.present ? data.modified.value : this.modified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Relation(')
          ..write('id: $id, ')
          ..write('fromEntry: $fromEntry, ')
          ..write('toEntry: $toEntry, ')
          ..write('type: $type, ')
          ..write('inverseType: $inverseType, ')
          ..write('note: $note, ')
          ..write('modified: $modified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, fromEntry, toEntry, type, inverseType, note, modified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Relation &&
          other.id == this.id &&
          other.fromEntry == this.fromEntry &&
          other.toEntry == this.toEntry &&
          other.type == this.type &&
          other.inverseType == this.inverseType &&
          other.note == this.note &&
          other.modified == this.modified);
}

class RelationsCompanion extends UpdateCompanion<Relation> {
  final Value<String> id;
  final Value<String> fromEntry;
  final Value<String> toEntry;
  final Value<String> type;
  final Value<String> inverseType;
  final Value<String> note;
  final Value<DateTime> modified;
  final Value<int> rowid;
  const RelationsCompanion({
    this.id = const Value.absent(),
    this.fromEntry = const Value.absent(),
    this.toEntry = const Value.absent(),
    this.type = const Value.absent(),
    this.inverseType = const Value.absent(),
    this.note = const Value.absent(),
    this.modified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RelationsCompanion.insert({
    required String id,
    required String fromEntry,
    required String toEntry,
    required String type,
    this.inverseType = const Value.absent(),
    this.note = const Value.absent(),
    this.modified = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fromEntry = Value(fromEntry),
       toEntry = Value(toEntry),
       type = Value(type);
  static Insertable<Relation> custom({
    Expression<String>? id,
    Expression<String>? fromEntry,
    Expression<String>? toEntry,
    Expression<String>? type,
    Expression<String>? inverseType,
    Expression<String>? note,
    Expression<DateTime>? modified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromEntry != null) 'from_entry': fromEntry,
      if (toEntry != null) 'to_entry': toEntry,
      if (type != null) 'type': type,
      if (inverseType != null) 'inverse_type': inverseType,
      if (note != null) 'note': note,
      if (modified != null) 'modified': modified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RelationsCompanion copyWith({
    Value<String>? id,
    Value<String>? fromEntry,
    Value<String>? toEntry,
    Value<String>? type,
    Value<String>? inverseType,
    Value<String>? note,
    Value<DateTime>? modified,
    Value<int>? rowid,
  }) {
    return RelationsCompanion(
      id: id ?? this.id,
      fromEntry: fromEntry ?? this.fromEntry,
      toEntry: toEntry ?? this.toEntry,
      type: type ?? this.type,
      inverseType: inverseType ?? this.inverseType,
      note: note ?? this.note,
      modified: modified ?? this.modified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fromEntry.present) {
      map['from_entry'] = Variable<String>(fromEntry.value);
    }
    if (toEntry.present) {
      map['to_entry'] = Variable<String>(toEntry.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (inverseType.present) {
      map['inverse_type'] = Variable<String>(inverseType.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (modified.present) {
      map['modified'] = Variable<DateTime>(modified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RelationsCompanion(')
          ..write('id: $id, ')
          ..write('fromEntry: $fromEntry, ')
          ..write('toEntry: $toEntry, ')
          ..write('type: $type, ')
          ..write('inverseType: $inverseType, ')
          ..write('note: $note, ')
          ..write('modified: $modified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimelineEventsTable extends TimelineEvents
    with TableInfo<$TimelineEventsTable, TimelineEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimelineEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _startYearMeta = const VerificationMeta(
    'startYear',
  );
  @override
  late final GeneratedColumn<int> startYear = GeneratedColumn<int>(
    'start_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMonthMeta = const VerificationMeta(
    'startMonth',
  );
  @override
  late final GeneratedColumn<int> startMonth = GeneratedColumn<int>(
    'start_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDayMeta = const VerificationMeta(
    'startDay',
  );
  @override
  late final GeneratedColumn<int> startDay = GeneratedColumn<int>(
    'start_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endYearMeta = const VerificationMeta(
    'endYear',
  );
  @override
  late final GeneratedColumn<int> endYear = GeneratedColumn<int>(
    'end_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endMonthMeta = const VerificationMeta(
    'endMonth',
  );
  @override
  late final GeneratedColumn<int> endMonth = GeneratedColumn<int>(
    'end_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDayMeta = const VerificationMeta('endDay');
  @override
  late final GeneratedColumn<int> endDay = GeneratedColumn<int>(
    'end_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedMeta = const VerificationMeta(
    'modified',
  );
  @override
  late final GeneratedColumn<DateTime> modified = GeneratedColumn<DateTime>(
    'modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.fromMillisecondsSinceEpoch(0)),
  );
  @override
  List<GeneratedColumn> get $columns => [
    entryId,
    startYear,
    startMonth,
    startDay,
    endYear,
    endMonth,
    endDay,
    modified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timeline_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimelineEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('start_year')) {
      context.handle(
        _startYearMeta,
        startYear.isAcceptableOrUnknown(data['start_year']!, _startYearMeta),
      );
    } else if (isInserting) {
      context.missing(_startYearMeta);
    }
    if (data.containsKey('start_month')) {
      context.handle(
        _startMonthMeta,
        startMonth.isAcceptableOrUnknown(data['start_month']!, _startMonthMeta),
      );
    }
    if (data.containsKey('start_day')) {
      context.handle(
        _startDayMeta,
        startDay.isAcceptableOrUnknown(data['start_day']!, _startDayMeta),
      );
    }
    if (data.containsKey('end_year')) {
      context.handle(
        _endYearMeta,
        endYear.isAcceptableOrUnknown(data['end_year']!, _endYearMeta),
      );
    }
    if (data.containsKey('end_month')) {
      context.handle(
        _endMonthMeta,
        endMonth.isAcceptableOrUnknown(data['end_month']!, _endMonthMeta),
      );
    }
    if (data.containsKey('end_day')) {
      context.handle(
        _endDayMeta,
        endDay.isAcceptableOrUnknown(data['end_day']!, _endDayMeta),
      );
    }
    if (data.containsKey('modified')) {
      context.handle(
        _modifiedMeta,
        modified.isAcceptableOrUnknown(data['modified']!, _modifiedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId};
  @override
  TimelineEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimelineEvent(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      startYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_year'],
      )!,
      startMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_month'],
      ),
      startDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_day'],
      ),
      endYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_year'],
      ),
      endMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_month'],
      ),
      endDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_day'],
      ),
      modified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified'],
      )!,
    );
  }

  @override
  $TimelineEventsTable createAlias(String alias) {
    return $TimelineEventsTable(attachedDatabase, alias);
  }
}

class TimelineEvent extends DataClass implements Insertable<TimelineEvent> {
  final String entryId;
  final int startYear;
  final int? startMonth;
  final int? startDay;
  final int? endYear;
  final int? endMonth;
  final int? endDay;
  final DateTime modified;
  const TimelineEvent({
    required this.entryId,
    required this.startYear,
    this.startMonth,
    this.startDay,
    this.endYear,
    this.endMonth,
    this.endDay,
    required this.modified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['start_year'] = Variable<int>(startYear);
    if (!nullToAbsent || startMonth != null) {
      map['start_month'] = Variable<int>(startMonth);
    }
    if (!nullToAbsent || startDay != null) {
      map['start_day'] = Variable<int>(startDay);
    }
    if (!nullToAbsent || endYear != null) {
      map['end_year'] = Variable<int>(endYear);
    }
    if (!nullToAbsent || endMonth != null) {
      map['end_month'] = Variable<int>(endMonth);
    }
    if (!nullToAbsent || endDay != null) {
      map['end_day'] = Variable<int>(endDay);
    }
    map['modified'] = Variable<DateTime>(modified);
    return map;
  }

  TimelineEventsCompanion toCompanion(bool nullToAbsent) {
    return TimelineEventsCompanion(
      entryId: Value(entryId),
      startYear: Value(startYear),
      startMonth: startMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(startMonth),
      startDay: startDay == null && nullToAbsent
          ? const Value.absent()
          : Value(startDay),
      endYear: endYear == null && nullToAbsent
          ? const Value.absent()
          : Value(endYear),
      endMonth: endMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(endMonth),
      endDay: endDay == null && nullToAbsent
          ? const Value.absent()
          : Value(endDay),
      modified: Value(modified),
    );
  }

  factory TimelineEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimelineEvent(
      entryId: serializer.fromJson<String>(json['entryId']),
      startYear: serializer.fromJson<int>(json['startYear']),
      startMonth: serializer.fromJson<int?>(json['startMonth']),
      startDay: serializer.fromJson<int?>(json['startDay']),
      endYear: serializer.fromJson<int?>(json['endYear']),
      endMonth: serializer.fromJson<int?>(json['endMonth']),
      endDay: serializer.fromJson<int?>(json['endDay']),
      modified: serializer.fromJson<DateTime>(json['modified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<String>(entryId),
      'startYear': serializer.toJson<int>(startYear),
      'startMonth': serializer.toJson<int?>(startMonth),
      'startDay': serializer.toJson<int?>(startDay),
      'endYear': serializer.toJson<int?>(endYear),
      'endMonth': serializer.toJson<int?>(endMonth),
      'endDay': serializer.toJson<int?>(endDay),
      'modified': serializer.toJson<DateTime>(modified),
    };
  }

  TimelineEvent copyWith({
    String? entryId,
    int? startYear,
    Value<int?> startMonth = const Value.absent(),
    Value<int?> startDay = const Value.absent(),
    Value<int?> endYear = const Value.absent(),
    Value<int?> endMonth = const Value.absent(),
    Value<int?> endDay = const Value.absent(),
    DateTime? modified,
  }) => TimelineEvent(
    entryId: entryId ?? this.entryId,
    startYear: startYear ?? this.startYear,
    startMonth: startMonth.present ? startMonth.value : this.startMonth,
    startDay: startDay.present ? startDay.value : this.startDay,
    endYear: endYear.present ? endYear.value : this.endYear,
    endMonth: endMonth.present ? endMonth.value : this.endMonth,
    endDay: endDay.present ? endDay.value : this.endDay,
    modified: modified ?? this.modified,
  );
  TimelineEvent copyWithCompanion(TimelineEventsCompanion data) {
    return TimelineEvent(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      startYear: data.startYear.present ? data.startYear.value : this.startYear,
      startMonth: data.startMonth.present
          ? data.startMonth.value
          : this.startMonth,
      startDay: data.startDay.present ? data.startDay.value : this.startDay,
      endYear: data.endYear.present ? data.endYear.value : this.endYear,
      endMonth: data.endMonth.present ? data.endMonth.value : this.endMonth,
      endDay: data.endDay.present ? data.endDay.value : this.endDay,
      modified: data.modified.present ? data.modified.value : this.modified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimelineEvent(')
          ..write('entryId: $entryId, ')
          ..write('startYear: $startYear, ')
          ..write('startMonth: $startMonth, ')
          ..write('startDay: $startDay, ')
          ..write('endYear: $endYear, ')
          ..write('endMonth: $endMonth, ')
          ..write('endDay: $endDay, ')
          ..write('modified: $modified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    entryId,
    startYear,
    startMonth,
    startDay,
    endYear,
    endMonth,
    endDay,
    modified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimelineEvent &&
          other.entryId == this.entryId &&
          other.startYear == this.startYear &&
          other.startMonth == this.startMonth &&
          other.startDay == this.startDay &&
          other.endYear == this.endYear &&
          other.endMonth == this.endMonth &&
          other.endDay == this.endDay &&
          other.modified == this.modified);
}

class TimelineEventsCompanion extends UpdateCompanion<TimelineEvent> {
  final Value<String> entryId;
  final Value<int> startYear;
  final Value<int?> startMonth;
  final Value<int?> startDay;
  final Value<int?> endYear;
  final Value<int?> endMonth;
  final Value<int?> endDay;
  final Value<DateTime> modified;
  final Value<int> rowid;
  const TimelineEventsCompanion({
    this.entryId = const Value.absent(),
    this.startYear = const Value.absent(),
    this.startMonth = const Value.absent(),
    this.startDay = const Value.absent(),
    this.endYear = const Value.absent(),
    this.endMonth = const Value.absent(),
    this.endDay = const Value.absent(),
    this.modified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimelineEventsCompanion.insert({
    required String entryId,
    required int startYear,
    this.startMonth = const Value.absent(),
    this.startDay = const Value.absent(),
    this.endYear = const Value.absent(),
    this.endMonth = const Value.absent(),
    this.endDay = const Value.absent(),
    this.modified = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       startYear = Value(startYear);
  static Insertable<TimelineEvent> custom({
    Expression<String>? entryId,
    Expression<int>? startYear,
    Expression<int>? startMonth,
    Expression<int>? startDay,
    Expression<int>? endYear,
    Expression<int>? endMonth,
    Expression<int>? endDay,
    Expression<DateTime>? modified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (startYear != null) 'start_year': startYear,
      if (startMonth != null) 'start_month': startMonth,
      if (startDay != null) 'start_day': startDay,
      if (endYear != null) 'end_year': endYear,
      if (endMonth != null) 'end_month': endMonth,
      if (endDay != null) 'end_day': endDay,
      if (modified != null) 'modified': modified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimelineEventsCompanion copyWith({
    Value<String>? entryId,
    Value<int>? startYear,
    Value<int?>? startMonth,
    Value<int?>? startDay,
    Value<int?>? endYear,
    Value<int?>? endMonth,
    Value<int?>? endDay,
    Value<DateTime>? modified,
    Value<int>? rowid,
  }) {
    return TimelineEventsCompanion(
      entryId: entryId ?? this.entryId,
      startYear: startYear ?? this.startYear,
      startMonth: startMonth ?? this.startMonth,
      startDay: startDay ?? this.startDay,
      endYear: endYear ?? this.endYear,
      endMonth: endMonth ?? this.endMonth,
      endDay: endDay ?? this.endDay,
      modified: modified ?? this.modified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (startYear.present) {
      map['start_year'] = Variable<int>(startYear.value);
    }
    if (startMonth.present) {
      map['start_month'] = Variable<int>(startMonth.value);
    }
    if (startDay.present) {
      map['start_day'] = Variable<int>(startDay.value);
    }
    if (endYear.present) {
      map['end_year'] = Variable<int>(endYear.value);
    }
    if (endMonth.present) {
      map['end_month'] = Variable<int>(endMonth.value);
    }
    if (endDay.present) {
      map['end_day'] = Variable<int>(endDay.value);
    }
    if (modified.present) {
      map['modified'] = Variable<DateTime>(modified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimelineEventsCompanion(')
          ..write('entryId: $entryId, ')
          ..write('startYear: $startYear, ')
          ..write('startMonth: $startMonth, ')
          ..write('startDay: $startDay, ')
          ..write('endYear: $endYear, ')
          ..write('endMonth: $endMonth, ')
          ..write('endDay: $endDay, ')
          ..write('modified: $modified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventParticipantsTable extends EventParticipants
    with TableInfo<$EventParticipantsTable, EventParticipant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventParticipantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventEntryIdMeta = const VerificationMeta(
    'eventEntryId',
  );
  @override
  late final GeneratedColumn<String> eventEntryId = GeneratedColumn<String>(
    'event_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _participantIdMeta = const VerificationMeta(
    'participantId',
  );
  @override
  late final GeneratedColumn<String> participantId = GeneratedColumn<String>(
    'participant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entries (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [eventEntryId, participantId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_participants';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventParticipant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_entry_id')) {
      context.handle(
        _eventEntryIdMeta,
        eventEntryId.isAcceptableOrUnknown(
          data['event_entry_id']!,
          _eventEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eventEntryIdMeta);
    }
    if (data.containsKey('participant_id')) {
      context.handle(
        _participantIdMeta,
        participantId.isAcceptableOrUnknown(
          data['participant_id']!,
          _participantIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventEntryId, participantId};
  @override
  EventParticipant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventParticipant(
      eventEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_entry_id'],
      )!,
      participantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_id'],
      )!,
    );
  }

  @override
  $EventParticipantsTable createAlias(String alias) {
    return $EventParticipantsTable(attachedDatabase, alias);
  }
}

class EventParticipant extends DataClass
    implements Insertable<EventParticipant> {
  final String eventEntryId;
  final String participantId;
  const EventParticipant({
    required this.eventEntryId,
    required this.participantId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_entry_id'] = Variable<String>(eventEntryId);
    map['participant_id'] = Variable<String>(participantId);
    return map;
  }

  EventParticipantsCompanion toCompanion(bool nullToAbsent) {
    return EventParticipantsCompanion(
      eventEntryId: Value(eventEntryId),
      participantId: Value(participantId),
    );
  }

  factory EventParticipant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventParticipant(
      eventEntryId: serializer.fromJson<String>(json['eventEntryId']),
      participantId: serializer.fromJson<String>(json['participantId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventEntryId': serializer.toJson<String>(eventEntryId),
      'participantId': serializer.toJson<String>(participantId),
    };
  }

  EventParticipant copyWith({String? eventEntryId, String? participantId}) =>
      EventParticipant(
        eventEntryId: eventEntryId ?? this.eventEntryId,
        participantId: participantId ?? this.participantId,
      );
  EventParticipant copyWithCompanion(EventParticipantsCompanion data) {
    return EventParticipant(
      eventEntryId: data.eventEntryId.present
          ? data.eventEntryId.value
          : this.eventEntryId,
      participantId: data.participantId.present
          ? data.participantId.value
          : this.participantId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventParticipant(')
          ..write('eventEntryId: $eventEntryId, ')
          ..write('participantId: $participantId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(eventEntryId, participantId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventParticipant &&
          other.eventEntryId == this.eventEntryId &&
          other.participantId == this.participantId);
}

class EventParticipantsCompanion extends UpdateCompanion<EventParticipant> {
  final Value<String> eventEntryId;
  final Value<String> participantId;
  final Value<int> rowid;
  const EventParticipantsCompanion({
    this.eventEntryId = const Value.absent(),
    this.participantId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventParticipantsCompanion.insert({
    required String eventEntryId,
    required String participantId,
    this.rowid = const Value.absent(),
  }) : eventEntryId = Value(eventEntryId),
       participantId = Value(participantId);
  static Insertable<EventParticipant> custom({
    Expression<String>? eventEntryId,
    Expression<String>? participantId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventEntryId != null) 'event_entry_id': eventEntryId,
      if (participantId != null) 'participant_id': participantId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventParticipantsCompanion copyWith({
    Value<String>? eventEntryId,
    Value<String>? participantId,
    Value<int>? rowid,
  }) {
    return EventParticipantsCompanion(
      eventEntryId: eventEntryId ?? this.eventEntryId,
      participantId: participantId ?? this.participantId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventEntryId.present) {
      map['event_entry_id'] = Variable<String>(eventEntryId.value);
    }
    if (participantId.present) {
      map['participant_id'] = Variable<String>(participantId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventParticipantsCompanion(')
          ..write('eventEntryId: $eventEntryId, ')
          ..write('participantId: $participantId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TombstonesTable extends Tombstones
    with TableInfo<$TombstonesTable, Tombstone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TombstonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [kind, recordId, worldId, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tombstones';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tombstone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, recordId};
  @override
  Tombstone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tombstone(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}world_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $TombstonesTable createAlias(String alias) {
    return $TombstonesTable(attachedDatabase, alias);
  }
}

class Tombstone extends DataClass implements Insertable<Tombstone> {
  final String kind;
  final String recordId;
  final String worldId;
  final DateTime deletedAt;
  const Tombstone({
    required this.kind,
    required this.recordId,
    required this.worldId,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['record_id'] = Variable<String>(recordId);
    map['world_id'] = Variable<String>(worldId);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  TombstonesCompanion toCompanion(bool nullToAbsent) {
    return TombstonesCompanion(
      kind: Value(kind),
      recordId: Value(recordId),
      worldId: Value(worldId),
      deletedAt: Value(deletedAt),
    );
  }

  factory Tombstone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tombstone(
      kind: serializer.fromJson<String>(json['kind']),
      recordId: serializer.fromJson<String>(json['recordId']),
      worldId: serializer.fromJson<String>(json['worldId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'recordId': serializer.toJson<String>(recordId),
      'worldId': serializer.toJson<String>(worldId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  Tombstone copyWith({
    String? kind,
    String? recordId,
    String? worldId,
    DateTime? deletedAt,
  }) => Tombstone(
    kind: kind ?? this.kind,
    recordId: recordId ?? this.recordId,
    worldId: worldId ?? this.worldId,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  Tombstone copyWithCompanion(TombstonesCompanion data) {
    return Tombstone(
      kind: data.kind.present ? data.kind.value : this.kind,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tombstone(')
          ..write('kind: $kind, ')
          ..write('recordId: $recordId, ')
          ..write('worldId: $worldId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, recordId, worldId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tombstone &&
          other.kind == this.kind &&
          other.recordId == this.recordId &&
          other.worldId == this.worldId &&
          other.deletedAt == this.deletedAt);
}

class TombstonesCompanion extends UpdateCompanion<Tombstone> {
  final Value<String> kind;
  final Value<String> recordId;
  final Value<String> worldId;
  final Value<DateTime> deletedAt;
  final Value<int> rowid;
  const TombstonesCompanion({
    this.kind = const Value.absent(),
    this.recordId = const Value.absent(),
    this.worldId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TombstonesCompanion.insert({
    required String kind,
    required String recordId,
    required String worldId,
    required DateTime deletedAt,
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       recordId = Value(recordId),
       worldId = Value(worldId),
       deletedAt = Value(deletedAt);
  static Insertable<Tombstone> custom({
    Expression<String>? kind,
    Expression<String>? recordId,
    Expression<String>? worldId,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (recordId != null) 'record_id': recordId,
      if (worldId != null) 'world_id': worldId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TombstonesCompanion copyWith({
    Value<String>? kind,
    Value<String>? recordId,
    Value<String>? worldId,
    Value<DateTime>? deletedAt,
    Value<int>? rowid,
  }) {
    return TombstonesCompanion(
      kind: kind ?? this.kind,
      recordId: recordId ?? this.recordId,
      worldId: worldId ?? this.worldId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TombstonesCompanion(')
          ..write('kind: $kind, ')
          ..write('recordId: $recordId, ')
          ..write('worldId: $worldId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WorldsTable worlds = $WorldsTable(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $RelationsTable relations = $RelationsTable(this);
  late final $TimelineEventsTable timelineEvents = $TimelineEventsTable(this);
  late final $EventParticipantsTable eventParticipants =
      $EventParticipantsTable(this);
  late final $TombstonesTable tombstones = $TombstonesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    worlds,
    entries,
    relations,
    timelineEvents,
    eventParticipants,
    tombstones,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'worlds',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('relations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('relations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('timeline_events', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('event_participants', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('event_participants', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$WorldsTableCreateCompanionBuilder =
    WorldsCompanion Function({
      required String id,
      required String name,
      Value<String> calendarConfig,
      required DateTime created,
      Value<DateTime> modified,
      Value<DateTime?> lastSyncAt,
      Value<int> rowid,
    });
typedef $$WorldsTableUpdateCompanionBuilder =
    WorldsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> calendarConfig,
      Value<DateTime> created,
      Value<DateTime> modified,
      Value<DateTime?> lastSyncAt,
      Value<int> rowid,
    });

final class $$WorldsTableReferences
    extends BaseReferences<_$AppDatabase, $WorldsTable, World> {
  $$WorldsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EntriesTable, List<Entry>> _entriesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.entries,
    aliasName: 'worlds__id__entries__world_id',
  );

  $$EntriesTableProcessedTableManager get entriesRefs {
    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.worldId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_entriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorldsTableFilterComposer
    extends Composer<_$AppDatabase, $WorldsTable> {
  $$WorldsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calendarConfig => $composableBuilder(
    column: $table.calendarConfig,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> entriesRefs(
    Expression<bool> Function($$EntriesTableFilterComposer f) f,
  ) {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorldsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorldsTable> {
  $$WorldsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calendarConfig => $composableBuilder(
    column: $table.calendarConfig,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorldsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorldsTable> {
  $$WorldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get calendarConfig => $composableBuilder(
    column: $table.calendarConfig,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<DateTime> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  Expression<T> entriesRefs<T extends Object>(
    Expression<T> Function($$EntriesTableAnnotationComposer a) f,
  ) {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorldsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorldsTable,
          World,
          $$WorldsTableFilterComposer,
          $$WorldsTableOrderingComposer,
          $$WorldsTableAnnotationComposer,
          $$WorldsTableCreateCompanionBuilder,
          $$WorldsTableUpdateCompanionBuilder,
          (World, $$WorldsTableReferences),
          World,
          PrefetchHooks Function({bool entriesRefs})
        > {
  $$WorldsTableTableManager(_$AppDatabase db, $WorldsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorldsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorldsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorldsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> calendarConfig = const Value.absent(),
                Value<DateTime> created = const Value.absent(),
                Value<DateTime> modified = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorldsCompanion(
                id: id,
                name: name,
                calendarConfig: calendarConfig,
                created: created,
                modified: modified,
                lastSyncAt: lastSyncAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> calendarConfig = const Value.absent(),
                required DateTime created,
                Value<DateTime> modified = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorldsCompanion.insert(
                id: id,
                name: name,
                calendarConfig: calendarConfig,
                created: created,
                modified: modified,
                lastSyncAt: lastSyncAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorldsTable, World>(table),
                  $$WorldsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (entriesRefs) db.entries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (entriesRefs)
                    await $_getPrefetchedData<World, $WorldsTable, Entry>(
                      currentTable: table,
                      referencedTable: $$WorldsTableReferences
                          ._entriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$WorldsTableReferences(db, table, p0).entriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.worldId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WorldsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorldsTable,
      World,
      $$WorldsTableFilterComposer,
      $$WorldsTableOrderingComposer,
      $$WorldsTableAnnotationComposer,
      $$WorldsTableCreateCompanionBuilder,
      $$WorldsTableUpdateCompanionBuilder,
      (World, $$WorldsTableReferences),
      World,
      PrefetchHooks Function({bool entriesRefs})
    >;
typedef $$EntriesTableCreateCompanionBuilder =
    EntriesCompanion Function({
      required String id,
      required String worldId,
      required EntryType type,
      required String title,
      Value<String> aliases,
      Value<String> summary,
      Value<String> body,
      Value<EntryStatus> status,
      Value<String> tags,
      Value<String> fields,
      Value<String?> imagePath,
      required DateTime created,
      required DateTime updated,
      Value<DateTime> modified,
      Value<int> rowid,
    });
typedef $$EntriesTableUpdateCompanionBuilder =
    EntriesCompanion Function({
      Value<String> id,
      Value<String> worldId,
      Value<EntryType> type,
      Value<String> title,
      Value<String> aliases,
      Value<String> summary,
      Value<String> body,
      Value<EntryStatus> status,
      Value<String> tags,
      Value<String> fields,
      Value<String?> imagePath,
      Value<DateTime> created,
      Value<DateTime> updated,
      Value<DateTime> modified,
      Value<int> rowid,
    });

final class $$EntriesTableReferences
    extends BaseReferences<_$AppDatabase, $EntriesTable, Entry> {
  $$EntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorldsTable _worldIdTable(_$AppDatabase db) =>
      db.worlds.createAlias('entries__world_id__worlds__id');

  $$WorldsTableProcessedTableManager get worldId {
    final $_column = $_itemColumn<String>('world_id')!;

    final manager = $$WorldsTableTableManager(
      $_db,
      $_db.worlds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_worldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RelationsTable, List<Relation>>
  _outgoingRelationsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.relations,
    aliasName: 'entries__id__relations__from_entry',
  );

  $$RelationsTableProcessedTableManager get outgoingRelations {
    final manager = $$RelationsTableTableManager(
      $_db,
      $_db.relations,
    ).filter((f) => f.fromEntry.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_outgoingRelationsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RelationsTable, List<Relation>>
  _incomingRelationsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.relations,
    aliasName: 'entries__id__relations__to_entry',
  );

  $$RelationsTableProcessedTableManager get incomingRelations {
    final manager = $$RelationsTableTableManager(
      $_db,
      $_db.relations,
    ).filter((f) => f.toEntry.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_incomingRelationsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TimelineEventsTable, List<TimelineEvent>>
  _timelineEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.timelineEvents,
    aliasName: 'entries__id__timeline_events__entry_id',
  );

  $$TimelineEventsTableProcessedTableManager get timelineEventsRefs {
    final manager = $$TimelineEventsTableTableManager(
      $_db,
      $_db.timelineEvents,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_timelineEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventParticipantsTable, List<EventParticipant>>
  _participationsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventParticipants,
    aliasName: 'entries__id__event_participants__event_entry_id',
  );

  $$EventParticipantsTableProcessedTableManager get participations {
    final manager = $$EventParticipantsTableTableManager(
      $_db,
      $_db.eventParticipants,
    ).filter((f) => f.eventEntryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_participationsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventParticipantsTable, List<EventParticipant>>
  _participantOfTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventParticipants,
    aliasName: 'entries__id__event_participants__participant_id',
  );

  $$EventParticipantsTableProcessedTableManager get participantOf {
    final manager = $$EventParticipantsTableTableManager(
      $_db,
      $_db.eventParticipants,
    ).filter((f) => f.participantId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_participantOfTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EntryType, EntryType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aliases => $composableBuilder(
    column: $table.aliases,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EntryStatus, EntryStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fields => $composableBuilder(
    column: $table.fields,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnFilters(column),
  );

  $$WorldsTableFilterComposer get worldId {
    final $$WorldsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableFilterComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> outgoingRelations(
    Expression<bool> Function($$RelationsTableFilterComposer f) f,
  ) {
    final $$RelationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.relations,
      getReferencedColumn: (t) => t.fromEntry,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RelationsTableFilterComposer(
            $db: $db,
            $table: $db.relations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> incomingRelations(
    Expression<bool> Function($$RelationsTableFilterComposer f) f,
  ) {
    final $$RelationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.relations,
      getReferencedColumn: (t) => t.toEntry,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RelationsTableFilterComposer(
            $db: $db,
            $table: $db.relations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> timelineEventsRefs(
    Expression<bool> Function($$TimelineEventsTableFilterComposer f) f,
  ) {
    final $$TimelineEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timelineEvents,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelineEventsTableFilterComposer(
            $db: $db,
            $table: $db.timelineEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> participations(
    Expression<bool> Function($$EventParticipantsTableFilterComposer f) f,
  ) {
    final $$EventParticipantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventParticipants,
      getReferencedColumn: (t) => t.eventEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventParticipantsTableFilterComposer(
            $db: $db,
            $table: $db.eventParticipants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> participantOf(
    Expression<bool> Function($$EventParticipantsTableFilterComposer f) f,
  ) {
    final $$EventParticipantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventParticipants,
      getReferencedColumn: (t) => t.participantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventParticipantsTableFilterComposer(
            $db: $db,
            $table: $db.eventParticipants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aliases => $composableBuilder(
    column: $table.aliases,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fields => $composableBuilder(
    column: $table.fields,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorldsTableOrderingComposer get worldId {
    final $$WorldsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableOrderingComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EntryType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get aliases =>
      $composableBuilder(column: $table.aliases, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EntryStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get fields =>
      $composableBuilder(column: $table.fields, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<DateTime> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);

  GeneratedColumn<DateTime> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  $$WorldsTableAnnotationComposer get worldId {
    final $$WorldsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableAnnotationComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> outgoingRelations<T extends Object>(
    Expression<T> Function($$RelationsTableAnnotationComposer a) f,
  ) {
    final $$RelationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.relations,
      getReferencedColumn: (t) => t.fromEntry,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RelationsTableAnnotationComposer(
            $db: $db,
            $table: $db.relations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> incomingRelations<T extends Object>(
    Expression<T> Function($$RelationsTableAnnotationComposer a) f,
  ) {
    final $$RelationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.relations,
      getReferencedColumn: (t) => t.toEntry,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RelationsTableAnnotationComposer(
            $db: $db,
            $table: $db.relations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> timelineEventsRefs<T extends Object>(
    Expression<T> Function($$TimelineEventsTableAnnotationComposer a) f,
  ) {
    final $$TimelineEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timelineEvents,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelineEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.timelineEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> participations<T extends Object>(
    Expression<T> Function($$EventParticipantsTableAnnotationComposer a) f,
  ) {
    final $$EventParticipantsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.eventParticipants,
          getReferencedColumn: (t) => t.eventEntryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EventParticipantsTableAnnotationComposer(
                $db: $db,
                $table: $db.eventParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> participantOf<T extends Object>(
    Expression<T> Function($$EventParticipantsTableAnnotationComposer a) f,
  ) {
    final $$EventParticipantsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.eventParticipants,
          getReferencedColumn: (t) => t.participantId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EventParticipantsTableAnnotationComposer(
                $db: $db,
                $table: $db.eventParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntriesTable,
          Entry,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (Entry, $$EntriesTableReferences),
          Entry,
          PrefetchHooks Function({
            bool worldId,
            bool outgoingRelations,
            bool incomingRelations,
            bool timelineEventsRefs,
            bool participations,
            bool participantOf,
          })
        > {
  $$EntriesTableTableManager(_$AppDatabase db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> worldId = const Value.absent(),
                Value<EntryType> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> aliases = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<EntryStatus> status = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> fields = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<DateTime> created = const Value.absent(),
                Value<DateTime> updated = const Value.absent(),
                Value<DateTime> modified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                worldId: worldId,
                type: type,
                title: title,
                aliases: aliases,
                summary: summary,
                body: body,
                status: status,
                tags: tags,
                fields: fields,
                imagePath: imagePath,
                created: created,
                updated: updated,
                modified: modified,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String worldId,
                required EntryType type,
                required String title,
                Value<String> aliases = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<EntryStatus> status = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> fields = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                required DateTime created,
                required DateTime updated,
                Value<DateTime> modified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion.insert(
                id: id,
                worldId: worldId,
                type: type,
                title: title,
                aliases: aliases,
                summary: summary,
                body: body,
                status: status,
                tags: tags,
                fields: fields,
                imagePath: imagePath,
                created: created,
                updated: updated,
                modified: modified,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntriesTable, Entry>(table),
                  $$EntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                worldId = false,
                outgoingRelations = false,
                incomingRelations = false,
                timelineEventsRefs = false,
                participations = false,
                participantOf = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (outgoingRelations) db.relations,
                    if (incomingRelations) db.relations,
                    if (timelineEventsRefs) db.timelineEvents,
                    if (participations) db.eventParticipants,
                    if (participantOf) db.eventParticipants,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (worldId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.worldId,
                                    referencedTable: $$EntriesTableReferences
                                        ._worldIdTable(db),
                                    referencedColumn: $$EntriesTableReferences
                                        ._worldIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (outgoingRelations)
                        await $_getPrefetchedData<
                          Entry,
                          $EntriesTable,
                          Relation
                        >(
                          currentTable: table,
                          referencedTable: $$EntriesTableReferences
                              ._outgoingRelationsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).outgoingRelations,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.fromEntry == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (incomingRelations)
                        await $_getPrefetchedData<
                          Entry,
                          $EntriesTable,
                          Relation
                        >(
                          currentTable: table,
                          referencedTable: $$EntriesTableReferences
                              ._incomingRelationsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).incomingRelations,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.toEntry == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (timelineEventsRefs)
                        await $_getPrefetchedData<
                          Entry,
                          $EntriesTable,
                          TimelineEvent
                        >(
                          currentTable: table,
                          referencedTable: $$EntriesTableReferences
                              ._timelineEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).timelineEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (participations)
                        await $_getPrefetchedData<
                          Entry,
                          $EntriesTable,
                          EventParticipant
                        >(
                          currentTable: table,
                          referencedTable: $$EntriesTableReferences
                              ._participationsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).participations,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventEntryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (participantOf)
                        await $_getPrefetchedData<
                          Entry,
                          $EntriesTable,
                          EventParticipant
                        >(
                          currentTable: table,
                          referencedTable: $$EntriesTableReferences
                              ._participantOfTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).participantOf,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.participantId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntriesTable,
      Entry,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (Entry, $$EntriesTableReferences),
      Entry,
      PrefetchHooks Function({
        bool worldId,
        bool outgoingRelations,
        bool incomingRelations,
        bool timelineEventsRefs,
        bool participations,
        bool participantOf,
      })
    >;
typedef $$RelationsTableCreateCompanionBuilder =
    RelationsCompanion Function({
      required String id,
      required String fromEntry,
      required String toEntry,
      required String type,
      Value<String> inverseType,
      Value<String> note,
      Value<DateTime> modified,
      Value<int> rowid,
    });
typedef $$RelationsTableUpdateCompanionBuilder =
    RelationsCompanion Function({
      Value<String> id,
      Value<String> fromEntry,
      Value<String> toEntry,
      Value<String> type,
      Value<String> inverseType,
      Value<String> note,
      Value<DateTime> modified,
      Value<int> rowid,
    });

final class $$RelationsTableReferences
    extends BaseReferences<_$AppDatabase, $RelationsTable, Relation> {
  $$RelationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EntriesTable _fromEntryTable(_$AppDatabase db) =>
      db.entries.createAlias('relations__from_entry__entries__id');

  $$EntriesTableProcessedTableManager get fromEntry {
    final $_column = $_itemColumn<String>('from_entry')!;

    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromEntryTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EntriesTable _toEntryTable(_$AppDatabase db) =>
      db.entries.createAlias('relations__to_entry__entries__id');

  $$EntriesTableProcessedTableManager get toEntry {
    final $_column = $_itemColumn<String>('to_entry')!;

    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toEntryTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RelationsTableFilterComposer
    extends Composer<_$AppDatabase, $RelationsTable> {
  $$RelationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inverseType => $composableBuilder(
    column: $table.inverseType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnFilters(column),
  );

  $$EntriesTableFilterComposer get fromEntry {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromEntry,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntriesTableFilterComposer get toEntry {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toEntry,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RelationsTableOrderingComposer
    extends Composer<_$AppDatabase, $RelationsTable> {
  $$RelationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inverseType => $composableBuilder(
    column: $table.inverseType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnOrderings(column),
  );

  $$EntriesTableOrderingComposer get fromEntry {
    final $$EntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromEntry,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableOrderingComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntriesTableOrderingComposer get toEntry {
    final $$EntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toEntry,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableOrderingComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RelationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RelationsTable> {
  $$RelationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get inverseType => $composableBuilder(
    column: $table.inverseType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  $$EntriesTableAnnotationComposer get fromEntry {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromEntry,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntriesTableAnnotationComposer get toEntry {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toEntry,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RelationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RelationsTable,
          Relation,
          $$RelationsTableFilterComposer,
          $$RelationsTableOrderingComposer,
          $$RelationsTableAnnotationComposer,
          $$RelationsTableCreateCompanionBuilder,
          $$RelationsTableUpdateCompanionBuilder,
          (Relation, $$RelationsTableReferences),
          Relation,
          PrefetchHooks Function({bool fromEntry, bool toEntry})
        > {
  $$RelationsTableTableManager(_$AppDatabase db, $RelationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RelationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RelationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RelationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fromEntry = const Value.absent(),
                Value<String> toEntry = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> inverseType = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> modified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RelationsCompanion(
                id: id,
                fromEntry: fromEntry,
                toEntry: toEntry,
                type: type,
                inverseType: inverseType,
                note: note,
                modified: modified,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String fromEntry,
                required String toEntry,
                required String type,
                Value<String> inverseType = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> modified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RelationsCompanion.insert(
                id: id,
                fromEntry: fromEntry,
                toEntry: toEntry,
                type: type,
                inverseType: inverseType,
                note: note,
                modified: modified,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RelationsTable, Relation>(table),
                  $$RelationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({fromEntry = false, toEntry = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (fromEntry) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.fromEntry,
                                referencedTable: $$RelationsTableReferences
                                    ._fromEntryTable(db),
                                referencedColumn: $$RelationsTableReferences
                                    ._fromEntryTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (toEntry) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.toEntry,
                                referencedTable: $$RelationsTableReferences
                                    ._toEntryTable(db),
                                referencedColumn: $$RelationsTableReferences
                                    ._toEntryTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RelationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RelationsTable,
      Relation,
      $$RelationsTableFilterComposer,
      $$RelationsTableOrderingComposer,
      $$RelationsTableAnnotationComposer,
      $$RelationsTableCreateCompanionBuilder,
      $$RelationsTableUpdateCompanionBuilder,
      (Relation, $$RelationsTableReferences),
      Relation,
      PrefetchHooks Function({bool fromEntry, bool toEntry})
    >;
typedef $$TimelineEventsTableCreateCompanionBuilder =
    TimelineEventsCompanion Function({
      required String entryId,
      required int startYear,
      Value<int?> startMonth,
      Value<int?> startDay,
      Value<int?> endYear,
      Value<int?> endMonth,
      Value<int?> endDay,
      Value<DateTime> modified,
      Value<int> rowid,
    });
typedef $$TimelineEventsTableUpdateCompanionBuilder =
    TimelineEventsCompanion Function({
      Value<String> entryId,
      Value<int> startYear,
      Value<int?> startMonth,
      Value<int?> startDay,
      Value<int?> endYear,
      Value<int?> endMonth,
      Value<int?> endDay,
      Value<DateTime> modified,
      Value<int> rowid,
    });

final class $$TimelineEventsTableReferences
    extends BaseReferences<_$AppDatabase, $TimelineEventsTable, TimelineEvent> {
  $$TimelineEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EntriesTable _entryIdTable(_$AppDatabase db) =>
      db.entries.createAlias('timeline_events__entry_id__entries__id');

  $$EntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TimelineEventsTableFilterComposer
    extends Composer<_$AppDatabase, $TimelineEventsTable> {
  $$TimelineEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get startYear => $composableBuilder(
    column: $table.startYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMonth => $composableBuilder(
    column: $table.startMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startDay => $composableBuilder(
    column: $table.startDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endYear => $composableBuilder(
    column: $table.endYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMonth => $composableBuilder(
    column: $table.endMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endDay => $composableBuilder(
    column: $table.endDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnFilters(column),
  );

  $$EntriesTableFilterComposer get entryId {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimelineEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $TimelineEventsTable> {
  $$TimelineEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get startYear => $composableBuilder(
    column: $table.startYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMonth => $composableBuilder(
    column: $table.startMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startDay => $composableBuilder(
    column: $table.startDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endYear => $composableBuilder(
    column: $table.endYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMonth => $composableBuilder(
    column: $table.endMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endDay => $composableBuilder(
    column: $table.endDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnOrderings(column),
  );

  $$EntriesTableOrderingComposer get entryId {
    final $$EntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableOrderingComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimelineEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimelineEventsTable> {
  $$TimelineEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get startYear =>
      $composableBuilder(column: $table.startYear, builder: (column) => column);

  GeneratedColumn<int> get startMonth => $composableBuilder(
    column: $table.startMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startDay =>
      $composableBuilder(column: $table.startDay, builder: (column) => column);

  GeneratedColumn<int> get endYear =>
      $composableBuilder(column: $table.endYear, builder: (column) => column);

  GeneratedColumn<int> get endMonth =>
      $composableBuilder(column: $table.endMonth, builder: (column) => column);

  GeneratedColumn<int> get endDay =>
      $composableBuilder(column: $table.endDay, builder: (column) => column);

  GeneratedColumn<DateTime> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  $$EntriesTableAnnotationComposer get entryId {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimelineEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimelineEventsTable,
          TimelineEvent,
          $$TimelineEventsTableFilterComposer,
          $$TimelineEventsTableOrderingComposer,
          $$TimelineEventsTableAnnotationComposer,
          $$TimelineEventsTableCreateCompanionBuilder,
          $$TimelineEventsTableUpdateCompanionBuilder,
          (TimelineEvent, $$TimelineEventsTableReferences),
          TimelineEvent,
          PrefetchHooks Function({bool entryId})
        > {
  $$TimelineEventsTableTableManager(
    _$AppDatabase db,
    $TimelineEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimelineEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimelineEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimelineEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<int> startYear = const Value.absent(),
                Value<int?> startMonth = const Value.absent(),
                Value<int?> startDay = const Value.absent(),
                Value<int?> endYear = const Value.absent(),
                Value<int?> endMonth = const Value.absent(),
                Value<int?> endDay = const Value.absent(),
                Value<DateTime> modified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimelineEventsCompanion(
                entryId: entryId,
                startYear: startYear,
                startMonth: startMonth,
                startDay: startDay,
                endYear: endYear,
                endMonth: endMonth,
                endDay: endDay,
                modified: modified,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required int startYear,
                Value<int?> startMonth = const Value.absent(),
                Value<int?> startDay = const Value.absent(),
                Value<int?> endYear = const Value.absent(),
                Value<int?> endMonth = const Value.absent(),
                Value<int?> endDay = const Value.absent(),
                Value<DateTime> modified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimelineEventsCompanion.insert(
                entryId: entryId,
                startYear: startYear,
                startMonth: startMonth,
                startDay: startDay,
                endYear: endYear,
                endMonth: endMonth,
                endDay: endDay,
                modified: modified,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TimelineEventsTable, TimelineEvent>(table),
                  $$TimelineEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (entryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.entryId,
                                referencedTable: $$TimelineEventsTableReferences
                                    ._entryIdTable(db),
                                referencedColumn:
                                    $$TimelineEventsTableReferences
                                        ._entryIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TimelineEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimelineEventsTable,
      TimelineEvent,
      $$TimelineEventsTableFilterComposer,
      $$TimelineEventsTableOrderingComposer,
      $$TimelineEventsTableAnnotationComposer,
      $$TimelineEventsTableCreateCompanionBuilder,
      $$TimelineEventsTableUpdateCompanionBuilder,
      (TimelineEvent, $$TimelineEventsTableReferences),
      TimelineEvent,
      PrefetchHooks Function({bool entryId})
    >;
typedef $$EventParticipantsTableCreateCompanionBuilder =
    EventParticipantsCompanion Function({
      required String eventEntryId,
      required String participantId,
      Value<int> rowid,
    });
typedef $$EventParticipantsTableUpdateCompanionBuilder =
    EventParticipantsCompanion Function({
      Value<String> eventEntryId,
      Value<String> participantId,
      Value<int> rowid,
    });

final class $$EventParticipantsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $EventParticipantsTable,
          EventParticipant
        > {
  $$EventParticipantsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EntriesTable _eventEntryIdTable(_$AppDatabase db) =>
      db.entries.createAlias('event_participants__event_entry_id__entries__id');

  $$EntriesTableProcessedTableManager get eventEntryId {
    final $_column = $_itemColumn<String>('event_entry_id')!;

    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EntriesTable _participantIdTable(_$AppDatabase db) =>
      db.entries.createAlias('event_participants__participant_id__entries__id');

  $$EntriesTableProcessedTableManager get participantId {
    final $_column = $_itemColumn<String>('participant_id')!;

    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_participantIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EventParticipantsTableFilterComposer
    extends Composer<_$AppDatabase, $EventParticipantsTable> {
  $$EventParticipantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$EntriesTableFilterComposer get eventEntryId {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventEntryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntriesTableFilterComposer get participantId {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.participantId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventParticipantsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventParticipantsTable> {
  $$EventParticipantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$EntriesTableOrderingComposer get eventEntryId {
    final $$EntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventEntryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableOrderingComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntriesTableOrderingComposer get participantId {
    final $$EntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.participantId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableOrderingComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventParticipantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventParticipantsTable> {
  $$EventParticipantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$EntriesTableAnnotationComposer get eventEntryId {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventEntryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntriesTableAnnotationComposer get participantId {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.participantId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventParticipantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventParticipantsTable,
          EventParticipant,
          $$EventParticipantsTableFilterComposer,
          $$EventParticipantsTableOrderingComposer,
          $$EventParticipantsTableAnnotationComposer,
          $$EventParticipantsTableCreateCompanionBuilder,
          $$EventParticipantsTableUpdateCompanionBuilder,
          (EventParticipant, $$EventParticipantsTableReferences),
          EventParticipant,
          PrefetchHooks Function({bool eventEntryId, bool participantId})
        > {
  $$EventParticipantsTableTableManager(
    _$AppDatabase db,
    $EventParticipantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventParticipantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventParticipantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventParticipantsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> eventEntryId = const Value.absent(),
                Value<String> participantId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventParticipantsCompanion(
                eventEntryId: eventEntryId,
                participantId: participantId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventEntryId,
                required String participantId,
                Value<int> rowid = const Value.absent(),
              }) => EventParticipantsCompanion.insert(
                eventEntryId: eventEntryId,
                participantId: participantId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventParticipantsTable, EventParticipant>(table),
                  $$EventParticipantsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({eventEntryId = false, participantId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (eventEntryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.eventEntryId,
                                    referencedTable:
                                        $$EventParticipantsTableReferences
                                            ._eventEntryIdTable(db),
                                    referencedColumn:
                                        $$EventParticipantsTableReferences
                                            ._eventEntryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (participantId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.participantId,
                                    referencedTable:
                                        $$EventParticipantsTableReferences
                                            ._participantIdTable(db),
                                    referencedColumn:
                                        $$EventParticipantsTableReferences
                                            ._participantIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$EventParticipantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventParticipantsTable,
      EventParticipant,
      $$EventParticipantsTableFilterComposer,
      $$EventParticipantsTableOrderingComposer,
      $$EventParticipantsTableAnnotationComposer,
      $$EventParticipantsTableCreateCompanionBuilder,
      $$EventParticipantsTableUpdateCompanionBuilder,
      (EventParticipant, $$EventParticipantsTableReferences),
      EventParticipant,
      PrefetchHooks Function({bool eventEntryId, bool participantId})
    >;
typedef $$TombstonesTableCreateCompanionBuilder =
    TombstonesCompanion Function({
      required String kind,
      required String recordId,
      required String worldId,
      required DateTime deletedAt,
      Value<int> rowid,
    });
typedef $$TombstonesTableUpdateCompanionBuilder =
    TombstonesCompanion Function({
      Value<String> kind,
      Value<String> recordId,
      Value<String> worldId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });

class $$TombstonesTableFilterComposer
    extends Composer<_$AppDatabase, $TombstonesTable> {
  $$TombstonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TombstonesTableOrderingComposer
    extends Composer<_$AppDatabase, $TombstonesTable> {
  $$TombstonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TombstonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TombstonesTable> {
  $$TombstonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$TombstonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TombstonesTable,
          Tombstone,
          $$TombstonesTableFilterComposer,
          $$TombstonesTableOrderingComposer,
          $$TombstonesTableAnnotationComposer,
          $$TombstonesTableCreateCompanionBuilder,
          $$TombstonesTableUpdateCompanionBuilder,
          (
            Tombstone,
            BaseReferences<_$AppDatabase, $TombstonesTable, Tombstone>,
          ),
          Tombstone,
          PrefetchHooks Function()
        > {
  $$TombstonesTableTableManager(_$AppDatabase db, $TombstonesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TombstonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TombstonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TombstonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> worldId = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TombstonesCompanion(
                kind: kind,
                recordId: recordId,
                worldId: worldId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String recordId,
                required String worldId,
                required DateTime deletedAt,
                Value<int> rowid = const Value.absent(),
              }) => TombstonesCompanion.insert(
                kind: kind,
                recordId: recordId,
                worldId: worldId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TombstonesTable, Tombstone>(table),
                  BaseReferences<_$AppDatabase, $TombstonesTable, Tombstone>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TombstonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TombstonesTable,
      Tombstone,
      $$TombstonesTableFilterComposer,
      $$TombstonesTableOrderingComposer,
      $$TombstonesTableAnnotationComposer,
      $$TombstonesTableCreateCompanionBuilder,
      $$TombstonesTableUpdateCompanionBuilder,
      (Tombstone, BaseReferences<_$AppDatabase, $TombstonesTable, Tombstone>),
      Tombstone,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WorldsTableTableManager get worlds =>
      $$WorldsTableTableManager(_db, _db.worlds);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$RelationsTableTableManager get relations =>
      $$RelationsTableTableManager(_db, _db.relations);
  $$TimelineEventsTableTableManager get timelineEvents =>
      $$TimelineEventsTableTableManager(_db, _db.timelineEvents);
  $$EventParticipantsTableTableManager get eventParticipants =>
      $$EventParticipantsTableTableManager(_db, _db.eventParticipants);
  $$TombstonesTableTableManager get tombstones =>
      $$TombstonesTableTableManager(_db, _db.tombstones);
}
