import '../models/movie.dart';

/// Mock Service가 어떤 결과로 완료될지 정하는 모드.
///
/// 실제 서버라면 네트워크 상황에 따라 저절로 갈리는 결과를,
/// 4주차에서는 화면 상태를 연습하기 위해 호출하는 쪽에서 직접 고른다.
enum MovieLoadMode { success, empty, failure }

/// 영화 목록을 불러오지 못했을 때 던지는 예외.
///
/// [message]는 디버깅용이며 화면에는 그대로 표시하지 않는다.
class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;

  @override
  String toString() => 'MovieLoadException: $message';
}

/// `Future.delayed`로 서버 응답을 흉내 내는 영화 목록 Service.
///
/// 화면은 이 Service가 내부에서 지연을 쓰는지, 실제 API를 호출하는지 알 필요가 없다.
class FakeMovieService {
  const FakeMovieService();

  /// 워크북 기준(최소 800ms)보다 길게 잡아 Loading 화면을 확인할 수 있게 한다.
  static const Duration _delay = Duration(seconds: 1);

  /// 영화 목록을 비동기로 불러온다.
  ///
  /// 완료 전에는 Loading, 값으로 완료되면 Success 또는 Empty,
  /// 오류로 완료되면 Error 화면을 보여주는 데 사용한다.
  // TODO(5주차 유저별 평점 조회 API): FakeMovieService를 Swagger의 실제 API Service로 교체한다.
  Future<List<Movie>> fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    await Future<void>.delayed(_delay);

    return switch (mode) {
      MovieLoadMode.success => movies,
      MovieLoadMode.empty => const <Movie>[],
      MovieLoadMode.failure => throw const MovieLoadException(
        '영화를 불러오지 못했습니다.',
      ),
    };
  }
}
