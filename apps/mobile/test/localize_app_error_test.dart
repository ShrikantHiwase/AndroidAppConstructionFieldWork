import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:construction_field_app/core/errors/localize_app_error.dart';
import 'package:construction_field_app/features/issues/domain/issue_models.dart';
import 'package:construction_field_app/features/site_ops/domain/site_ops_models.dart';
import 'package:construction_field_app/l10n/app_localizations.dart';

void main() {
  test('localizeAppError maps codes to English and Hinglish', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final hi = lookupAppLocalizations(const Locale('hi'));

    final client = FieldRecordsException(AppErrorCodes.clientReadOnly);
    expect(localizeAppError(client, en), 'Client accounts are read-only');
    expect(localizeAppError(client, hi), contains('read-only'));
    expect(client.toString(), 'Client accounts are read-only');

    final move = FieldRecordsException(
      AppErrorCodes.cannotMoveStatus,
      arg1: IssueStatus.open.name,
      arg2: IssueStatus.closed.name,
    );
    expect(localizeAppError(move, en), contains('Open'));
    expect(localizeAppError(move, en), contains('Closed'));
    expect(localizeAppError(move, hi), contains(hi.issueStatusOpen));

    final photo = SiteOpsException(
      AppErrorCodes.photoRequiredOnFail,
      arg1: 'Edge protection',
    );
    expect(localizeAppError(photo, hi), contains('Edge protection'));
    expect(localizeAppError(photo, hi), contains('photo'));
  });
}
