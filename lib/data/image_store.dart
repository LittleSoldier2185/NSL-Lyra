import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Thrown with a Thai, user-facing message when a picture cannot be used.
class ImageException implements Exception {
  ImageException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Entry pictures live as files in the app's own folder, named after their content
/// (`<16 hex of sha-256>.jpg|png`). An entry only stores that name in `imagePath`, so the same
/// picture is one file however many entries use it, and the name means the same thing on every
/// device (backups and syncs carry the bytes and the receiver stores them under the same name).
class ImageStore {
  ImageStore({this.dir});

  /// Where the files live; null = `images` inside the app's support folder.
  final Directory? dir;

  /// Longest side kept; larger pictures are scaled down when added.
  static const maxSide = 1280;

  /// The biggest picture accepted from outside (a backup or sync file).
  static const maxBytes = 12 * 1024 * 1024;

  static final _name = RegExp(r'^[0-9a-f]{16}\.(jpg|png)$');

  /// Only names this store itself creates are accepted, so a file from elsewhere can never point
  /// outside the images folder.
  static bool validName(String? name) => name != null && _name.hasMatch(name);

  Directory? _resolved;

  Future<Directory> folder() async {
    final cached = _resolved;
    if (cached != null) return cached;
    final d = dir ?? Directory(p.join((await getApplicationSupportDirectory()).path, 'images'));
    await d.create(recursive: true);
    return _resolved = d;
  }

  Future<File> file(String name) async => File(p.join((await folder()).path, name));

  static String _hashName(Uint8List bytes, String ext) => '${sha256.convert(bytes).toString().substring(0, 16)}.$ext';

  /// Decodes a picked picture, scales it down, stores it and returns its name.
  Future<String> addFromBytes(Uint8List bytes) async {
    if (bytes.isEmpty) throw ImageException('ไฟล์รูปว่างเปล่า');
    final processed = await Isolate.run(() => _process(bytes));
    if (processed == null) throw ImageException('เปิดรูปนี้ไม่ได้ — ใช้ไฟล์ JPG, PNG, GIF, BMP หรือ WebP');
    final (data, ext) = processed;
    final name = _hashName(data, ext);
    final f = await file(name);
    if (!await f.exists()) await f.writeAsBytes(data, flush: true);
    return name;
  }

  /// Runs off the main isolate. Null if the bytes are not a picture.
  static (Uint8List, String)? _process(Uint8List bytes) {
    try {
      var image = img.decodeImage(bytes);
      if (image == null) return null;
      image = img.bakeOrientation(image);
      if (image.width > maxSide || image.height > maxSide) {
        image = image.width >= image.height ? img.copyResize(image, width: maxSide) : img.copyResize(image, height: maxSide);
      }
      // Keep transparency (maps, icons) as PNG; photos and paintings become much smaller JPEGs.
      if (image.hasAlpha && _usesAlpha(image)) return (Uint8List.fromList(img.encodePng(image)), 'png');
      return (Uint8List.fromList(img.encodeJpg(image, quality: 85)), 'jpg');
    } catch (_) {
      return null;
    }
  }

  static bool _usesAlpha(img.Image image) {
    for (final px in image) {
      if (px.a < px.maxChannelValue) return true;
    }
    return false;
  }

  Future<Uint8List?> read(String? name) async {
    if (!validName(name)) return null;
    try {
      final f = await file(name!);
      return await f.exists() ? await f.readAsBytes() : null;
    } catch (_) {
      return null;
    }
  }

  /// Stores bytes that came from a backup or sync file under [name]. Accepted only if the name is
  /// one this store would have made for exactly these bytes (so it cannot be a path trick or a
  /// damaged file) and the size is sane. Returns whether the picture is now available.
  Future<bool> saveFromOutside(String? name, Uint8List bytes) async {
    if (!validName(name) || bytes.isEmpty || bytes.length > maxBytes) return false;
    final ext = name!.substring(name.length - 3);
    if (_hashName(bytes, ext) != name) return false;
    try {
      final f = await file(name);
      if (!await f.exists()) await f.writeAsBytes(bytes, flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The pictures named in [names] as base64, for a backup or sync file. Missing files are left out.
  Future<Map<String, String>> exportData(Iterable<String?> names) async {
    final out = <String, String>{};
    for (final n in names.toSet()) {
      final bytes = await read(n);
      if (bytes != null) out[n!] = base64Encode(bytes);
    }
    return out;
  }

  /// Makes the picture [name] available from [data] (base64) found in a backup or sync file.
  /// True if it is stored now (or already was). Bad base64, a name this store would not make or
  /// bytes that do not match the name all just return false.
  Future<bool> importData(String? name, Object? data) async {
    if (!validName(name)) return false;
    if (data is String) {
      try {
        if (await saveFromOutside(name, base64Decode(data))) return true;
      } on FormatException {
        // fall through to "already have it?"
      }
    }
    return has(name);
  }

  Future<bool> has(String? name) async {
    if (!validName(name)) return false;
    try {
      return await (await file(name!)).exists();
    } catch (_) {
      return false;
    }
  }

  /// Deletes picture files no entry refers to any more. Returns how many were removed.
  Future<int> prune(Set<String> inUse) async {
    var removed = 0;
    try {
      await for (final f in (await folder()).list()) {
        if (f is! File) continue;
        final name = p.basename(f.path);
        if (validName(name) && !inUse.contains(name)) {
          try {
            await f.delete();
            removed++;
          } catch (_) {}
        }
      }
    } catch (_) {}
    return removed;
  }
}
