import 'package:dio/dio.dart';

import '../../core/network/api_error.dart';
import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

/// 공통 응답을 한 번 파싱하고 result의 [RatingDto]만 꺼낸다.
RatingDto parseRatingResult(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw StateError('평점 응답 형식이 올바르지 않습니다.');
  }
  final common = CommonResponse<RatingDto>.fromJson(
    data,
    (value) => RatingDto.fromJson(value as Map<String, dynamic>),
  );
  final rating = common.result;
  if (rating == null) throw StateError('평점 result가 없습니다.');
  return rating;
}

/// 공개 유저별 평점 조회는 공통 응답이 아니라 직접 배열이다.
List<RatingDto> parseRatingList(Object? data) {
  if (data is! List) throw StateError('평점 목록 응답은 배열이어야 합니다.');
  return data
      .map((value) => RatingDto.fromJson(value as Map<String, dynamic>))
      .toList();
}

/// 자체 백엔드(v7)의 평점 API를 호출하는 Service.
///
/// 메서드마다 다른 Client를 쓴다.
/// - 공개 조회 GET `/v7/members/{memberId}/ratings`: 공개용 Client, 200 + 직접 배열
/// - 등록 POST `/v7/ratings`: 보호용 Client, 201 + result Rating
/// - 수정 PATCH `/v7/ratings/{ratingId}`: 보호용 Client, 200 + result Rating
/// - 삭제 DELETE `/v7/ratings/{ratingId}`: 보호용 Client, 200 + result null (v6의 204 아님)
///
/// v6와 달리 보호 요청의 path·body에 memberId가 없다. 서버가 토큰으로 회원을 식별한다.
class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);

  final Dio _publicDio;
  final Dio _authDio;

  /// 공개 API라 memberId path를 유지한다.
  ///
  /// v7 로그인·내 정보 응답에는 memberId가 없어서 "로그인한 내 평점 전체"를
  /// 이 API로 복원할 수 없다. 명세에 없는 JWT claim으로 memberId를 추정하지 않는다.
  Future<List<RatingDto>> fetchMemberRatings(int memberId) async {
    final response = await _publicDio.get('/v7/members/$memberId/ratings');
    return parseRatingList(response.data);
  }

  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final response = await _authDio.post('/v7/ratings', data: request.toJson());
    return parseRatingResult(response.data);
  }

  /// PATCH는 부분 수정이 아니라 전체 교체다. comment를 생략하면 기존 후기가 null로 덮이므로
  /// [UpdateRatingRequest]가 항상 score·comment를 함께 보낸다.
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final response = await _authDio.patch(
      '/v7/ratings/$ratingId',
      data: UpdateRatingRequest(score: score, comment: comment).toJson(),
    );
    return parseRatingResult(response.data);
  }

  Future<void> deleteRating(int ratingId) async {
    final response = await _authDio.delete('/v7/ratings/$ratingId');
    if (response.statusCode != 200) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

/// 평점 쓰기(등록·수정·삭제) 실패를 화면 문구로 바꾼다.
///
/// 401·403처럼 다음 행동이 정해진 code는 고정 문구로, 나머지(400·404·409)는
/// 서버 message를 그대로 보여준다.
String writeErrorMessage(DioException error) {
  final code = apiErrorCode(error);
  if (isSessionExpiredCode(code)) return '로그인이 만료됐어요. 다시 로그인해 주세요.';
  if (code == 'RATING403_1') return '본인이 작성한 평점만 수정하거나 삭제할 수 있어요.';
  if (code == 'RATING404_1') return '이미 삭제된 평점이에요. 목록을 새로고침했어요.';
  return apiErrorMessage(error) ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 평점 쓰기 실패를 Dialog까지 전달하는 예외. [message]는 화면에 그대로 보여준다.
class RatingWriteException implements Exception {
  const RatingWriteException(this.message, {this.code});

  final String message;

  /// 서버 공통 응답의 code(`RATING403_1` 등). 통신 자체가 실패했으면 null.
  final String? code;

  factory RatingWriteException.fromDio(DioException error) {
    return RatingWriteException(
      writeErrorMessage(error),
      code: apiErrorCode(error),
    );
  }

  @override
  String toString() => 'RatingWriteException($code, $message)';
}
