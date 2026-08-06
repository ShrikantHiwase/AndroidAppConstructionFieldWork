import '../../../core/constants/app_constants.dart';
import '../../auth/domain/auth_models.dart';
import 'admin_invite_models.dart';

abstract class AdminInvitesRepository implements InviteAuthBridge {
  Stream<List<AdminInvite>> watchInvites();

  Future<List<AdminInvite>> listInvites({InviteStatus? status});

  Future<AdminInvite> createInvite({
    required AuthSession session,
    required String email,
    required AppRole role,
    required List<String> projectIds,
  });
}
