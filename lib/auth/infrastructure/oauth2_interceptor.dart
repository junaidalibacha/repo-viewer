import 'package:dio/dio.dart';
import 'package:repo_viewer/auth/application/auth_notifier.dart';

import 'github_authenticator.dart';

class OAuth2Interceptor extends Interceptor {
  final GithubAuthenticator _authenticator;
  final AuthNotifier _authNotifier;
  final Dio _dio;

  OAuth2Interceptor(this._authenticator, this._authNotifier, this._dio);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final credentials = await _authenticator.getSignedInCrendentials();
    final modifiedOptions = options
      ..headers.addAll(
        credentials == null
            ? {}
            : {'Authorization': 'beares ${credentials.accessToken}'},
      );
    handler.next(modifiedOptions);
  }

  @override
  Future<void> onError(DioError err, ErrorInterceptorHandler handler) async {
    final errResponse = err.response;
    if (errResponse != null && errResponse.statusCode == 401) {
      final credentials = await _authenticator.getSignedInCrendentials();

      credentials != null && credentials.canRefresh
          ? await _authenticator.refreshCredentials(credentials)
          : await _authenticator.clearCredentialStorage();
      await _authNotifier.checkAndUpdateAuthState();

      final refreshCredentials = await _authenticator.getSignedInCrendentials();
      if (refreshCredentials != null) {
        handler.resolve(
          await _dio.fetch(
            errResponse.requestOptions
              ..headers['Authorization'] =
                  'bearer ${refreshCredentials.accessToken}',
          ),
        );
      }
    }
  }
}
