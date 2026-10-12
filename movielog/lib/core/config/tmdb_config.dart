import 'package:flutter_dotenv/flutter_dotenv.dart';

/// `.env`에서 TMDB 설정값을 읽는 곳을 한 군데로 모은다.
///
/// Token 원문은 코드·로그에 남기지 않고, 키 문자열도 여기서만 사용한다.
abstract final class TmdbConfig {
  static String get accessToken => dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';
}
