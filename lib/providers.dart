import 'dart:io' show Directory;
import 'dart:typed_data' show Uint8List;

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart' show ThemeMode;
import 'dart:ui' show Offset;

import 'core/calendar.dart';
import 'data/auto_backup.dart';
import 'data/database.dart';
import 'data/repository.dart';
import 'data/theme_prefs.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<Repository>((ref) => Repository(ref.watch(databaseProvider)));

final worldsProvider = StreamProvider<List<World>>((ref) => ref.watch(repositoryProvider).watchWorlds());

/// Explicitly chosen world; null means "first world".
class _WorldChoice extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? id) => state = id;
}

final worldChoiceProvider = NotifierProvider<_WorldChoice, String?>(_WorldChoice.new);

/// The world being viewed, or null while loading / when none exists yet.
final activeWorldProvider = Provider<World?>((ref) {
  final worlds = ref.watch(worldsProvider).value;
  if (worlds == null || worlds.isEmpty) return null;
  final choice = ref.watch(worldChoiceProvider);
  return worlds.firstWhere((w) => w.id == choice, orElse: () => worlds.first);
});

final entriesProvider = StreamProvider<List<Entry>>((ref) {
  final w = ref.watch(activeWorldProvider);
  if (w == null) return Stream.value(const []);
  return ref.watch(repositoryProvider).watchEntries(w.id);
});

class _Selected extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? id) => state = id;
}

final selectedIdProvider = NotifierProvider<_Selected, String?>(_Selected.new);

class _Query extends Notifier<String> {
  @override
  String build() => '';
  void set(String q) => state = q;
}

final queryProvider = NotifierProvider<_Query, String>(_Query.new);

class _TypeFilter extends Notifier<EntryType?> {
  @override
  EntryType? build() => null;
  void set(EntryType? t) => state = t;
}

final typeFilterProvider = NotifierProvider<_TypeFilter, EntryType?>(_TypeFilter.new);

/// Desktop only: whether the content column shows the editor.
class _Editing extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

final editingProvider = NotifierProvider<_Editing, bool>(_Editing.new);

/// Shown in the top bar: false while a debounced save is pending.
class _Saved extends Notifier<bool> {
  @override
  bool build() => true;
  void set(bool v) => state = v;
}

final savedProvider = NotifierProvider<_Saved, bool>(_Saved.new);

final allEntriesProvider = Provider<List<Entry>>((ref) => ref.watch(entriesProvider).value ?? const []);

class _StatusFilter extends Notifier<EntryStatus?> {
  @override
  EntryStatus? build() => null;
  void set(EntryStatus? s) => state = s;
}

final statusFilterProvider = NotifierProvider<_StatusFilter, EntryStatus?>(_StatusFilter.new);

class _TagFilter extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? t) => state = t;
}

final tagFilterProvider = NotifierProvider<_TagFilter, String?>(_TagFilter.new);

enum EntrySort { updated, name }

class _Sort extends Notifier<EntrySort> {
  @override
  EntrySort build() => EntrySort.updated;
  void set(EntrySort s) => state = s;
}

final sortProvider = NotifierProvider<_Sort, EntrySort>(_Sort.new);

/// Every tag used in the active world, sorted.
final allTagsProvider = Provider<List<String>>((ref) {
  final tags = <String>{};
  for (final e in ref.watch(allEntriesProvider)) {
    tags.addAll(decodeList(e.tags));
  }
  return tags.toList()..sort(thaiCompare);
});

/// Sort key that ignores Thai leading vowels (เ แ โ ใ ไ), as dictionaries do.
String _thaiKey(String s) => s.toLowerCase().replaceFirst(RegExp(r'^[เแโใไ]+'), '');

int thaiCompare(String a, String b) => _thaiKey(a).compareTo(_thaiKey(b));

