import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_locale_provider.dart';
import '../core/notifications/notification_deep_link.dart';
import '../core/providers/connectivity_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/offline_badge.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/biometric_unlock_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/role_home_page.dart';
import '../l10n/app_localizations.dart';

class FieldApp extends ConsumerWidget {
  const FieldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final firebaseEnabled = ref.watch(firebaseEnabledProvider);
    final localeOverride = ref.watch(appLocaleProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: localeOverride,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: switch (auth.status) {
        AuthStatus.unknown => const _BootSplash(),
        AuthStatus.signedOut => const LoginPage(),
        AuthStatus.locked => const BiometricUnlockPage(),
        AuthStatus.signedIn => const RoleHomePage(),
      },
      builder: (context, child) {
        return Banner(
          message: firebaseEnabled ? 'FIREBASE' : 'DEMO',
          location: BannerLocation.topEnd,
          color: const Color(0xFF1B4D3E),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class ScaffoldShell extends ConsumerWidget {
  const ScaffoldShell({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOfflineProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: OfflineBadge(isOffline: offline)),
          ),
        ],
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
