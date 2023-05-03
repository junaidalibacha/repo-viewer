import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:oauth2/oauth2.dart';
import 'package:repo_viewer/auth/domain/auth_failure.dart';
import 'package:repo_viewer/auth/infrastructure/credentials_storage/credentials_storage.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:repo_viewer/core/infrastructure/dio_extension.dart';

import '../../core/shared/encoder.dart';

class GithubOAuthHttpClient extends http.BaseClient {
  final httpClinet = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return httpClinet.send(request);
  }
}

class GithubAuthenticator {
  GithubAuthenticator(this._crendentialsStorage, this._dio);
  final CrendentialsStorage _crendentialsStorage;
  final Dio _dio;

  static const clientId = '053a8e3e038d82cae3c8';
  static const clientSecret = '9eb0c157cf32fff3ddb58206b3971749c6e1d1e6';
  static const scopes = ['read:user', 'repo'];
  static final redirectUrl = Uri.parse('http://localhost:3000/callback');
  static final authEndPoint =
      Uri.parse('https://github.com/login/oauth/authorize');
  static final revocationEndPoint =
      Uri.parse('https://api.github.com/applications/$clientId/token');
  static final tokenEndPoint =
      Uri.parse('https://github.com/login/oauth/access_token');

  Future<Credentials?> getSignedInCrendentials() async {
    try {
      final storedCredentials = await _crendentialsStorage.read();
      if (storedCredentials != null) {
        if (storedCredentials.canRefresh && storedCredentials.isExpired) {
          final failureOrCredentials =
              await refreshCredentials(storedCredentials);
          return failureOrCredentials.fold((l) => null, (r) => r);
        }
      }
      return storedCredentials;
    } on PlatformException {
      return null;
    }
  }

  Future<bool> isSignedIn() => getSignedInCrendentials().then(
        (credentials) => credentials != null,
      );

  AuthorizationCodeGrant createGrant() {
    return AuthorizationCodeGrant(
      clientId,
      authEndPoint,
      tokenEndPoint,
      secret: clientSecret,
      httpClient: GithubOAuthHttpClient(),
    );
  }

  Uri getAuthorizationUrl(AuthorizationCodeGrant grant) {
    return grant.getAuthorizationUrl(redirectUrl, scopes: scopes);
  }

  Future<Either<AuthFailure, Unit>> handleAuthResponse(
    AuthorizationCodeGrant grant,
    Map<String, String> queryParams,
  ) async {
    try {
      final httpClient = await grant.handleAuthorizationResponse(queryParams);
      await _crendentialsStorage.save(httpClient.credentials);
      return right(unit);
    } on FormatException {
      return left(const AuthFailure.server());
    } on AuthorizationException catch (e) {
      return left(AuthFailure.server('${e.error}: ${e.description}'));
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }

  Future<Either<AuthFailure, Unit>> signOut() async {
    try {
      final accessToken =
          await _crendentialsStorage.read().then((value) => value?.accessToken);

      final usernameAndPassword =
          stringToBase64.encode('{$clientId:$clientSecret}');
      try {
        await _dio.deleteUri(
          revocationEndPoint,
          data: {
            'accessToken': accessToken,
          },
          options: Options(
            headers: {
              'Authorization': 'basic $usernameAndPassword',
            },
          ),
        );
      } on DioError catch (e) {
        if (e.isNoConnectionError) {
          debugPrint('Token not Deleted');
        } else {
          rethrow;
        }
      }
      return clearCredentialStorage();
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }

  Future<Either<AuthFailure, Unit>> clearCredentialStorage() async {
    try {
      await _crendentialsStorage.clear();
      return right(unit);
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }

  Future<Either<AuthFailure, Credentials>> refreshCredentials(
    Credentials credentials,
  ) async {
    try {
      final refreshCredentials = await credentials.refresh(
        identifier: clientId,
        secret: clientSecret,
        httpClient: GithubOAuthHttpClient(),
      );
      await _crendentialsStorage.save(refreshCredentials);
      return right(refreshCredentials);
    } on FormatException {
      return left(const AuthFailure.server());
    } on AuthorizationException catch (e) {
      return left(AuthFailure.server('${e.error}: ${e.description}'));
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }
}
