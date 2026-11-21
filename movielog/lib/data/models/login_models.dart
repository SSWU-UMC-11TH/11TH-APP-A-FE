/// 로그인 요청 body (`POST /v7/auth/login`, LoginRequestDto).
///
/// 비밀번호는 trim하지 않고 그대로 보내며, 어떤 저장소·로그에도 남기지 않는다.
class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
  };
}

/// 로그인 성공 응답의 `result` (LoginResponseDto).
///
/// v7 명세에는 memberId가 없다. JWT payload에 있을 것이라고 추정해 꺼내지 않는다.
class LoginResult {
  const LoginResult({required this.nickname, required this.accessToken});

  final String nickname;
  final String accessToken;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      nickname: json['nickname'] as String,
      accessToken: json['accessToken'] as String,
    );
  }

  /// 디버그 출력에 토큰 원문이 섞이지 않도록 가린다.
  @override
  String toString() => 'LoginResult(nickname: $nickname, accessToken: ***)';
}
