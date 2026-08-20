import '../../features/admin/domain/admin_invite_models.dart';
import '../../features/documents/domain/document_models.dart';
import '../../features/dpr/domain/dpr_models.dart';
import '../../features/issues/domain/issue_models.dart';
import '../../features/site_ops/domain/site_ops_models.dart';
import '../../features/voice_notes/domain/voice_note_models.dart';
import '../../l10n/app_localizations.dart';
import 'app_error_codes.dart';

export 'app_error_codes.dart';

/// Maps domain exceptions to locale-aware copy for SnackBars / error panes.
String localizeAppError(Object error, AppLocalizations l10n) {
  if (error is FieldRecordsException) {
    return switch (error.code) {
      AppErrorCodes.clientReadOnly => l10n.errClientReadOnly,
      AppErrorCodes.cannotAssign => l10n.errCannotAssign,
      AppErrorCodes.cannotChangeStatus => l10n.errCannotChangeStatus,
      AppErrorCodes.titleRequired => l10n.errTitleRequired,
      AppErrorCodes.subjectRequired => l10n.errSubjectRequired,
      AppErrorCodes.commentEmpty => l10n.errCommentEmpty,
      AppErrorCodes.issueNotFound => l10n.errIssueNotFound,
      AppErrorCodes.issueWrongProject => l10n.errIssueWrongProject,
      AppErrorCodes.rfiNotFound => l10n.errRfiNotFound,
      AppErrorCodes.cannotMoveStatus => l10n.errCannotMoveStatus(
          _statusLabel(error.arg1, l10n),
          _statusLabel(error.arg2, l10n),
        ),
      _ => error.englishMessage,
    };
  }
  if (error is DprException) {
    return switch (error.code) {
      AppErrorCodes.clientCannotEditDpr => l10n.errClientCannotEditDpr,
      AppErrorCodes.clientCannotSubmitDpr => l10n.errClientCannotSubmitDpr,
      AppErrorCodes.dprAlreadySubmitted => l10n.errDprAlreadySubmitted,
      AppErrorCodes.dprNotFound => l10n.errDprNotFound,
      AppErrorCodes.dprWrongProject => l10n.errDprWrongProject,
      AppErrorCodes.dprNeedActivity => l10n.errDprNeedActivity,
      _ => error.englishMessage,
    };
  }
  if (error is DrawingException) {
    return switch (error.code) {
      AppErrorCodes.clientCannotPin => l10n.errClientCannotPin,
      AppErrorCodes.drawingNotFound => l10n.errDrawingNotFound,
      AppErrorCodes.pageOutOfRange => l10n.errPageOutOfRange,
      AppErrorCodes.pinOutOfBounds => l10n.errPinOutOfBounds,
      _ => error.englishMessage,
    };
  }
  if (error is SiteOpsException) {
    return switch (error.code) {
      AppErrorCodes.clientReadOnlySiteOps => l10n.errClientReadOnlySiteOps,
      AppErrorCodes.titleRequired => l10n.errTitleRequired,
      AppErrorCodes.checklistItemsRequired => l10n.errChecklistItemsRequired,
      AppErrorCodes.headcountInvalid => l10n.errHeadcountInvalid,
      AppErrorCodes.materialRequired => l10n.errMaterialRequired,
      AppErrorCodes.quantityInvalid => l10n.errQuantityInvalid,
      AppErrorCodes.photoEvidenceRequired =>
        l10n.errPhotoEvidenceRequired(error.arg1 ?? ''),
      AppErrorCodes.photoRequiredOnFail =>
        l10n.errPhotoRequiredOnFail(error.arg1 ?? ''),
      _ => error.englishMessage,
    };
  }
  if (error is DocumentsException) {
    return switch (error.code) {
      AppErrorCodes.cannotUploadDocs => l10n.errCannotUploadDocs,
      AppErrorCodes.cannotManageFolders => l10n.errCannotManageFolders,
      AppErrorCodes.folderNotFound => l10n.errFolderNotFound,
      AppErrorCodes.parentFolderNotFound => l10n.errParentFolderNotFound,
      AppErrorCodes.fileNameRequired => l10n.errFileNameRequired,
      AppErrorCodes.documentNotFound => l10n.errDocumentNotFound,
      _ => error.englishMessage,
    };
  }
  if (error is VoiceNotesException) {
    return switch (error.code) {
      AppErrorCodes.clientCannotVoice => l10n.errClientCannotVoice,
      AppErrorCodes.parentRequired => l10n.errParentRequired,
      AppErrorCodes.audioPathRequired => l10n.errAudioPathRequired,
      _ => error.englishMessage,
    };
  }
  if (error is AdminInvitesException) {
    return switch (error.code) {
      AppErrorCodes.onlyAdminsInvite => l10n.errOnlyAdminsInvite,
      AppErrorCodes.emailRequired => l10n.errEmailRequired,
      AppErrorCodes.selectProject => l10n.errSelectProject,
      AppErrorCodes.unknownProject =>
        l10n.errUnknownProject(error.arg1 ?? ''),
      AppErrorCodes.pendingInviteExists =>
        l10n.errPendingInviteExists(error.arg1 ?? ''),
      AppErrorCodes.inviteMissingId => l10n.errInviteMissingId,
      AppErrorCodes.remoteFailure => error.arg1 ?? l10n.errRemoteFailure,
      _ => error.englishMessage,
    };
  }
  return '$error';
}

String _statusLabel(String? name, AppLocalizations l10n) {
  if (name == null || name.isEmpty) return '—';
  try {
    return IssueStatus.values.byName(name).localizedLabel(l10n);
  } catch (_) {
    return name;
  }
}
