import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Maps FCM / local payloads into inbox title/body/data (testable without plugins).
class ParsedPushMessage {
  const ParsedPushMessage({
    required this.title,
    required this.body,
    this.data = const {},
  });

  final String title;
  final String body;
  final Map<String, String> data;
}

ParsedPushMessage parsePushPayload({
  String? notificationTitle,
  String? notificationBody,
  Map<String, dynamic> data = const {},
  AppLocalizations? l10n,
}) {
  final copy = l10n ?? lookupAppLocalizations(const Locale('en'));
  final stringData = <String, String>{
    for (final e in data.entries) e.key: e.value?.toString() ?? '',
  };
  final title = notificationTitle ??
      stringData['title'] ??
      _titleForType(stringData['type'], copy) ??
      copy.notifyFieldUpdate;
  final body = notificationBody ??
      stringData['body'] ??
      stringData['status'] ??
      (stringData.isEmpty ? copy.notifyOpenAppForDetails : stringData.toString());
  return ParsedPushMessage(title: title, body: body, data: stringData);
}

String? _titleForType(String? type, AppLocalizations l10n) {
  switch (type) {
    case 'issue_assigned':
      return l10n.notifyIssueAssigned;
    case 'issue_status':
      return l10n.notifyIssueStatusUpdated;
    case 'rfi_assigned':
      return l10n.notifyRfiAssigned;
    case 'rfi_status':
      return l10n.notifyRfiStatusUpdated;
    case 'dpr_submitted':
      return l10n.notifyDprSubmitted;
    case 'dpr_nudge':
      return l10n.dprReminderTitle;
    default:
      return null;
  }
}
