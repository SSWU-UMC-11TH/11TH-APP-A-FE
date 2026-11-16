/// 닉네임·이메일 중복 확인 응답 `{ "available": true }`.
///
/// v5는 공통 Wrapper가 없으므로 응답 body를 그대로 fromJson에 전달한다.
/// (6주차 이후 API의 `result` Wrapper와 파싱 방식이 다르다.)
class CheckResult {
  const CheckResult({required this.available});

  final bool available;

  factory CheckResult.fromJson(Map<String, dynamic> json) {
    return CheckResult(available: json['available'] as bool);
  }
}
