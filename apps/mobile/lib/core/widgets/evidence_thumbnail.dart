import 'dart:io';

import 'package:flutter/material.dart';

/// Square preview for an evidence photo: renders the local file when it still
/// exists on device, otherwise falls back to an icon (demo stubs, cleared
/// cache, or remote-only attachments).
class EvidenceThumbnail extends StatelessWidget {
  const EvidenceThumbnail({super.key, this.localPath, this.size = 48});

  final String? localPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = localPath;
    final file = (path == null || path.isEmpty) ? null : File(path);
    final scheme = Theme.of(context).colorScheme;

    Widget fallback() => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
        );

    if (file == null || !file.existsSync()) return fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        errorBuilder: (_, __, ___) => fallback(),
      ),
    );
  }
}
