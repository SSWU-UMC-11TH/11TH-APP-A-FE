/// 회원가입 요청 body (`POST /v6/members`, CreateMemberDto).
///
/// toJson은 Dart 객체 → 요청 JSON 방향이다.
/// 비밀번호는 사용자가 입력한 문자 자체가 의미 있으므로 trim하지 않는다.
/// 앞뒤 공백 허용 여부는 Form validation에서 처리한다.
class CreateMemberRequest {
  const CreateMemberRequest({
    required this.email,
    required this.password,
    required this.nickname,
  });

  final String email;
  final String password;
  final String nickname;

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
    'nickname': nickname.trim(),
  };

  /// 실수로 로그에 찍혀도 비밀번호가 남지 않도록 감춘다.
  @override
  String toString() =>
      'CreateMemberRequest(email: ${email.trim()}, nickname: ${nickname.trim()}, password: ***)';
}
