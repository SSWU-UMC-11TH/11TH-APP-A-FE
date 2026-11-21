import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

/// 자체 백엔드(v6)의 평점 API를 호출하는 Service.
///
/// API마다 성공 응답 계약이 다르므로 각각에 맞춰 처리한다.
/// - 조회 GET: 200 + 직접 배열
/// - 등록 POST: 201 + 공통 응답(result 계약 미확정 → 파싱하지 않음)
/// - 수정 PATCH: 200 + 공통 응답(result null)
/// - 삭제 DELETE: 204 + body 없음(JSON으로 파싱하지 않음)
class RatingApiService {
  RatingApiService(this._dio);

  final Dio _dio;

  /// 평점이 없으면 빈 배열을 돌려준다. 빈 배열은 실패가 아니다.
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v6/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    // Swagger 설명은 result가 ratingId 숫자라고 하지만 예시는 null이다.
    // 계약이 확정되기 전에는 result를 강제 캐스팅하지 않고, 등록 뒤 GET으로 확인한다.
    if (response.statusCode != 201) {
      throw StateError('예상하지 못한 등록 응답: ${response.statusCode}');
    }
  }

  /// comment를 생략하면 기존 후기가 null로 덮이므로 [UpdateRatingRequest]가
  /// 항상 comment 키를 포함해 보낸다.
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    await _dio.patch(
      '/v6/members/$memberId/ratings/$ratingId',
      data: UpdateRatingRequest(score: score, comment: comment).toJson(),
    );
  }

  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await _dio.delete(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    // 204는 body가 없다. response.data를 Map으로 캐스팅하지 않는다.
    if (response.statusCode != 204) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

/// 평점 조회 실패를 원인별 안내 문구로 바꾼다.
///
/// 400(memberId 형식 오류)과 404(없는 회원), 그 밖의 통신 실패를 하나로 뭉치지 않는다.
String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 평점 쓰기(등록·수정·삭제) 실패의 서버 message를 그대로 꺼낸다.
///
/// 같은 `COMMON404`라도 등록은 "유저", 수정·삭제는 "평점"을 가리키므로
/// code로 문구를 새로 만들지 않는다. code는 다음 UI 행동을 정할 때만 쓴다.
String writeErrorMessage(DioException error) {
  final common = CommonResponse.tryParseError(error.response?.data);
  return common?.message ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 403·404는 화면에 남은 목록이 서버 상태와 어긋났다는 뜻이므로 다시 조회해서 맞춘다.
///
/// 400(별점 범위)·409(중복 등록)는 같은 화면에서 값만 고치거나 다시 시도하면 된다.
bool shouldRefreshAfterRatingError(DioException error) {
  final code = CommonResponse.tryParseError(error.response?.data)?.code;
  return code == 'COMMON403' || code == 'COMMON404';
}

/// 평점 쓰기 실패를 Dialog까지 전달하는 예외. [message]는 화면에 그대로 보여준다.
class RatingWriteException implements Exception {
  const RatingWriteException(this.message, {this.code});

  final String message;

  /// 서버 공통 응답의 code(`COMMON403` 등). 통신 자체가 실패했으면 null.
  final String? code;

  factory RatingWriteException.fromDio(DioException error) {
    return RatingWriteException(
      writeErrorMessage(error),
      code: CommonResponse.tryParseError(error.response?.data)?.code,
    );
  }

  @override
  String toString() => 'RatingWriteException($code, $message)';
}
