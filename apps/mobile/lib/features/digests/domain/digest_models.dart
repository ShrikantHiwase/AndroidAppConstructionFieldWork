import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';

class DigestPrefs {
  const DigestPrefs({
    this.dprNudgeEnabled = true,
    this.nudgeHourLocal = 17,
    this.pmDigestEnabled = true,
  });

  final bool dprNudgeEnabled;
  final int nudgeHourLocal;
  final bool pmDigestEnabled;

  DigestPrefs copyWith({
    bool? dprNudgeEnabled,
    int? nudgeHourLocal,
    bool? pmDigestEnabled,
  }) {
    return DigestPrefs(
      dprNudgeEnabled: dprNudgeEnabled ?? this.dprNudgeEnabled,
      nudgeHourLocal: nudgeHourLocal ?? this.nudgeHourLocal,
      pmDigestEnabled: pmDigestEnabled ?? this.pmDigestEnabled,
    );
  }

  Map<String, Object?> toJson() => {
        'dprNudgeEnabled': dprNudgeEnabled,
        'nudgeHourLocal': nudgeHourLocal,
        'pmDigestEnabled': pmDigestEnabled,
      };

  factory DigestPrefs.fromJson(Map<String, Object?> json) => DigestPrefs(
        dprNudgeEnabled: json['dprNudgeEnabled'] as bool? ?? true,
        nudgeHourLocal: json['nudgeHourLocal'] as int? ?? 17,
        pmDigestEnabled: json['pmDigestEnabled'] as bool? ?? true,
      );
}

enum DigestItemKind { missingDpr, openIssue, openRfi, dprBlocker, nudge }

class DigestItem {
  const DigestItem({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.relatedId,
  });

  final DigestItemKind kind;
  final String title;
  final String subtitle;
  final String? relatedId;
}

class DprNudge {
  const DprNudge({
    required this.message,
    required this.dueHourLocal,
  });

  final String message;
  final int dueHourLocal;
}

class PmDigestSnapshot {
  const PmDigestSnapshot({
    required this.generatedAt,
    required this.items,
    required this.openIssueCount,
    required this.openRfiCount,
    required this.missingTodayDpr,
  });

  final DateTime generatedAt;
  final List<DigestItem> items;
  final int openIssueCount;
  final int openRfiCount;
  final bool missingTodayDpr;

  String toShareText({
    required String projectName,
    required AppLocalizations l10n,
  }) {
    final buf = StringBuffer()
      ..writeln(l10n.pmDigestShareHeader(projectName))
      ..writeln(l10n.pmDigestGenerated(generatedAt.toIso8601String()))
      ..writeln(l10n.pmDigestOpenIssues(openIssueCount))
      ..writeln(l10n.pmDigestOpenRfis(openRfiCount))
      ..writeln(
        missingTodayDpr ? l10n.pmDigestTodayMissing : l10n.pmDigestTodayOk,
      )
      ..writeln('---');
    for (final item in items) {
      buf.writeln('• ${item.title} — ${item.subtitle}');
    }
    return buf.toString();
  }
}

class DigestsException implements Exception {
  DigestsException(this.message);
  final String message;
  @override
  String toString() => message;
}

bool canManageDigestPrefs(AppRole role) => role != AppRole.client;

bool canViewPmDigest(AppRole role) => switch (role) {
      AppRole.projectManager || AppRole.admin => true,
      _ => false,
    };
