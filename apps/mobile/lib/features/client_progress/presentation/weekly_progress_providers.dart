import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_locale_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dpr/presentation/dpr_providers.dart';
import '../../issues/presentation/field_records_providers.dart';
import '../domain/weekly_progress_builder.dart';
import '../domain/weekly_progress_models.dart';

final weeklyProgressProvider =
    FutureProvider<WeeklyProgressSnapshot?>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null || !canViewWeeklyProgress(session.activeRole)) {
    return null;
  }
  final dprs = await ref.watch(dprsProvider.future);
  final issues = await ref.watch(issuesProvider.future);
  final override = ref.watch(appLocaleProvider);
  final l10n = lookupAppLocalizations(override ?? const Locale('en'));
  return buildWeeklyProgress(
    projectId: session.activeProjectId,
    dprs: dprs,
    issues: issues,
    l10n: l10n,
  );
});
