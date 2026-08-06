import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

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
}

/// Test / headless: records shares and optionally copies.
class RecordingSharePort implements SharePort {
  RecordingSharePort({this.copyToClipboard = false});

  final bool copyToClipboard;
  final shared = <({String text, String? subject})>[];

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
}

final sharePortProvider = Provider<SharePort>((ref) {
  return const SystemSharePort();
});

String shareSnackMessage(ShareOutcome outcome, {required String kind}) {
  return switch (outcome.delivery) {
    ShareDelivery.system => '$kind opened in the system share sheet',
    ShareDelivery.clipboard =>
      '$kind copied — paste into WhatsApp or email',
  };
}
