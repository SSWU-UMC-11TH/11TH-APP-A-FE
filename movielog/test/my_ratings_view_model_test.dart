import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

import 'support/fake_movie_log_services.dart';
import 'support/fake_tmdb_movie_service.dart';

void main() {
  late FakeRatingApiService ratingService;
  late FakeTmdbMovieService movieService;

  MyRatingsViewModel createViewModel() =>
      MyRatingsViewModel(ratingService, movieService, 1);

  setUp(() {
    ratingService = FakeRatingApiService();
    movieService = FakeTmdbMovieService()
      ..detailById = {
        680: fixtureMovie(680, title: '펄프 픽션'),
        13: fixtureMovie(13, title: '포레스트 검프'),
      };
  });

  test('학습용 memberId 1을 조회한다', () async {
    final viewModel = createViewModel();
    await viewModel.load();
    expect(ratingService.calls, [1]);
  });

  test('요청 중에는 loading, 끝나면 평점과 TMDB 영화를 묶어 success', () async {
    ratingService.gate = Completer<void>();
    final viewModel = createViewModel();
    expect(viewModel.status, MyRatingsLoadStatus.idle);

    final pending = viewModel.load();
    expect(viewModel.status, MyRatingsLoadStatus.loading);

    ratingService.gate!.complete();
    await pending;
    expect(viewModel.status, MyRatingsLoadStatus.success);
    expect(viewModel.ratings.map((entry) => entry.movie?.title), [
      '펄프 픽션',
      '포레스트 검프',
    ]);
    expect(viewModel.message, isNull);
  });

  test('빈 배열은 실패가 아니라 empty다', () async {
    ratingService.ratings = [];
    final viewModel = createViewModel();
    await viewModel.load();

    expect(viewModel.status, MyRatingsLoadStatus.empty);
    expect(viewModel.message, isNull);
  });

  test('평점 조회 실패는 error와 원인별 문구가 된다', () async {
    ratingService.failStatus = 404;
    final viewModel = createViewModel();
    await viewModel.load();

    expect(viewModel.status, MyRatingsLoadStatus.error);
    expect(viewModel.message, '존재하지 않는 회원입니다.');
  });

  test('TMDB에서 영화를 못 찾거나 실패해도 평점 기록은 남기고 안내한다', () async {
    movieService.detailById = {};
    movieService.failDetailIds = {13};
    final viewModel = createViewModel();
    await viewModel.load();

    expect(viewModel.status, MyRatingsLoadStatus.success);
    expect(viewModel.ratings, hasLength(2));
    expect(viewModel.ratings.every((entry) => entry.movie == null), isTrue);
    expect(viewModel.message, '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.');
  });

  test('같은 movieId는 한 번만 조회하고, 일시적 실패는 다음 로딩에서 다시 조회한다', () async {
    ratingService.ratings = [
      fixtureRating(1, movieId: 680),
      fixtureRating(2, movieId: 680),
      fixtureRating(3, movieId: 13),
    ];
    movieService.failDetailIds = {13};
    final viewModel = createViewModel();
    await viewModel.load();
    expect(movieService.detailCalls, [680, 13]);

    movieService.failDetailIds = {};
    await viewModel.load();
    // 680은 캐시를 쓰고, 실패했던 13만 다시 조회한다.
    expect(movieService.detailCalls, [680, 13, 13]);
    expect(viewModel.ratings.last.movie?.title, '포레스트 검프');
    expect(viewModel.message, isNull);
  });

  test('응답 전에 dispose되면 늦은 결과를 반영하지 않는다', () async {
    ratingService.gate = Completer<void>();
    final viewModel = createViewModel();
    final pending = viewModel.load();
    viewModel.dispose();

    ratingService.gate!.complete();
    await pending;
    expect(viewModel.status, MyRatingsLoadStatus.loading);
  });
}
