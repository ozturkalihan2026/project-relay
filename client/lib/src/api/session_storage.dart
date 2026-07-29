import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SessionStorage {
  Future<String?> readRefreshToken();

  Future<void> writeRefreshToken(String token);

  Future<void> clear();
}

class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  static const _refreshTokenKey = 'relay.refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  @override
  Future<void> writeRefreshToken(String token) {
    return _storage.write(key: _refreshTokenKey, value: token);
  }

  @override
  Future<void> clear() {
    return _storage.delete(key: _refreshTokenKey);
  }
}
