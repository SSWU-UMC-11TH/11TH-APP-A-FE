import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

/// 영화 목록 화면의 상태.
///
/// Genre API로 Chip을 구성하고, Discover API를 page 1부터 불러와
/// TMDB `id` 기준으로 중복을 없앤 최대 30개를 보관한다.
class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);

  final TmdbMovieService _service;

  static const int maxMovieCount = 30;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];

  /// 선택된 장르 ID. null이면 "전체"이며 `with_genres`를 보내지 않는다.
  int? selectedGenreId;
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;

  /// 늦게 도착한 이전 요청의 결과를 무시하기 위한 요청 번호.
  int _requestVersion = 0;
  bool _disposed = false;

  bool get isLoading =>
      status == MovieListLoadStatus.idle ||
      status == MovieListLoadStatus.loading;

  /// 한 페이지 개수를 가정하지 않고, 30개가 모이거나 다음 페이지가 없을 때까지 요청한다.
  Future<List<TmdbMovieDto>> fetchUpToThirtyMovies({int? genreId}) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < maxMovieCount && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreId: genreId,
      );

      for (final movie in page.results) {
        // 페이지 사이에 같은 영화가 다시 와도 TMDB id가 같으면 하나만 남는다.
        byId[movie.id] = movie;
        if (byId.length == maxMovieCount) break;
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    return byId.values.take(maxMovieCount).toList();
  }

  Future<void> loadInitial() async {
    selectedGenreId = null;
    final version = ++_requestVersion;
    status = MovieListLoadStatus.loading;
    notifyListeners();

    try {
      final fetchedGenres = await _service.fetchGenres();
      final discovered = await fetchUpToThirtyMovies();

      if (_disposed || version != _requestVersion) return;
      genres = fetchedGenres;
      movies = discovered;
      status = movies.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } on DioException {
      if (_disposed || version != _requestVersion) return;
      status = MovieListLoadStatus.error;
      message = '영화를 불러오지 못했어요. 다시 시도해 주세요.';
    }

    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  /// 장르 Chip 선택. 기존 결과를 버리고 `with_genres`로 page 1부터 다시 요청한다.
  Future<void> selectGenre(int? genreId) async {
    // Discover 요청 중에는 장르를 바꾸지 않는다.
    if (isLoading) return;
    if (genreId == selectedGenreId && status != MovieListLoadStatus.error) {
      return;
    }
    await _loadMovies(genreId);
  }

  /// 실패한 요청을 같은 조건으로 다시 실행한다.
  Future<void> retry() {
    // 장르 목록부터 받지 못했다면 처음부터, 아니면 마지막으로 고른 장르로 다시 요청한다.
    if (genres.isEmpty) return loadInitial();
    return _loadMovies(selectedGenreId);
  }

  Future<void> _loadMovies(int? genreId) async {
    selectedGenreId = genreId;
    final version = ++_requestVersion;
    status = MovieListLoadStatus.loading;
    notifyListeners();

    try {
      final result = await fetchUpToThirtyMovies(genreId: genreId);
      if (_disposed || version != _requestVersion) return;
      movies = result;
      status = result.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } on DioException {
      if (_disposed || version != _requestVersion) return;
      status = MovieListLoadStatus.error;
      message = '해당 장르 영화를 불러오지 못했어요.';
    }

    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
