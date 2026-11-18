/// 회원가입 성공 응답의 `result` payload (SignUpResponseDto).
///
/// 응답 전체는 `CommonResponse<SignUpResult>`로 한 번만 파싱하고,
/// 이 클래스는 그 안의 result만 담당한다. 응답에 비밀번호는 포함되지 않는다.
class SignUpResult {
  const SignUpResult({
    required this.memberId,
    required this.email,
    required this.nickname,
  });

  final int memberId;
  final String email;
  final String nickname;

  factory SignUpResult.fromJson(Map<String, dynamic> json) {
    return SignUpResult(
      memberId: (json['memberId'] as num).toInt(),
      email: json['email'] as String,
      nickname: json['nickname'] as String,
    );
  }
}
