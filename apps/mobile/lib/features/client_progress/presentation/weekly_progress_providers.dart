import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  return buildWeeklyProgress(
    projectId: session.activeProjectId,
    dprs: dprs,
    issues: issues,
  );
});
