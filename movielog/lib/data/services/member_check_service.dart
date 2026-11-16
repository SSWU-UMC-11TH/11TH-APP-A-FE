import 'package:dio/dio.dart';

import '../models/check_result.dart';

/// 닉네임·이메일 중복 확인 API를 호출하는 Service.
///
/// 상태를 갖지 않으며, 통신 실패는 DioException 그대로 ViewModel에 전달한다.
class MemberCheckService {
  MemberCheckService(this._dio);

  final Dio _dio;

  /// 사용 가능하면 true, 이미 사용 중이면 false.
  Future<bool> checkNickname(String nickname) async {
    // 한글·공백·특수문자가 Path를 깨뜨리지 않도록 인코딩한다.
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v5/members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  /// 사용 가능하면 true, 이미 사용 중이면 false.
  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v5/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }
}
