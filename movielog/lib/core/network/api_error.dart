import 'package:dio/dio.dart';

/// 서버 공통 오류 응답(`{ isSuccess, code, message, result }`)에서 code를 꺼낸다.
///
/// 통신 자체가 실패했거나 body가 공통 형식이 아니면 null이다.
String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final code = data['code'];
  return code is String ? code : null;
}

/// 서버 공통 오류 응답에서 사용자에게 보여줄 message를 꺼낸다.
String? apiErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final message = data['message'];
  return message is String ? message : null;
}

/// 보호 요청에서 토큰이 없거나(AUTH401_2)·무효하거나(AUTH401_3)·만료된(AUTH401_4) 경우.
///
/// 로그인 실패 `AUTH401_1`은 로그인 Form의 오류이므로 여기에 넣지 않는다.
/// 이 세 code만 현재 세션을 정리하는 후보다.
bool isSessionExpiredCode(String? code) =>
    code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
