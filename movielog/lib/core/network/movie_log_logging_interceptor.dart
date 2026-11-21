import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// MovieLog Client의 요청·응답을 기록하되 민감 정보는 가린다.
///
/// - Authorization Header → `Bearer ***`
/// - body의 `password`·`accessToken` → `***`
/// JWT 원문과 비밀번호가 Console·스크린샷·PR에 남지 않게 하기 위함이다.
class MovieLogLoggingInterceptor extends Interceptor {
  static const Set<String> _sensitiveKeys = {'password', 'accessToken'};

  /// Map·List를 재귀로 돌며 민감한 key의 값을 `***`로 바꾼 사본을 만든다.
  static Object? mask(Object? value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key: _sensitiveKeys.contains(entry.key)
              ? '***'
              : mask(entry.value),
      };
    }
    if (value is List) return value.map(mask).toList();
    return value;
  }

  static Map<String, dynamic> maskHeaders(Map<String, dynamic> headers) {
    final masked = Map<String, dynamic>.from(headers);
    if (masked.containsKey('Authorization')) {
      masked['Authorization'] = 'Bearer ***';
    }
    return masked;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[MovieLog 요청] ${options.method} ${options.uri}');
    debugPrint('[MovieLog 요청 Header] ${maskHeaders(options.headers)}');
    if (options.data != null) {
      debugPrint('[MovieLog 요청 Body] ${mask(options.data)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '[MovieLog 응답] ${response.statusCode} ${response.requestOptions.uri}',
    );
    debugPrint('[MovieLog 응답 Body] ${mask(response.data)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[MovieLog 오류] ${err.response?.statusCode} ${err.requestOptions.uri}',
    );
    debugPrint('[MovieLog 오류 Body] ${mask(err.response?.data)}');
    handler.next(err);
  }
}
