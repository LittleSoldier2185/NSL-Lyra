import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Remembers the chosen theme (system / light / night). A plain JSON file next to
/// the database; any failure just means "use the system setting".
class ThemePrefs {
  ThemePrefs({this.dir});

  /// Where the file lives; null = the app's support folder.
  final Directory? dir;

  Future<File> _file() async {
    final d = dir ?? await getApplicationSupportDirectory();
    return File(p.join(d.path, 'theme_prefs.json'));
  }

  Future<ThemeMode> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return ThemeMode.system;
      final j = jsonDecode(await f.readAsString());
      final name = j is Map ? j['mode'] : null;
      return ThemeMode.values.firstWhere((m) => m.name == name, orElse: () => ThemeMode.system);
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> save(ThemeMode mode) async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode({'mode': mode.name}));
    } catch (_) {}
  }
}
