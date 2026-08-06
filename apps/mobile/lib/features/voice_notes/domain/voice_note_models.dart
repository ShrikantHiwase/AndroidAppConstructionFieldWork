import '../../../core/constants/app_constants.dart';

enum VoiceParentType { dpr, issue }

extension VoiceParentTypeX on VoiceParentType {
  String get firestoreValue => switch (this) {
        VoiceParentType.dpr => 'dpr',
        VoiceParentType.issue => 'issue',
      };

  static VoiceParentType fromFirestore(String value) => switch (value) {
        'issue' => VoiceParentType.issue,
        _ => VoiceParentType.dpr,
      };
}

class VoiceNote {
  const VoiceNote({
    required this.id,
    required this.orgId,
    required this.projectId,
    required this.parentType,
    required this.parentId,
    required this.transcript,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.audioLocalPath,
    this.remoteAudioUrl,
    this.transcriptPending = false,
    this.synced = false,
  });

  final String id;
  final String orgId;
  final String projectId;
  final VoiceParentType parentType;
  final String parentId;
  final String transcript;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  /// Demo path until a real recorder plugin is wired.
  final String? audioLocalPath;
  final String? remoteAudioUrl;
  /// True when audio was captured offline and transcript awaits online pass.
  final bool transcriptPending;
  final bool synced;

  VoiceNote copyWith({
    String? transcript,
    String? audioLocalPath,
    String? remoteAudioUrl,
    bool? transcriptPending,
    bool? synced,
  }) {
    return VoiceNote(
      id: id,
      orgId: orgId,
      projectId: projectId,
      parentType: parentType,
      parentId: parentId,
      transcript: transcript ?? this.transcript,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      audioLocalPath: audioLocalPath ?? this.audioLocalPath,
      remoteAudioUrl: remoteAudioUrl ?? this.remoteAudioUrl,
      transcriptPending: transcriptPending ?? this.transcriptPending,
      synced: synced ?? this.synced,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'orgId': orgId,
        'projectId': projectId,
        'parentType': parentType.firestoreValue,
        'parentId': parentId,
        'transcript': transcript,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': createdAt.toIso8601String(),
        'audioLocalPath': audioLocalPath,
        'remoteAudioUrl': remoteAudioUrl,
        'transcriptPending': transcriptPending,
        'synced': synced,
      };

  /// Firestore payload without local-only audio path.
  Map<String, Object?> toRemoteJson() {
    final json = toJson();
    json.remove('audioLocalPath');
    return json;
  }

  factory VoiceNote.fromJson(Map<String, Object?> json) => VoiceNote(
        id: json['id'] as String,
        orgId: json['orgId'] as String,
        projectId: json['projectId'] as String,
        parentType: VoiceParentTypeX.fromFirestore(
          json['parentType'] as String? ?? 'dpr',
        ),
        parentId: json['parentId'] as String,
        transcript: json['transcript'] as String? ?? '',
        createdBy: json['createdBy'] as String,
        createdByName: json['createdByName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        audioLocalPath: json['audioLocalPath'] as String?,
        remoteAudioUrl: json['remoteAudioUrl'] as String?,
        transcriptPending: json['transcriptPending'] as bool? ?? false,
        synced: json['synced'] as bool? ?? false,
      );
}

class VoiceNotesException implements Exception {
  VoiceNotesException(this.message);
  final String message;
  @override
  String toString() => message;
}

bool canAddVoiceNotes(AppRole role) => role != AppRole.client;
