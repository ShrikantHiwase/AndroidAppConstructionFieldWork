import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/domain/auth_models.dart';
import '../domain/voice_note_models.dart';
import '../domain/voice_notes_repository.dart';

class LocalVoiceNotesRepository implements VoiceNotesRepository {
  LocalVoiceNotesRepository(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'voice.notes';

  final _items = <String, VoiceNote>{};
  final _controller = StreamController<List<VoiceNote>>.broadcast();
  int _seq = 0;

  void _load() {
    for (final raw in _prefs.getStringList(_key) ?? const []) {
      final note = VoiceNote.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
      _items[note.id] = note;
    }
  }

  Future<void> _persist() async {
    await _prefs.setStringList(
      _key,
      _items.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    _controller.add(_items.values.toList());
  }

  List<VoiceNote> _filter({
    required VoiceParentType parentType,
    required String parentId,
  }) {
    return _items.values
        .where((n) => n.parentType == parentType && n.parentId == parentId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Stream<List<VoiceNote>> watchForParent({
    required VoiceParentType parentType,
    required String parentId,
  }) async* {
    yield _filter(parentType: parentType, parentId: parentId);
    yield* _controller.stream
        .map((_) => _filter(parentType: parentType, parentId: parentId));
  }

  @override
  Future<List<VoiceNote>> listForParent({
    required VoiceParentType parentType,
    required String parentId,
  }) async {
    return _filter(parentType: parentType, parentId: parentId);
  }

  @override
  Future<VoiceNote> addDemoVoiceNote({
    required AuthSession session,
    required VoiceParentType parentType,
    required String parentId,
    String? transcript,
    bool offline = false,
  }) async {
    if (!canAddVoiceNotes(session.activeRole)) {
      throw VoiceNotesException('Client accounts cannot add voice notes');
    }
    if (parentId.trim().isEmpty) {
      throw VoiceNotesException('Parent record is required');
    }
    final now = DateTime.now().toUtc();
    final id = 'voice_${now.microsecondsSinceEpoch}_${++_seq}';
    final pending = offline;
    final note = VoiceNote(
      id: id,
      orgId: session.activeProject.orgId,
      projectId: session.activeProjectId,
      parentType: parentType,
      parentId: parentId,
      transcript: pending
          ? (transcript?.trim().isNotEmpty == true
              ? transcript!.trim()
              : 'Audio stored offline — transcript when online')
          : (transcript?.trim().isNotEmpty == true
              ? transcript!.trim()
              : 'Voice stub: progress update from site (${session.user.displayName})'),
      createdBy: session.user.id,
      createdByName: session.user.displayName,
      createdAt: now,
      audioLocalPath: 'local://demo/voice_$id.m4a',
      transcriptPending: pending,
    );
    _items[note.id] = note;
    await _persist();
    return note;
  }
}
