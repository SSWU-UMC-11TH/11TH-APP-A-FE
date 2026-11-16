import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

import 'support/fake_tmdb_movie_service.dart';

void main() {
  test('Genre API로 장르를 받고 Discover를 page 1부터 불러 최대 30개를 만든다', () async {
    final service = FakeTmdbMovieService();
    final viewModel = MovieListViewModel(service);

    await viewModel.loadInitial();

    expect(viewModel.status, MovieListLoadStatus.success);
    expect(viewModel.genres, fixtureGenres);
    expect(viewModel.movies, hasLength(30));
    // 한 페이지 20개 기준으로 page 1, 2만 요청하고 멈춘다.
    expect(service.discoverCalls, [
      (page: 1, genreId: null),
      (page: 2, genreId: null),
    ]);
  });

  test('페이지 사이에 중복된 TMDB id는 하나만 남긴다', () async {
    final service = FakeTmdbMovieService(
      discover: (page, genreId) => TmdbMoviePageDto(
        page: page,
        // 페이지마다 앞 10개는 이전 페이지와 겹친다.
        results: [
          for (var i = 1; i <= 20; i++) fixtureMovie((page - 1) * 10 + i),
        ],
        totalPages: 10,
        totalResults: 200,
      ),
    );
    final viewModel = MovieListViewModel(service);

    await viewModel.loadInitial();

    final ids = viewModel.movies.map((movie) => movie.id).toList();
    expect(ids, hasLength(30));
    expect(ids.toSet(), hasLength(30));
    expect(service.discoverCalls.map((call) => call.page), [1, 2]);
  });

  test('마지막 페이지에서 멈추고 30개보다 적으면 있는 만큼만 보여준다', () async {
    final service = FakeTmdbMovieService(
      discover: FakeTmdbMovieService.pagedDiscover(totalPages: 1, perPage: 7),
    );
    final viewModel = MovieListViewModel(service);

    await viewModel.loadInitial();

    expect(viewModel.status, MovieListLoadStatus.success);
    expect(viewModel.movies, hasLength(7));
    expect(service.discoverCalls, hasLength(1));
  });

  test('장르를 고르면 with_genres로 page 1부터 다시 요청하고, 전체는 null로 요청한다', () async {
    final service = FakeTmdbMovieService();
    final viewModel = MovieListViewModel(service);
    await viewModel.loadInitial();
    service.discoverCalls.clear();

    await viewModel.selectGenre(28);

    expect(viewModel.selectedGenreId, 28);
    expect(service.discoverCalls, [
      (page: 1, genreId: 28),
      (page: 2, genreId: 28),
    ]);
    // 이전 목록을 거르지 않고 해당 장르 응답으로 교체한다.
    expect(viewModel.movies.first.id, 280001);

    service.discoverCalls.clear();
    await viewModel.selectGenre(null);

    expect(viewModel.selectedGenreId, isNull);
    expect(service.discoverCalls.first, (page: 1, genreId: null));
    expect(viewModel.movies.first.id, 1);
  });

  test('Discover 요청 중에는 장르를 바꿀 수 없다', () async {
    final service = FakeTmdbMovieService();
    final viewModel = MovieListViewModel(service);
    await viewModel.loadInitial();

    final gate = Completer<void>();
    service.discoverGate = gate;
    final loading = viewModel.selectGenre(28);
    expect(viewModel.isLoading, isTrue);

    await viewModel.selectGenre(35);
    expect(viewModel.selectedGenreId, 28);

    gate.complete();
    await loading;
    expect(viewModel.selectedGenreId, 28);
    expect(service.discoverCalls.any((call) => call.genreId == 35), isFalse);
  });

  test('결과가 없으면 Empty 상태가 된다', () async {
    final service = FakeTmdbMovieService(
      discover: FakeTmdbMovieService.pagedDiscover(totalPages: 1, perPage: 0),
    );
    final viewModel = MovieListViewModel(service);

    await viewModel.loadInitial();

    expect(viewModel.status, MovieListLoadStatus.empty);
    expect(viewModel.movies, isEmpty);
  });

  test('실패하면 Error 상태가 되고, 재시도는 마지막으로 고른 장르로 다시 요청한다', () async {
    final service = FakeTmdbMovieService();
    final viewModel = MovieListViewModel(service);
    await viewModel.loadInitial();

    service.failDiscover = true;
    await viewModel.selectGenre(35);
    expect(viewModel.status, MovieListLoadStatus.error);
    expect(viewModel.message, '해당 장르 영화를 불러오지 못했어요.');

    service.failDiscover = false;
    service.discoverCalls.clear();
    await viewModel.retry();

    expect(viewModel.status, MovieListLoadStatus.success);
    expect(service.discoverCalls.first, (page: 1, genreId: 35));
  });

  test('장르 목록부터 실패했다면 재시도는 처음부터 다시 불러온다', () async {
    final service = FakeTmdbMovieService()..failGenres = true;
    final viewModel = MovieListViewModel(service);

    await viewModel.loadInitial();
    expect(viewModel.status, MovieListLoadStatus.error);

    service.failGenres = false;
    await viewModel.retry();

    expect(viewModel.status, MovieListLoadStatus.success);
    expect(viewModel.genres, fixtureGenres);
  });

  test('응답 전에 화면을 떠나 dispose되면 늦은 결과를 반영하지 않는다', () async {
    final service = FakeTmdbMovieService();
    final gate = Completer<void>();
    service.discoverGate = gate;
    final viewModel = MovieListViewModel(service);

    final loading = viewModel.loadInitial();
    viewModel.dispose();
    gate.complete();

    await expectLater(loading, completes);
    expect(viewModel.movies, isEmpty);
  });
}
