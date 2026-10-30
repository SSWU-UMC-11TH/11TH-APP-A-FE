import 'package:flutter_dotenv/flutter_dotenv.dart';

// .env 키 문자열과 누락 검사를 한 곳에 모은다.
abstract final class TmdbConfig {
  static const _accessTokenKey = 'TMDB_ACCESS_TOKEN';

  static String get accessToken => dotenv.env[_accessTokenKey] ?? '';

  // Token 원문을 출력하지 않고 존재 여부만 확인한다.
  static bool get hasAccessToken => accessToken.isNotEmpty;
}
