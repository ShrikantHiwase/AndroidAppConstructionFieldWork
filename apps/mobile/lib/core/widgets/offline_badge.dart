import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Always-visible connectivity affordance — never hide create behind network.
class OfflineBadge extends StatelessWidget {
  const OfflineBadge({super.key, required this.isOffline});

  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final label = AppLocalizations.of(context).offlineBadge;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onErrorContainer,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
