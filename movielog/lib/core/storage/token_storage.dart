import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// accessToken 저장·조회·삭제 규칙을 인증 흐름에서 분리한 추상화.
///
/// 로그인·로그아웃·Interceptor는 이 인터페이스에만 의존하므로
/// 테스트에서는 메모리 저장소로 바꿔 끼울 수 있다.
/// 비밀번호는 어떤 저장소에도 저장하지 않는다.
abstract interface class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> readAccessToken();
  Future<void> deleteAccessToken();
}

/// iOS Keychain·Android Keystore 기반 보안 저장소에 토큰을 보관한다.
///
/// SharedPreferences처럼 평문 key-value 저장소에는 토큰을 넣지 않는다.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  static const String _accessTokenKey = 'movielog.access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<void> saveAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  @override
  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<void> deleteAccessToken() {
    return _storage.delete(key: _accessTokenKey);
  }
}
