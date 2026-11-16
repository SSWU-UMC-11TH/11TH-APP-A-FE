import 'package:dio/dio.dart';

import '../models/rating_dto.dart';

/// 자체 백엔드의 평점 API를 호출하는 Service.
///
/// v5에는 조회 API만 있으므로 평점 등록·수정·삭제는 아직 다루지 않는다.
class RatingApiService {
  RatingApiService(this._dio);

  final Dio _dio;

  /// 평점이 없으면 빈 배열을 돌려준다. 빈 배열은 실패가 아니다.
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v5/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
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
