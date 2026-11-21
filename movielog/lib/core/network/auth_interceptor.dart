import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// MovieLog 보호 API 요청에만 `Authorization: Bearer {MovieLog JWT}`를 붙인다.
///
/// 보호용 Client에만 등록하고, 그 안에서도 host·path로 한 번 더 거른다.
/// TMDB Client에는 절대 등록하지 않는다(TMDB에는 TMDB Read Access Token만 보낸다).
/// BuildContext나 화면 이동은 다루지 않는다. 401 처리는 ViewModel이 code로 판단한다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  static const String movieLogHost = 'workbook.devnoco.com';

  final TokenStorage _storage;

  /// 토큰이 필요한 v7 보호 API인지 판단한다. 공개 유저별 평점 조회는 포함하지 않는다.
  static bool isProtected(Uri uri) {
    final path = uri.path;
    return uri.host == movieLogHost &&
        (path == '/v7/members/me' ||
            path == '/v7/ratings' ||
            path.startsWith('/v7/ratings/'));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!isProtected(options.uri)) {
      handler.next(options);
      return;
    }
    // 이전 요청이나 다른 세션의 토큰을 재사용하지 않도록 매 요청마다 새로 읽는다.
    options.headers.remove('Authorization');
    try {
      final token = await _storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (_) {
      // 서버 401과 기기 저장소 실패는 다른 오류다. 응답 없이 unknown으로 거절한다.
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: StateError('인증 저장소를 읽지 못했습니다.'),
        ),
      );
    }
  }
}
