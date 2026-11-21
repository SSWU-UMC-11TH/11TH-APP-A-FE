import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/network/movie_log_logging_interceptor.dart';

import 'support/fake_movie_log_services.dart';

/// 실제 네트워크 대신 Interceptor를 거친 요청 Header만 기록하는 Adapter.
class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late MemoryTokenStorage storage;
  late _RecordingAdapter adapter;
  late Dio dio;

  setUp(() {
    storage = MemoryTokenStorage('jwt-1');
    adapter = _RecordingAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(storage));
  });

  String? authorizationOf(int index) =>
      adapter.requests[index].headers['Authorization'] as String?;

  test('보호 path(me·ratings)에만 MovieLog Bearer를 붙인다', () async {
    await dio.get('/v7/members/me');
    await dio.post('/v7/ratings');
    await dio.patch('/v7/ratings/12');
    await dio.post('/v7/auth/login');
    await dio.get('/v7/members/7/ratings'); // 공개 유저별 평점 조회
    await dio.get('/v7/members/nickname/abc');

    expect(authorizationOf(0), 'Bearer jwt-1');
    expect(authorizationOf(1), 'Bearer jwt-1');
    expect(authorizationOf(2), 'Bearer jwt-1');
    expect(authorizationOf(3), isNull);
    expect(authorizationOf(4), isNull);
    expect(authorizationOf(5), isNull);
  });

  test('다른 host(TMDB·이미지)로는 같은 path라도 토큰을 보내지 않는다', () async {
    await dio.get('https://api.themoviedb.org/v7/ratings');
    expect(authorizationOf(0), isNull);
  });

  test('매 요청마다 저장소를 다시 읽어 이전 토큰을 재사용하지 않는다', () async {
    await dio.get('/v7/members/me');
    storage.token = 'jwt-2';
    await dio.get('/v7/members/me');
    storage.token = null;
    await dio.get(
      '/v7/members/me',
      options: Options(headers: {'Authorization': 'Bearer stale'}),
    );

    expect(authorizationOf(0), 'Bearer jwt-1');
    expect(authorizationOf(1), 'Bearer jwt-2');
    expect(authorizationOf(2), isNull);
  });

  test('저장소 읽기 실패는 서버 응답 없는 unknown 오류로 거절한다', () async {
    storage.failRead = true;
    await expectLater(
      dio.get('/v7/members/me'),
      throwsA(
        isA<DioException>()
            .having((e) => e.type, 'type', DioExceptionType.unknown)
            .having((e) => e.response, 'response', isNull),
      ),
    );
    expect(adapter.requests, isEmpty);
  });

  test('로그에는 Authorization·password·accessToken 원문이 남지 않는다', () {
    expect(
      MovieLogLoggingInterceptor.maskHeaders({'Authorization': 'Bearer jwt-1'}),
      {'Authorization': 'Bearer ***'},
    );
    expect(
      MovieLogLoggingInterceptor.mask({
        'email': 'movie@umc.com',
        'password': 'Umc1234!',
      }),
      {'email': 'movie@umc.com', 'password': '***'},
    );
    expect(
      MovieLogLoggingInterceptor.mask({
        'isSuccess': true,
        'result': {'nickname': '영화광', 'accessToken': 'jwt-1'},
      }),
      {
        'isSuccess': true,
        'result': {'nickname': '영화광', 'accessToken': '***'},
      },
    );
  });
}
