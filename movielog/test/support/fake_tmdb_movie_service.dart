import 'dart:async';

import 'package:dio/dio.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

TmdbMovieDto fixtureMovie(int id, {String? title, String? posterPath}) {
  return TmdbMovieDto(
    id: id,
    title: title ?? '영화 $id',
    overview: '줄거리 $id',
    posterPath: posterPath,
    backdropPath: null,
    releaseDate: '2025-01-01',
    genreIds: const [28],
    voteAverage: 7.5,
    popularity: 100,
  );
}

const List<TmdbGenreDto> fixtureGenres = [
  TmdbGenreDto(id: 28, name: '액션'),
  TmdbGenreDto(id: 35, name: '코미디'),
  TmdbGenreDto(id: 18, name: '드라마'),
];

/// TMDB 서버 대신 fixture를 돌려주는 Service.
///
/// Discover 요청의 page·genreId를 기록해 ViewModel이 어떤 조건으로 요청했는지 확인한다.
class FakeTmdbMovieService implements TmdbMovieService {
  FakeTmdbMovieService({
    List<TmdbMovieDto>? popular,
    this.genres = fixtureGenres,
    TmdbMoviePageDto Function(int page, int? genreId)? discover,
  }) : popular = popular ?? [for (var id = 1; id <= 20; id++) fixtureMovie(id)],
       discover = discover ?? pagedDiscover(totalPages: 5);

  List<TmdbMovieDto> popular;
  List<TmdbGenreDto> genres;
  TmdbMoviePageDto Function(int page, int? genreId) discover;

  bool failPopular = false;
  bool failGenres = false;
  bool failDiscover = false;

  /// 설정하면 Discover 응답이 이 Completer가 끝날 때까지 기다린다.
  Completer<void>? discoverGate;

  final List<({int page, int? genreId})> discoverCalls = [];

  /// 장르마다 다른 id를 갖는 20개짜리 페이지를 [totalPages]만큼 돌려준다.
  static TmdbMoviePageDto Function(int, int?) pagedDiscover({
    required int totalPages,
    int perPage = 20,
  }) {
    return (int page, int? genreId) {
      final base = (genreId ?? 0) * 10000 + (page - 1) * perPage;
      return TmdbMoviePageDto(
        page: page,
        results: [for (var i = 1; i <= perPage; i++) fixtureMovie(base + i)],
        totalPages: totalPages,
        totalResults: totalPages * perPage,
      );
    };
  }

  DioException _error(String path) => DioException(
    requestOptions: RequestOptions(path: path),
    type: DioExceptionType.connectionError,
  );

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async {
    if (failPopular) throw _error('/movie/popular');
    return TmdbMoviePageDto(
      page: page,
      results: popular,
      totalPages: 1,
      totalResults: popular.length,
    );
  }

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    int? genreId,
  }) async {
    discoverCalls.add((page: page, genreId: genreId));
    final gate = discoverGate;
    if (gate != null) await gate.future;
    if (failDiscover) throw _error('/discover/movie');
    return discover(page, genreId);
  }

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async {
    if (failGenres) throw _error('/genre/movie/list');
    return genres;
  }
}
