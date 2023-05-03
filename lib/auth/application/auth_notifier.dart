import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repo_viewer/auth/domain/auth_failure.dart';
import 'package:repo_viewer/auth/infrastructure/github_authenticator.dart';

part 'auth_notifier.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const AuthState._();
  const factory AuthState.initial() = _Initial;
  const factory AuthState.unAuthenticated() = _UnAuthenticated;
  const factory AuthState.authenticated() = _Authenticated;
  const factory AuthState.failure(AuthFailure failure) = _Failure;
}

typedef AuthUriCallBack = Future<Uri> Function(Uri authorizationUrl);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authenticator) : super(const AuthState.initial());
  final GithubAuthenticator _authenticator;

  Future<void> checkAndUpdateAuthState() async {
    state = (await _authenticator.isSignedIn())
        ? const AuthState.authenticated()
        : const AuthState.unAuthenticated();
  }

  Future<void> signIn(AuthUriCallBack authorizationCallBack) async {
    final grant = _authenticator.createGrant();

    final redirectUrl = await authorizationCallBack(
      _authenticator.getAuthorizationUrl(grant),
    );

    final failureOrSuccess = await _authenticator.handleAuthResponse(
      grant,
      redirectUrl.queryParameters,
    );

    state = failureOrSuccess.fold(
      (l) => AuthState.failure(l),
      (r) => const AuthState.authenticated(),
    );

    grant.close();
  }

  Future<void> signOut() async {
    final failureOrSuccess = await _authenticator.signOut();
    state = failureOrSuccess.fold(
      (l) => AuthState.failure(l),
      (r) => const AuthState.unAuthenticated(),
    );
  }
}
