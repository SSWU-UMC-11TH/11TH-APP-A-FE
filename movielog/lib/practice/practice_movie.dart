/// 0주차 Dart 문법 연습에서 사용하는 영화 모델.
///
/// 3주차부터 화면에서 사용하는 모델은 `lib/models/movie.dart`의 `Movie`다.
class PracticeMovie {
  const PracticeMovie({
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
