import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationLogEntry {
  const NotificationLogEntry({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    this.data = const {},
    this.source = 'local',
  });

  final String id;
  final DateTime at;
  final String title;
  final String body;
  final Map<String, String> data;
  final String source;

  Map<String, Object?> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'title': title,
        'body': body,
        'data': data,
        'source': source,
      };

  factory NotificationLogEntry.fromJson(Map<String, Object?> json) =>
      NotificationLogEntry(
        id: json['id'] as String,
        at: DateTime.parse(json['at'] as String),
        title: json['title'] as String,
        body: json['body'] as String,
        data: (json['data'] as Map? ?? {})
            .map((k, v) => MapEntry(k.toString(), v.toString())),
        source: json['source'] as String? ?? 'local',
      );
}

/// On-device inbox for demo nudges + FCM (foreground / background / open).
class LocalNotificationInbox {
  LocalNotificationInbox(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'fcm.inbox';
  static const _tokenKey = 'fcm.token';
  static const _max = 40;

  final _entries = <NotificationLogEntry>[];
  int _seq = 0;

  void _load() {
    for (final raw in _prefs.getStringList(_key) ?? const []) {
      _entries.add(
        NotificationLogEntry.fromJson(
          Map<String, Object?>.from(jsonDecode(raw) as Map),
        ),
      );
    }
  }

  Future<void> _persist() async {
    await _prefs.setStringList(
      _key,
      _entries.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  List<NotificationLogEntry> get entries => List.unmodifiable(_entries);

  Future<void> add({
    required String title,
    required String body,
    Map<String, String> data = const {},
    String source = 'local',
  }) async {
    _seq += 1;
    _entries.insert(
      0,
      NotificationLogEntry(
        id: 'n_${DateTime.now().microsecondsSinceEpoch}_$_seq',
        at: DateTime.now().toUtc(),
        title: title,
        body: body,
        data: data,
        source: source,
      ),
    );
    if (_entries.length > _max) {
      _entries.removeRange(_max, _entries.length);
    }
    await _persist();
  }

  Future<void> saveToken(String token) => _prefs.setString(_tokenKey, token);

  String? readToken() => _prefs.getString(_tokenKey);
}
