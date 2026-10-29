import 'package:dio/dio.dart';

import '../models/tmdb_movie_page.dart';

// HTTP 요청과 DTO 변환만 담당한다. 개수 제한 같은 화면 정책은 ViewModel이 맡는다.
class TmdbMovieService {
  TmdbMovieService(this._dio);
  final Dio _dio;

  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async {
    final response = await _dio.get(
      '/movie/popular',
      queryParameters: {'language': 'ko-KR', 'page': page},
    );
    return TmdbMoviePageDto.fromJson(response.data as Map<String, dynamic>);
  }
}
