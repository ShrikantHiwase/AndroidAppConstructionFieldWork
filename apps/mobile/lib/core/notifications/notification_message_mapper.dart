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
}) {
  final stringData = <String, String>{
    for (final e in data.entries) e.key: e.value?.toString() ?? '',
  };
  final title = notificationTitle ??
      stringData['title'] ??
      _titleForType(stringData['type']) ??
      'Field update';
  final body = notificationBody ??
      stringData['body'] ??
      stringData['status'] ??
      (stringData.isEmpty ? 'Open the app for details' : stringData.toString());
  return ParsedPushMessage(title: title, body: body, data: stringData);
}

String? _titleForType(String? type) {
  switch (type) {
    case 'issue_assigned':
      return 'Issue assigned';
    case 'issue_status':
      return 'Issue status updated';
    case 'dpr_submitted':
      return 'DPR submitted';
    default:
      return null;
  }
}
