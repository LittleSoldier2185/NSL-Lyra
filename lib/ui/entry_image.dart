import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../providers.dart';
import '../theme.dart';

/// An entry's picture, read from the app's image folder. Shows a quiet placeholder while the
/// folder is resolving or if the file is missing (e.g. a sync brought the entry but not the file).
class EntryImage extends ConsumerWidget {
  const EntryImage(this.name, {super.key, this.width, this.height, this.fit = BoxFit.cover, this.cacheWidth});
  final String name;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Decode at this width instead of full size (thumbnails).
  final int? cacheWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dir = ref.watch(imageDirProvider).value;
    Widget placeholder([IconData icon = Icons.image_outlined]) => Container(
          width: width,
          height: height,
          color: C.bgChip,
          alignment: Alignment.center,
          child: Icon(icon, color: C.inkFaint, size: 24),
        );
    if (dir == null) return placeholder();
    return Image.file(
      File(p.join(dir.path, name)),
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => placeholder(Icons.broken_image_outlined),
    );
  }
}

/// Full-screen, zoomable view of a picture.
Future<void> showImageViewer(BuildContext context, String name, String title) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(children: [
        Positioned.fill(
          child: InteractiveViewer(
            maxScale: 6,
            child: Center(child: EntryImage(name, fit: BoxFit.contain)),
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Row(children: [
            Expanded(child: Text(title, style: T.ui(15, w: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
            IconButton(
              tooltip: 'ปิด',
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]),
        ),
      ]),
    ),
  );
}
