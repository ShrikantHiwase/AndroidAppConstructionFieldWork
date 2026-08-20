/// Stable codes thrown by domain repositories.
abstract final class AppErrorCodes {
  static const clientReadOnly = 'clientReadOnly';
  static const clientReadOnlySiteOps = 'clientReadOnlySiteOps';
  static const clientCannotEditDpr = 'clientCannotEditDpr';
  static const clientCannotSubmitDpr = 'clientCannotSubmitDpr';
  static const clientCannotPin = 'clientCannotPin';
  static const clientCannotVoice = 'clientCannotVoice';
  static const cannotAssign = 'cannotAssign';
  static const cannotChangeStatus = 'cannotChangeStatus';
  static const cannotUploadDocs = 'cannotUploadDocs';
  static const cannotManageFolders = 'cannotManageFolders';
  static const onlyAdminsInvite = 'onlyAdminsInvite';
  static const titleRequired = 'titleRequired';
  static const subjectRequired = 'subjectRequired';
  static const fileNameRequired = 'fileNameRequired';
  static const commentEmpty = 'commentEmpty';
  static const issueNotFound = 'issueNotFound';
  static const issueWrongProject = 'issueWrongProject';
  static const rfiNotFound = 'rfiNotFound';
  static const dprNotFound = 'dprNotFound';
  static const dprWrongProject = 'dprWrongProject';
  static const dprAlreadySubmitted = 'dprAlreadySubmitted';
  static const dprNeedActivity = 'dprNeedActivity';
  static const documentNotFound = 'documentNotFound';
  static const folderNotFound = 'folderNotFound';
  static const parentFolderNotFound = 'parentFolderNotFound';
  static const drawingNotFound = 'drawingNotFound';
  static const pageOutOfRange = 'pageOutOfRange';
  static const pinOutOfBounds = 'pinOutOfBounds';
  static const parentRequired = 'parentRequired';
  static const audioPathRequired = 'audioPathRequired';
  static const checklistItemsRequired = 'checklistItemsRequired';
  static const headcountInvalid = 'headcountInvalid';
  static const materialRequired = 'materialRequired';
  static const quantityInvalid = 'quantityInvalid';
  static const photoEvidenceRequired = 'photoEvidenceRequired';
  static const photoRequiredOnFail = 'photoRequiredOnFail';
  static const emailRequired = 'emailRequired';
  static const selectProject = 'selectProject';
  static const unknownProject = 'unknownProject';
  static const pendingInviteExists = 'pendingInviteExists';
  static const inviteMissingId = 'inviteMissingId';
  static const cannotMoveStatus = 'cannotMoveStatus';
  static const remoteFailure = 'remoteFailure';
}

/// English fallback for logs / Exception.toString().
String englishAppErrorMessage(String code, {String? arg1, String? arg2}) {
  return switch (code) {
    AppErrorCodes.clientReadOnly => 'Client accounts are read-only',
    AppErrorCodes.clientReadOnlySiteOps =>
      'Client accounts are read-only for site ops',
    AppErrorCodes.clientCannotEditDpr => 'Client accounts cannot edit DPR',
    AppErrorCodes.clientCannotSubmitDpr => 'Client accounts cannot submit DPR',
    AppErrorCodes.clientCannotPin => 'Client accounts cannot pin drawings',
    AppErrorCodes.clientCannotVoice => 'Client accounts cannot add voice notes',
    AppErrorCodes.cannotAssign => 'Your role cannot assign work',
    AppErrorCodes.cannotChangeStatus => 'Your role cannot change status',
    AppErrorCodes.cannotUploadDocs => 'Your role cannot upload documents',
    AppErrorCodes.cannotManageFolders => 'Your role cannot manage folders',
    AppErrorCodes.onlyAdminsInvite => 'Only admins can invite users',
    AppErrorCodes.titleRequired => 'Title is required',
    AppErrorCodes.subjectRequired => 'Subject is required',
    AppErrorCodes.fileNameRequired => 'File name is required',
    AppErrorCodes.commentEmpty => 'Comment cannot be empty',
    AppErrorCodes.issueNotFound => 'Issue not found',
    AppErrorCodes.issueWrongProject => 'Issue is not in the active project',
    AppErrorCodes.rfiNotFound => 'RFI not found',
    AppErrorCodes.dprNotFound => 'DPR not found',
    AppErrorCodes.dprWrongProject => 'DPR is not in the active project',
    AppErrorCodes.dprAlreadySubmitted => "Today's DPR is already submitted",
    AppErrorCodes.dprNeedActivity => 'Add at least one activity before submit',
    AppErrorCodes.documentNotFound => 'Document not found',
    AppErrorCodes.folderNotFound => 'Folder not found in active project',
    AppErrorCodes.parentFolderNotFound => 'Parent folder not found',
    AppErrorCodes.drawingNotFound => 'Drawing not found',
    AppErrorCodes.pageOutOfRange => 'Page out of range',
    AppErrorCodes.pinOutOfBounds => 'Pin must be within the drawing page',
    AppErrorCodes.parentRequired => 'Parent record is required',
    AppErrorCodes.audioPathRequired => 'Audio path is required',
    AppErrorCodes.checklistItemsRequired => 'Add checklist items',
    AppErrorCodes.headcountInvalid => 'Headcount must be > 0',
    AppErrorCodes.materialRequired => 'Material required',
    AppErrorCodes.quantityInvalid => 'Quantity must be > 0',
    AppErrorCodes.photoEvidenceRequired =>
      'Photo evidence required for ${arg1 ?? ''}',
    AppErrorCodes.photoRequiredOnFail =>
      'Photo required on fail: ${arg1 ?? ''}',
    AppErrorCodes.emailRequired => 'Valid email required',
    AppErrorCodes.selectProject => 'Select at least one project',
    AppErrorCodes.unknownProject => 'Unknown project: ${arg1 ?? ''}',
    AppErrorCodes.pendingInviteExists =>
      'Pending invite already exists for ${arg1 ?? ''}',
    AppErrorCodes.inviteMissingId => 'Invite created but no inviteId returned',
    AppErrorCodes.cannotMoveStatus =>
      'Cannot move from ${arg1 ?? ''} to ${arg2 ?? ''}',
    AppErrorCodes.remoteFailure => arg1 ?? 'Remote failure',
    _ => code,
  };
}
