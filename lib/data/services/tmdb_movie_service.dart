import 'package:dio/dio.dart';

class TmdbMovieService {
  TmdbMovieService(this._dio);
  final Dio _dio;

  // Step 1에서는 응답 원본을 반환하고, Step 2에서 DTO 변환을 추가한다.
  Future<Map<String, dynamic>> fetchPopular({int page = 1}) async {
    final response = await _dio.get(
      '/movie/popular',
      queryParameters: {'language': 'ko-KR', 'page': page},
    );
    return response.data as Map<String, dynamic>;
  }
}
