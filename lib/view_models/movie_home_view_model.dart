import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieHomeLoadStatus { idle, loading, success, empty, error }

class MovieHomeViewModel extends ChangeNotifier {
  MovieHomeViewModel(this._service);
  final TmdbMovieService _service;

  static const _popularCount = 5;

  List<TmdbMovieDto> popularMovies = const [];
  // 인기 5개와 겹치지 않도록 그 다음 영화를 추천 카드에 쓴다. 없으면 숨긴다.
  TmdbMovieDto? heroMovie;
  MovieHomeLoadStatus status = MovieHomeLoadStatus.idle;
  String? message;

  bool _disposed = false;

  Future<void> loadPopular() async {
    status = MovieHomeLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final page = await _service.fetchPopular();
      // 5개보다 적게 와도 take는 있는 만큼만 반환한다.
      popularMovies = page.results.take(_popularCount).toList();
      heroMovie = page.results.skip(_popularCount).firstOrNull;
      status = popularMovies.isEmpty
          ? MovieHomeLoadStatus.empty
          : MovieHomeLoadStatus.success;
    } on DioException {
      status = MovieHomeLoadStatus.error;
      message = '인기 영화를 불러오지 못했어요.';
    } catch (error) {
      // 응답 형식이 달라 DTO 변환에 실패해도 Loading에 멈추지 않게 한다.
      debugPrint('[MovieHome] 응답 변환 실패: $error');
      status = MovieHomeLoadStatus.error;
      message = '인기 영화를 불러오지 못했어요.';
    }

    // 응답 전에 화면을 벗어났다면 dispose된 객체에 알리지 않는다.
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
