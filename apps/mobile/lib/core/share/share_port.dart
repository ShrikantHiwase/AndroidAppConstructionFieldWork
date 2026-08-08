import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';

/// Result of a share attempt (system sheet or clipboard fallback).
enum ShareDelivery {
  /// Native share sheet accepted / completed (or unavailable-but-shown).
  system,

  /// Copied to clipboard because share failed or was unavailable in tests.
  clipboard,
}

class ShareOutcome {
  const ShareOutcome({
    required this.delivery,
    this.statusLabel,
  });

  final ShareDelivery delivery;
  final String? statusLabel;
}

/// Abstraction so UI can share without coupling to plugins in unit tests.
abstract class SharePort {
  Future<ShareOutcome> shareText({
    required String text,
    String? subject,
  });

  /// Writes [bytes] to a temp file and opens the system share sheet.
  /// On failure, copies [fallbackText] (if provided) to the clipboard.
  Future<ShareOutcome> shareFile({
    required Uint8List bytes,
    required String filename,
    String? subject,
    String? text,
    String? fallbackText,
    String mimeType = 'application/pdf',
  });
}

/// Production port: `share_plus` with clipboard fallback.
class SystemSharePort implements SharePort {
  const SystemSharePort();

  @override
  Future<ShareOutcome> shareText({
    required String text,
    String? subject,
  }) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: text, subject: subject),
      );
      if (result.status == ShareResultStatus.unavailable) {
        await Clipboard.setData(ClipboardData(text: text));
        return const ShareOutcome(
          delivery: ShareDelivery.clipboard,
          statusLabel: 'unavailable',
        );
      }
      return ShareOutcome(
        delivery: ShareDelivery.system,
        statusLabel: result.status.name,
      );
    } catch (e, st) {
      debugPrint('Share failed, copying instead: $e\n$st');
      await Clipboard.setData(ClipboardData(text: text));
      return const ShareOutcome(delivery: ShareDelivery.clipboard);
    }
  }

  @override
  Future<ShareOutcome> shareFile({
    required Uint8List bytes,
    required String filename,
    String? subject,
    String? text,
    String? fallbackText,
    String mimeType = 'application/pdf',
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final safeName = filename.replaceAll(RegExp(r'[^\w.\-]+'), '_');
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(bytes, flush: true);
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path, mimeType: mimeType, name: safeName),
          ],
          subject: subject,
          text: text,
        ),
      );
      if (result.status == ShareResultStatus.unavailable) {
        return _fileClipboardFallback(fallbackText);
      }
      return ShareOutcome(
        delivery: ShareDelivery.system,
        statusLabel: result.status.name,
      );
    } catch (e, st) {
      debugPrint('Share file failed: $e\n$st');
      return _fileClipboardFallback(fallbackText);
    }
  }

  Future<ShareOutcome> _fileClipboardFallback(String? fallbackText) async {
    if (fallbackText != null && fallbackText.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: fallbackText));
      return const ShareOutcome(
        delivery: ShareDelivery.clipboard,
        statusLabel: 'unavailable',
      );
    }
    return const ShareOutcome(
      delivery: ShareDelivery.clipboard,
      statusLabel: 'unavailable',
    );
  }
}

/// Test / headless: records shares and optionally copies.
class RecordingSharePort implements SharePort {
  RecordingSharePort({this.copyToClipboard = false});

  final bool copyToClipboard;
  final shared = <({String text, String? subject})>[];
  final sharedFiles =
      <({String filename, int byteLength, String? subject, String? text})>[];

  @override
  Future<ShareOutcome> shareText({
    required String text,
    String? subject,
  }) async {
    shared.add((text: text, subject: subject));
    if (copyToClipboard) {
      await Clipboard.setData(ClipboardData(text: text));
      return const ShareOutcome(delivery: ShareDelivery.clipboard);
    }
    return const ShareOutcome(delivery: ShareDelivery.system);
  }

  @override
  Future<ShareOutcome> shareFile({
    required Uint8List bytes,
    required String filename,
    String? subject,
    String? text,
    String? fallbackText,
    String mimeType = 'application/pdf',
  }) async {
    sharedFiles.add((
      filename: filename,
      byteLength: bytes.length,
      subject: subject,
      text: text,
    ));
    if (copyToClipboard &&
        fallbackText != null &&
        fallbackText.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: fallbackText));
      return const ShareOutcome(delivery: ShareDelivery.clipboard);
    }
    return const ShareOutcome(delivery: ShareDelivery.system);
  }
}

final sharePortProvider = Provider<SharePort>((ref) {
  return const SystemSharePort();
});

String shareSnackMessage(
  ShareOutcome outcome, {
  required String kind,
  required AppLocalizations l10n,
}) {
  return switch (outcome.delivery) {
    ShareDelivery.system => l10n.shareSnackSystem(kind),
    ShareDelivery.clipboard => l10n.shareSnackClipboard(kind),
  };
}
