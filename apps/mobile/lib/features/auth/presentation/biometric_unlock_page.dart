import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/device/device_providers.dart';
import 'auth_controller.dart';

/// Local unlock gate when biometrics preference is on.
class BiometricUnlockPage extends ConsumerWidget {
  const BiometricUnlockPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Text('Unlock Field Evidence', style: textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                session == null
                    ? 'Confirm it is you to continue.'
                    : 'Welcome back, ${session.user.displayName}. '
                        '${native ? 'Use device biometrics or PIN.' : 'Demo unlock (FakeBiometricService) until USE_NATIVE_SENSORS=true.'}',
                style: textTheme.bodyLarge,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () async {
                  final ok = await ref
                      .read(biometricServiceProvider)
                      .authenticate(reason: 'Unlock Field Evidence');
                  if (!ok) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unlock failed')),
                      );
                    }
                    return;
                  }
                  await ref.read(authControllerProvider.notifier).unlock();
                },
                icon: const Icon(Icons.lock_open),
                label: const Text('Unlock'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
