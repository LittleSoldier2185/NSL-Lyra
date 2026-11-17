import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'backup.dart';
import 'repository.dart';

/// Keeps dated JSON backups of every world in the app's own folder, so a bad edit, a bad
/// sync or a deleted world can be undone by importing one of them (Settings → นำเข้า).
///
/// A world is only written when it differs from its newest backup, and only the newest
/// [keep] files per world are kept. Backups of a deleted world stay as a safety net.
class AutoBackup {
  AutoBackup(this.repo, {Future<Directory> Function()? dir, this.keep = 10, DateTime Function()? clock})
      : _dir = dir ?? _defaultDir,
        _clock = clock ?? DateTime.now;

  final Repository repo;
  final int keep;
  final Future<Directory> Function() _dir;
  final DateTime Function() _clock;

  static Future<Directory> _defaultDir() async => Directory(p.join((await getApplicationSupportDirectory()).path, 'backups'));

  /// The folder the backups live in.
  Future<Directory> folder() => _dir();

  /// Backs up every world that changed since its last backup. Returns the files written.
  /// Never throws: a failed backup must not get in the way of using the app.
  Future<List<File>> run() async {
    final written = <File>[];
    try {
      final dir = await _dir();
      await dir.create(recursive: true);
      final service = BackupService(repo);
      for (final world in await repo.worlds()) {
        try {
          final file = await _backupWorld(service, dir, world);
          if (file != null) written.add(file);
        } catch (_) {
          // This world failed; the others still get their turn.
        }
      }
    } catch (_) {}
    return written;
  }

  static String _prefix(String worldId) => '${worldId.length > 8 ? worldId.substring(0, 8) : worldId}_';

  static String _two(int v) => v.toString().padLeft(2, '0');

  String _stamp(DateTime t) =>
      '${t.year}${_two(t.month)}${_two(t.day)}-${_two(t.hour)}${_two(t.minute)}${_two(t.second)}';

  /// The backup's content without its export time, for "did anything change".
  static String _essence(Map<dynamic, dynamic> json) =>
      jsonEncode(Map<dynamic, dynamic>.of(json)..remove('exportedAt'));

  /// 'yyyyMMdd-HHmmss' at the end of the file name (the world's name before it can change).
  static String _stampOf(File f) {
    final base = p.basenameWithoutExtension(f.path);
    return base.length >= 15 ? base.substring(base.length - 15) : base;
  }

  /// Backup files of one world, newest first (the stamp in the name sorts by time).
  Future<List<File>> filesOf(String worldId) async {
    final dir = await _dir();
    if (!await dir.exists()) return [];
    final prefix = _prefix(worldId);
    final files = [
      await for (final f in dir.list())
        if (f is File && p.basename(f.path).startsWith(prefix) && f.path.endsWith('.json')) f,
    ]..sort((a, b) => _stampOf(b).compareTo(_stampOf(a)));
    return files;
  }

  Future<File?> _backupWorld(BackupService service, Directory dir, world) async {
    final json = await service.exportWorld(world);
    final existing = await filesOf(world.id);
    if (existing.isNotEmpty) {
      try {
        final last = jsonDecode(await existing.first.readAsString());
        if (last is Map && _essence(last) == _essence(json)) return null; // nothing new to keep
      } catch (_) {
        // Unreadable newest backup: write a fresh one.
      }
    }
    final name = '${_prefix(world.id)}${safeFileName(world.name)}_${_stamp(_clock())}.json';
    final file = File(p.join(dir.path, name));
    if (await file.exists()) return null; // same second
    await file.writeAsString(const JsonEncoder.withIndent(' ').convert(json));
    final all = await filesOf(world.id);
    for (final old in all.skip(keep)) {
      try {
        await old.delete();
      } catch (_) {}
    }
    return file;
  }
}
