import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/device/device_providers.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_controller.dart';

/// Local unlock gate when biometrics preference is on.
class BiometricUnlockPage extends ConsumerWidget {
  const BiometricUnlockPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authSessionProvider);
    final native = ref.watch(usingNativeSensorsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.fingerprint,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(l10n.unlockTitle, style: textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                session == null
                    ? l10n.unlockConfirm
                    : l10n.unlockWelcomeBack(
                        session.user.displayName,
                        native ? l10n.unlockHintNative : l10n.unlockHintDemo,
                      ),
                style: textTheme.bodyLarge,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () async {
                  final ok = await ref
                      .read(biometricServiceProvider)
                      .authenticate(reason: l10n.unlockReason);
                  if (!ok) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.unlockFailed)),
                      );
                    }
                    return;
                  }
                  await ref.read(authControllerProvider.notifier).unlock();
                },
                icon: const Icon(Icons.lock_open),
                label: Text(l10n.unlockAction),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                child: Text(l10n.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
