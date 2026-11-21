import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'movie_log_logging_interceptor.dart';

/// 워크북 자체 백엔드 공통 옵션.
///
/// TMDB Client와 baseUrl·인증 Header가 다르므로 절대 하나로 합치지 않는다.
BaseOptions _movieLogOptions() {
  return BaseOptions(
    baseUrl: 'https://workbook.devnoco.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );
}

/// 공개 요청용 Client: 로그인, 회원가입, 중복 확인, 유저별 평점 조회.
///
/// AuthInterceptor가 없으므로 MovieLog JWT가 실리지 않는다.
Dio createMovieLogClient() {
  final dio = Dio(_movieLogOptions());
  if (kDebugMode) dio.interceptors.add(MovieLogLoggingInterceptor());
  return dio;
}

/// 보호 요청용 Client: 내 정보 조회·수정, 평점 등록·수정·삭제.
///
/// AuthInterceptor가 보호 path에만 Bearer 토큰을 붙인다.
/// 로깅 Interceptor는 토큰이 붙은 뒤에 실행되지만 Header를 마스킹해서 남긴다.
Dio createAuthMovieLogClient(TokenStorage storage) {
  final dio = Dio(_movieLogOptions());
  dio.interceptors.add(AuthInterceptor(storage));
  if (kDebugMode) dio.interceptors.add(MovieLogLoggingInterceptor());
  return dio;
}
