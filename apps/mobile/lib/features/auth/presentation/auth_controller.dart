import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../admin/data/firebase_admin_invites_repository.dart';
import '../../admin/data/local_admin_invites_repository.dart';
import '../../admin/domain/admin_invites_repository.dart';
import '../../../core/l10n/app_locale_provider.dart';
import '../../../core/secure/secure_store.dart';
import '../../../l10n/app_localizations.dart';
import '../data/fake_auth_repository.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override sharedPreferencesProvider in main()');
});

/// Fake by default (CI-safe). [main] overrides with [createSecureStore].
final secureStoreProvider = Provider<SecureStore>((ref) {
  return FakeSecureStore(ref.watch(sharedPreferencesProvider));
});

/// Overridden in [main] after [bootstrapFirebase]. Default keeps demo auth in tests.
final firebaseEnabledProvider = Provider<bool>((ref) => false);

/// Demo: local prefs invites. Firebase: callable `inviteMember` + Firestore list.
final adminInvitesRepositoryProvider = Provider<AdminInvitesRepository>((ref) {
  if (ref.watch(firebaseEnabledProvider)) {
    return FirebaseAdminInvitesRepository();
  }
  return LocalAdminInvitesRepository(ref.watch(sharedPreferencesProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final secure = ref.watch(secureStoreProvider);
  if (ref.watch(firebaseEnabledProvider)) {
    return FirebaseAuthRepository(prefs: prefs, secure: secure);
  }
  return FakeAuthRepository(
    prefs,
    invites: ref.watch(adminInvitesRepositoryProvider),
    secure: secure,
  );
});

enum AuthStatus { unknown, signedOut, locked, signedIn }

class AuthState {
  const AuthState({
    required this.status,
    this.session,
    this.errorMessage,
    this.isSubmitting = false,
  });

  final AuthStatus status;
  final AuthSession? session;
  final String? errorMessage;
  final bool isSubmitting;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    String? errorMessage,
    bool? isSubmitting,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref)
      : _repo = _ref.read(authRepositoryProvider),
        super(const AuthState(status: AuthStatus.unknown)) {
    _bootstrap();
  }

  final Ref _ref;
  final AuthRepository _repo;

  Future<void> _bootstrap() async {
    try {
      final session = await _repo.restoreSession();
      if (session == null) {
        state = const AuthState(status: AuthStatus.signedOut);
        return;
      }
      final fake = _repo;
      if (fake is FakeAuthRepository && fake.requiresUnlock) {
        state = AuthState(status: AuthStatus.locked, session: session);
      } else {
        state = AuthState(status: AuthStatus.signedIn, session: session);
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.signedOut,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(
      clearError: true,
      isSubmitting: true,
      status: AuthStatus.signedOut,
    );
    try {
      final session = await _repo.signInWithEmail(
        email: email,
        password: password,
      );
      state = AuthState(status: AuthStatus.signedIn, session: session);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.signedOut,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState(status: AuthStatus.signedOut);
  }

  Future<void> switchProject(String projectId) async {
    try {
      final session = await _repo.switchProject(projectId);
      state = AuthState(status: AuthStatus.signedIn, session: session);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _repo.setBiometricsEnabled(enabled);
    final session = state.session?.copyWith(biometricsEnabled: enabled);
    if (session != null) {
      state = AuthState(status: state.status, session: session);
    }
  }

  Future<void> unlock() async {
    final ok = await _repo.unlockWithBiometrics();
    if (ok && state.session != null) {
      state = AuthState(status: AuthStatus.signedIn, session: state.session);
    } else {
      final locale = _ref.read(appLocaleProvider) ?? const Locale('en');
      final l10n = lookupAppLocalizations(locale);
      state = state.copyWith(errorMessage: l10n.unlockFailed);
    }
  }

  Future<void> lockForResume() async {
    final repo = _repo;
    if (repo is FakeAuthRepository) {
      await repo.markLockedForResume();
      if (state.session != null && state.session!.biometricsEnabled) {
        state = AuthState(status: AuthStatus.locked, session: state.session);
      }
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

final authSessionProvider = Provider<AuthSession?>((ref) {
  return ref.watch(authControllerProvider).session;
});
