/// 영화 한 편의 정보를 담는 모델 클래스.
class Movie {
  const Movie({
    required this.title,
    required this.director,
    required this.releaseYear,
    this.myRating,
  });

  /// 영화 제목
  final String title;

  /// 감독 이름
  final String director;

  /// 개봉 연도
  final int releaseYear;

  /// 내가 매긴 평점 (아직 보지 않았다면 null)
  final double? myRating;

  /// 평점이 없으면 '평점 없음'으로 변환해 돌려준다.
  String get ratingLabel =>
      myRating == null ? '평점 없음' : '${myRating!.toStringAsFixed(1)}점';

  @override
  String toString() => '$title ($releaseYear) · $director · $ratingLabel';
}
