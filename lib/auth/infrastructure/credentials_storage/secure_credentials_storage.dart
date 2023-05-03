import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2/oauth2.dart';
import 'package:repo_viewer/auth/infrastructure/credentials_storage/credentials_storage.dart';

class SecureCredentialsStorage implements CrendentialsStorage {
  SecureCredentialsStorage(this._storage);
  final FlutterSecureStorage _storage;

  static const _key = 'oauth2_credentials';

  Credentials? _cachedCredentials;

  @override
  Future<Credentials?> read() async {
    if (_cachedCredentials != null) {
      return _cachedCredentials;
    }
    final jsonCredentials = await _storage.read(key: _key);
    if (jsonCredentials == null) {
      return null;
    }
    try {
      _cachedCredentials = Credentials.fromJson(jsonCredentials);
      return _cachedCredentials;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(Credentials credentials) {
    _cachedCredentials = credentials;
    return _storage.write(key: _key, value: credentials.toJson());
  }

  @override
  Future<void> clear() {
    _cachedCredentials = null;
    return _storage.delete(key: _key);
  }
}
