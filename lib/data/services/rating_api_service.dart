import 'package:dio/dio.dart';

import '../models/rating_dto.dart';

class RatingApiService {
  RatingApiService(this._dio);
  final Dio _dio;

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get<dynamic>('/v5/members/$memberId/ratings');
    final rows = response.data as List<dynamic>;
    return rows
        .map((row) => RatingDto.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }
}

String writeMyRatingsErrorMessage(DioException error) {
  switch (error.response?.statusCode) {
    case 400:
      return '회원 번호 형식을 확인해 주세요.';
    case 404:
      return '존재하지 않는 회원입니다.';
    default:
      return '평점을 불러오지 못했습니다. 다시 시도해 주세요.';
  }
}
