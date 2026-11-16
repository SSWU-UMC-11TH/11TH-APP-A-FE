import 'rating_dto.dart';
import 'tmdb_movie_dto.dart';

/// 자체 백엔드의 평점 기록과 그 movieId로 찾은 TMDB 영화 정보를 한 쌍으로 묶는다.
///
/// 평점의 주인은 자체 백엔드이므로 TMDB에서 영화를 찾지 못해도([movie]가 null)
/// 평점 기록은 그대로 남기고, 화면은 제목·포스터만 placeholder로 대신한다.
class RatingWithMovie {
  const RatingWithMovie({required this.rating, this.movie});

  final RatingDto rating;
  final TmdbMovieDto? movie;
}
