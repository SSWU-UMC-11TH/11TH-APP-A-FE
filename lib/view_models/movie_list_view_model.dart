import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/genre_preference.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service, {GenrePreference? genrePreference})
    : _genrePreference = genrePreference ?? GenrePreference();

  final TmdbMovieService _service;
  final GenrePreference _genrePreference;

  static const _maxMovies = 30;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];
  // 카드에서 genre_ids를 이름으로 바꿀 때 사용한다.
  Map<int, String> genreNameById = const {};
  // null이면 전체를 뜻한다.
  int? selectedGenreId;
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;

  int _requestVersion = 0;
  bool _disposed = false;

  bool get isLoading => status == MovieListLoadStatus.loading;

  // 30개가 되거나 더 이상 페이지가 없을 때까지 page 1부터 요청한다.
  Future<List<TmdbMovieDto>> _fetchUpToThirtyMovies({int? genreId}) async {
    // TMDB id를 key로 써서 페이지 사이 중복을 하나만 남긴다.
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < _maxMovies && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreId: genreId,
      );

      for (final movie in page.results) {
        byId[movie.id] = movie;
        if (byId.length == _maxMovies) break;
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    return byId.values.take(_maxMovies).toList();
  }

  Future<void> loadInitial() {
    return _load(
      errorMessage: '영화를 불러오지 못했어요. 다시 시도해 주세요.',
      fetch: () async {
        genres = await _service.fetchGenres();
        genreNameById = {for (final genre in genres) genre.id: genre.name};

        // 저장된 장르가 현재 장르 목록에 없으면 전체로 둔다.
        final savedGenreId = await _genrePreference.read();
        selectedGenreId = genres.any((genre) => genre.id == savedGenreId)
            ? savedGenreId
            : null;

        // Discover를 기다리는 동안 장르 Chip을 먼저 보여준다.
        if (!_disposed) notifyListeners();
        return _fetchUpToThirtyMovies(genreId: selectedGenreId);
      },
    );
  }

  Future<void> selectGenre(int? genreId) async {
    // 요청 중에는 장르를 바꿀 수 없다. 같은 장르를 다시 눌러도 요청하지 않는다.
    if (isLoading || genreId == selectedGenreId) return;

    selectedGenreId = genreId;
    _genrePreference.save(genreId).ignore();
    await _loadMovies();
  }

  // 장르 목록부터 실패했다면 처음부터, 아니면 같은 장르로 다시 요청한다.
  Future<void> retry() {
    return genres.isEmpty ? loadInitial() : _loadMovies();
  }

  Future<void> _loadMovies() {
    return _load(
      errorMessage: '해당 장르 영화를 불러오지 못했어요.',
      fetch: () => _fetchUpToThirtyMovies(genreId: selectedGenreId),
    );
  }

  Future<void> _load({
    required Future<List<TmdbMovieDto>> Function() fetch,
    required String errorMessage,
  }) async {
    final version = ++_requestVersion;
    status = MovieListLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final result = await fetch();
      // 화면을 벗어났거나 더 새로운 요청이 있으면 늦은 응답은 버린다.
      if (!_isCurrent(version)) return;
      movies = result;
      status = result.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } on DioException {
      if (!_isCurrent(version)) return;
      status = MovieListLoadStatus.error;
      message = errorMessage;
    } catch (error) {
      // 응답 형식이 달라 DTO 변환에 실패해도 Loading에 멈추지 않게 한다.
      debugPrint('[MovieList] 응답 변환 실패: $error');
      if (!_isCurrent(version)) return;
      status = MovieListLoadStatus.error;
      message = errorMessage;
    }

    notifyListeners();
  }

  bool _isCurrent(int version) => !_disposed && version == _requestVersion;

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
