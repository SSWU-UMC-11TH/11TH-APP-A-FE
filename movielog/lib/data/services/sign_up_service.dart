import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

/// 회원가입 화면이 쓰는 MovieLog API를 호출하는 Service (6주차 MemberCheckService).
///
/// 상태를 갖지 않으며, 통신 실패는 DioException 그대로 ViewModel에 전달한다.
/// 비밀번호가 담긴 요청 body는 로그로 남기지 않는다.
class SignUpService {
  SignUpService(this._dio);

  final Dio _dio;

  /// 사용 가능하면 true, 이미 사용 중이면 false.
  ///
  /// 성공 응답은 v5와 같은 직접 객체 `{ "available": true }`이고,
  /// 오류 응답만 v6 공통 형식으로 감싸진다.
  Future<bool> checkNickname(String nickname) async {
    // 한글·공백·특수문자가 Path를 깨뜨리지 않도록 인코딩한다.
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v6/members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  /// 사용 가능하면 true, 이미 사용 중이면 false.
  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v6/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  /// 회원가입. 성공(201)하면 공통 응답의 result에 [SignUpResult]가 담긴다.
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post('/v6/members', data: request.toJson());

    return CommonResponse<SignUpResult>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
  }
}

/// 회원가입 실패의 서버 message를 그대로 꺼낸다.
///
/// 400(비밀번호 형식 등)·409(이메일/닉네임 중복) 모두 message가 이미
/// 사용자에게 보여줄 문장이므로 code별 문구를 새로 만들지 않는다.
String writeSignUpErrorMessage(DioException error) {
  final common = CommonResponse.tryParseError(error.response?.data);
  return common?.message ?? '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}
