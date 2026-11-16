import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/models/movie.dart';
import 'package:movielog/services/fake_movie_service.dart';

void main() {
  const FakeMovieService service = FakeMovieService();

  test('성공 모드는 800ms 이상 기다린 뒤 Mock 영화 목록을 돌려준다', () async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final List<Movie> result = await service.fetchMovies();
    stopwatch.stop();

    expect(result, movies);
    // 최소 800ms 이상 Loading 화면이 보여야 한다.
    expect(
      stopwatch.elapsed,
      greaterThanOrEqualTo(const Duration(milliseconds: 800)),
    );
  });

  test('빈 목록 모드는 빈 목록을 돌려준다', () async {
    final List<Movie> result = await service.fetchMovies(
      mode: MovieLoadMode.empty,
    );

    expect(result, isEmpty);
  });

  test('실패 모드는 MovieLoadException으로 완료된다', () async {
    await expectLater(
      service.fetchMovies(mode: MovieLoadMode.failure),
      throwsA(isA<MovieLoadException>()),
    );
  });
}
