/// 닉네임·이메일 중복 확인 응답 `{ "available": true }`.
///
/// v6에서도 중복 확인 성공 응답은 공통 Wrapper 없이 직접 객체를 유지하므로
/// 응답 body를 그대로 fromJson에 전달한다. (오류 응답만 CommonResponse 형식이다.)
class CheckResult {
  const CheckResult({required this.available});

  final bool available;

  factory CheckResult.fromJson(Map<String, dynamic> json) {
    return CheckResult(available: json['available'] as bool);
  }
}
