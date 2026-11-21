/// v6부터 쓰기 API의 성공 응답과 모든 오류 응답이 공유하는 공통 형식 (v7 동일).
///
/// `{ isSuccess, code, message, result }` 네 필드로 성공 여부, 처리 결과 code,
/// 사용자 안내 message, 실제 데이터를 함께 전달한다.
/// [result]는 API마다 담기는 값이 다르므로 제네릭 [T]로 두고,
/// 값이 없거나 실패 응답이면 null이다.
///
/// v5부터 있던 중복 확인·평점 조회는 성공 시 기존 직접 객체/배열을 유지하므로
/// 그 성공 응답에는 이 Model을 쓰지 않는다.
class CommonResponse<T> {
  const CommonResponse({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
  });

  final bool isSuccess;
  final String code;
  final String message;
  final T? result;

  /// [parseResult]는 `result`가 null이 아닐 때만 호출한다.
  factory CommonResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) parseResult,
  ) {
    final rawResult = json['result'];
    return CommonResponse<T>(
      isSuccess: json['isSuccess'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      result: rawResult == null ? null : parseResult(rawResult),
    );
  }

  /// 오류 응답 body가 공통 형식이면 파싱하고, 아니면(HTML·빈 body 등) null을 돌려준다.
  static CommonResponse<Object?>? tryParseError(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    try {
      return CommonResponse<Object?>.fromJson(data, (value) => value);
    } on TypeError {
      return null;
    }
  }
}
