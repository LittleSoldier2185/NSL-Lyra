import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Remembers the other device's address so it needn't be typed every time.
/// A plain JSON file next to the database; any failure just means "nothing remembered".
class SyncPrefs {
  SyncPrefs({this.dir});

  /// Where the file lives; null = the app's support folder.
  final Directory? dir;

  Future<File> _file() async {
    final d = dir ?? await getApplicationSupportDirectory();
    return File(p.join(d.path, 'sync_prefs.json'));
  }

  Future<String> lastAddress() async {
    try {
      final f = await _file();
      if (!await f.exists()) return '';
      final j = jsonDecode(await f.readAsString());
      return j is Map ? (j['lastAddress'] as String? ?? '') : '';
    } catch (_) {
      return '';
    }
  }

  Future<void> saveLastAddress(String address) async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode({'lastAddress': address}));
    } catch (_) {}
  }
}
