import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart' show adminInvitesRepositoryProvider;
import '../domain/admin_invite_models.dart';

export '../../auth/presentation/auth_controller.dart'
    show adminInvitesRepositoryProvider;

final adminInvitesProvider = StreamProvider<List<AdminInvite>>((ref) {
  return ref.watch(adminInvitesRepositoryProvider).watchInvites();
});
