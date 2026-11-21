import 'package:dio/dio.dart';

import '../models/member_info.dart';

/// 내 정보 조회·수정 Service. 보호용 Client(AuthInterceptor 등록)를 받는다.
///
/// 사용자 식별은 path의 memberId가 아니라 Authorization Header의 토큰으로 한다.
class MemberApiService {
  MemberApiService(this._authDio);

  final Dio _authDio;

  Future<MemberInfo> fetchMe() async {
    final response = await _authDio.get('/v7/members/me');
    return parseMemberInfo(response.data);
  }

  /// 성공 응답의 result가 이미 최신 내 정보이므로 GET me를 다시 부르지 않는다.
  Future<MemberInfo> updateNickname(String nickname) async {
    final response = await _authDio.patch(
      '/v7/members/me',
      data: {'nickname': nickname},
    );
    return parseMemberInfo(response.data);
  }
}