/// Entries after search, type/status/tag filters and sorting.
final filteredEntriesProvider = Provider<List<Entry>>((ref) {
  final type = ref.watch(typeFilterProvider);
  final status = ref.watch(statusFilterProvider);
  final tag = ref.watch(tagFilterProvider);
  final sort = ref.watch(sortProvider);
  var list = ref.watch(allEntriesProvider).where((e) =>
      (type == null || e.type == type) &&
      (status == null || e.status == status) &&
      (tag == null || decodeList(e.tags).contains(tag)));
  final out = ref.watch(repositoryProvider).search(list.toList(), ref.watch(queryProvider));
  if (sort == EntrySort.name) out.sort((a, b) => thaiCompare(a.title, b.title));
  return out;
});

final selectedEntryProvider = Provider<Entry?>((ref) {
  final id = ref.watch(selectedIdProvider);
  final all = ref.watch(allEntriesProvider);
  if (id == null) return null;
  for (final e in all) {
    if (e.id == id) return e;
  }
  return null;
});

/// Dated entries of the active world, oldest first.
final timelineProvider = StreamProvider<List<TimelineItem>>((ref) {
  final w = ref.watch(activeWorldProvider);
  if (w == null) return Stream.value(const []);
  return ref.watch(repositoryProvider).watchTimeline(w.id);
});

final calendarProvider = Provider<CalendarConfig>((ref) {
  final w = ref.watch(activeWorldProvider);
  return w == null ? const CalendarConfig() : CalendarConfig.parse(w.calendarConfig);
});

enum MainView { overview, timeline, graph }

/// PC: what the content column shows when no entry is selected.
class _MainViewNotifier extends Notifier<MainView> {
  @override
  MainView build() => MainView.overview;
  void set(MainView v) => state = v;
}

final mainViewProvider = NotifierProvider<_MainViewNotifier, MainView>(_MainViewNotifier.new);

/// Every relation in the active world (for the graph).
final worldRelationsProvider = StreamProvider<List<Relation>>((ref) {
  final w = ref.watch(activeWorldProvider);
  if (w == null) return Stream.value(const []);
  return ref.watch(repositoryProvider).watchRelationsOfWorld(w.id);
});

/// Graph view state that should survive leaving the view (opening an entry and coming back).
/// Plain mutable object on purpose: the graph widget owns when to rebuild.
class GraphSession {
  final positions = <String, Offset>{};
  final pinned = <String>{};
  final hiddenTypes = <String>{};
  bool includeLinks = false;
  bool showIsolated = false;
  String? focusId;
  int depth = 1;
  Offset pan = Offset.zero;
  double scale = 1;
  bool fitted = false;
}

final graphSessionProvider = Provider.family<GraphSession, String>((ref, worldId) => GraphSession());

/// Timeline filter: only events involving this entry (as participant or as the event itself).
class _TimelineFilter extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? id) => state = id;
}

final timelineFilterProvider = NotifierProvider<_TimelineFilter, String?>(_TimelineFilter.new);

final relationsOfProvider = StreamProvider.family<List<Relation>, String>(
    (ref, id) => ref.watch(repositoryProvider).watchRelationsOf(id));

/// Theme choice: follow the system, or force light / night. Remembered between runs.
final themePrefsProvider = Provider<ThemePrefs>((ref) => ThemePrefs());

class _ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    ref.read(themePrefsProvider).load().then((m) {
      if (ref.mounted && m != state) state = m;
    });
    return ThemeMode.system;
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(themePrefsProvider).save(mode);
  }
}

final themeModeProvider = NotifierProvider<_ThemeModeNotifier, ThemeMode>(_ThemeModeNotifier.new);

/// Dated JSON backups in the app's own folder; see [AutoBackup].
final autoBackupProvider = Provider<AutoBackup>((ref) => AutoBackup(ref.watch(repositoryProvider)));

/// The folder entry pictures are stored in.
final imageDirProvider = FutureProvider<Directory>((ref) => ref.watch(repositoryProvider).images.folder());

/// Lets the person choose a picture file; returns its bytes, or null if they cancel.
/// A provider so tests can supply a picture without a file dialog.
final imagePickerProvider = Provider<Future<Uint8List?> Function()>((ref) => () async {
      final file = await FilePicker.pickFile(dialogTitle: 'เลือกรูปภาพ', type: FileType.image);
      return file == null ? null : await file.readAsBytes();
    });
