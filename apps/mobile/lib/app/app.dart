import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/offline_badge.dart';
import '../../features/auth/presentation/splash_home_page.dart';

class FieldApp extends ConsumerWidget {
  const FieldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Field Evidence',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Localizations will wire after `flutter gen-l10n` in CI / local builds.
      home: const SplashHomePage(),
      builder: (context, child) {
        return Banner(
          message: 'PHASE 0',
          location: BannerLocation.topEnd,
          color: const Color(0xFF1B4D3E),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Demo connectivity flag until connectivity_plus is hooked in Phase 1.
final isOfflineProvider = StateProvider<bool>((ref) => false);

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
