import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';

void main() {
  test('snake_case key를 연결하고 num을 int·double로 바꾼다', () {
    final movie = TmdbMovieDto.fromJson({
      'id': 550,
      'title': '파이트 클럽',
      'overview': '줄거리',
      'poster_path': '/poster.jpg',
      'backdrop_path': '/backdrop.jpg',
      'release_date': '1999-10-15',
      'genre_ids': [18, 53],
      'vote_average': 8,
      'popularity': 120.5,
    });

    expect(movie.id, 550);
    expect(movie.posterPath, '/poster.jpg');
    expect(movie.backdropPath, '/backdrop.jpg');
    expect(movie.genreIds, [18, 53]);
    expect(movie.voteAverage, 8.0);
    expect(movie.popularity, 120.5);
    expect(movie.releaseYear, '1999');
  });

  test('null이거나 빠진 값은 기본값으로 채운다', () {
    final movie = TmdbMovieDto.fromJson({
      'id': 1,
      'title': null,
      'poster_path': null,
      'release_date': '',
    });

    expect(movie.title, '제목 없음');
    expect(movie.overview, '');
    expect(movie.posterPath, isNull);
    expect(movie.genreIds, isEmpty);
    expect(movie.voteAverage, 0);
    expect(movie.releaseYear, isNull);
  });

  test('페이지 응답은 results와 page metadata를 함께 변환한다', () {
    final page = TmdbMoviePageDto.fromJson({
      'page': 2,
      'results': [
        {'id': 1, 'title': 'A'},
        {'id': 2, 'title': 'B'},
      ],
      'total_pages': 100,
      'total_results': 2000,
    });

    expect(page.page, 2);
    expect(page.results.map((movie) => movie.id), [1, 2]);
    expect(page.totalPages, 100);
    expect(page.totalResults, 2000);
  });

  test('장르 응답의 id와 name을 그대로 사용한다', () {
    final genre = TmdbGenreDto.fromJson({'id': 28, 'name': '액션'});

    expect(genre.id, 28);
    expect(genre.name, '액션');
  });
}
