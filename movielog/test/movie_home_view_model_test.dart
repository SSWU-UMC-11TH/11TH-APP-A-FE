import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';

import 'support/fake_tmdb_movie_service.dart';

void main() {
  test('Popular 첫 페이지에서 앞 5개만 보관한다', () async {
    final viewModel = MovieHomeViewModel(FakeTmdbMovieService());

    await viewModel.loadPopular();

    expect(viewModel.status, MovieHomeLoadStatus.success);
    expect(viewModel.popularMovies.map((movie) => movie.id), [1, 2, 3, 4, 5]);
  });

  test('결과가 5개보다 적으면 있는 만큼만 보관한다', () async {
    final service = FakeTmdbMovieService(
      popular: [fixtureMovie(1), fixtureMovie(2), fixtureMovie(3)],
    );
    final viewModel = MovieHomeViewModel(service);

    await viewModel.loadPopular();

    expect(viewModel.popularMovies, hasLength(3));
    expect(viewModel.status, MovieHomeLoadStatus.success);
  });

  test('결과가 없으면 Empty, 요청이 실패하면 Error 상태가 된다', () async {
    final service = FakeTmdbMovieService(popular: []);
    final viewModel = MovieHomeViewModel(service);

    await viewModel.loadPopular();
    expect(viewModel.status, MovieHomeLoadStatus.empty);

    service.failPopular = true;
    await viewModel.loadPopular();
    expect(viewModel.status, MovieHomeLoadStatus.error);
    expect(viewModel.message, '인기 영화를 불러오지 못했어요.');
  });
}
