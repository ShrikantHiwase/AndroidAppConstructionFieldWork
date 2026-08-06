import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'evidence_image_policy.dart';

class CompressedImage {
  const CompressedImage({
    required this.path,
    required this.byteSizeBytes,
    this.widthPx,
    this.qualityUsed,
  });

  final String path;
  final int byteSizeBytes;
  final int? widthPx;
  final int? qualityUsed;
}

/// Compresses evidence JPEGs for outbox / Storage upload.
abstract class ImageCompressor {
  Future<CompressedImage> compressFile(String path);
}

/// Reads length only (no re-encode). Used when decode fails.
class PassthroughImageCompressor implements ImageCompressor {
  const PassthroughImageCompressor();

  @override
  Future<CompressedImage> compressFile(String path) async {
    if (path.startsWith('local://') || path.startsWith('demo://')) {
      return CompressedImage(
        path: path,
        byteSizeBytes: EvidenceImagePolicy.demoByteSize,
      );
    }
    final file = File(path);
    final length = await file.exists() ? await file.length() : 0;
    return CompressedImage(path: path, byteSizeBytes: length);
  }
}

/// Demo path: synthetic size, no I/O.
class FakeImageCompressor implements ImageCompressor {
  const FakeImageCompressor();

  @override
  Future<CompressedImage> compressFile(String path) async {
    return CompressedImage(
      path: path,
      byteSizeBytes: EvidenceImagePolicy.demoByteSize,
      widthPx: EvidenceImagePolicy.maxWidthPx,
      qualityUsed: EvidenceImagePolicy.jpegQuality,
    );
  }
}

/// Pure-Dart JPEG resize + quality ladder via `package:image`.
class FileImageCompressor implements ImageCompressor {
  const FileImageCompressor();

  @override
  Future<CompressedImage> compressFile(String path) async {
    if (path.startsWith('local://') || path.startsWith('demo://')) {
      return const FakeImageCompressor().compressFile(path);
    }

    try {
      final file = File(path);
      if (!await file.exists()) {
        return CompressedImage(path: path, byteSizeBytes: 0);
      }
      final original = await file.readAsBytes();
      final decoded = img.decodeImage(original);
      if (decoded == null) {
        return CompressedImage(
          path: path,
          byteSizeBytes: original.length,
        );
      }

      var processed = decoded;
      if (processed.width > EvidenceImagePolicy.maxWidthPx) {
        processed = img.copyResize(
          processed,
          width: EvidenceImagePolicy.maxWidthPx,
        );
      }

      var quality = EvidenceImagePolicy.jpegQuality;
      var encoded = Uint8List.fromList(
        img.encodeJpg(processed, quality: quality),
      );
      while (encoded.length > EvidenceImagePolicy.targetMaxBytes &&
          quality > EvidenceImagePolicy.minJpegQuality) {
        quality -= 10;
        encoded = Uint8List.fromList(
          img.encodeJpg(processed, quality: quality),
        );
      }

      // High-frequency content can still exceed the soft target — shrink further.
      const widthSteps = [1280, 1024, 800];
      for (final w in widthSteps) {
        if (encoded.length <= EvidenceImagePolicy.targetMaxBytes) break;
        if (processed.width <= w) continue;
        processed = img.copyResize(processed, width: w);
        encoded = Uint8List.fromList(
          img.encodeJpg(processed, quality: quality),
        );
      }

      await file.writeAsBytes(encoded, flush: true);
      return CompressedImage(
        path: path,
        byteSizeBytes: encoded.length,
        widthPx: processed.width,
        qualityUsed: quality,
      );
    } catch (e, st) {
      debugPrint('Image compress failed, passthrough: $e\n$st');
      return const PassthroughImageCompressor().compressFile(path);
    }
  }
}

/// Builds a noisy on-disk JPEG for unit tests (no camera / path_provider).
Future<File> writeTestJpeg({
  int width = 2000,
  int height = 1200,
  int quality = 95,
}) async {
  final file = File(
    '${Directory.systemTemp.path}/evidence_test_'
    '${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  final image = img.Image(width: width, height: height);
  // Pseudo-noise so JPEG is large enough to exercise resize/quality.
  for (var y = 0; y < height; y += 2) {
    for (var x = 0; x < width; x += 2) {
      final v = (x * 37 + y * 91) % 255;
      final color = img.ColorRgb8(v, (v * 3) % 255, (255 - v));
      image.setPixel(x, y, color);
      if (x + 1 < width) image.setPixel(x + 1, y, color);
      if (y + 1 < height) image.setPixel(x, y + 1, color);
      if (x + 1 < width && y + 1 < height) {
        image.setPixel(x + 1, y + 1, color);
      }
    }
  }
  await file.writeAsBytes(img.encodeJpg(image, quality: quality), flush: true);
  return file;
}
