/// 유저별 평점 조회 응답 배열의 항목 하나.
///
/// `movieId`는 TMDB 영화 `id`와 같은 값이다.
/// `comment`는 명세상 nullable이므로 타입에도 그대로 반영한다.
class RatingDto {
  const RatingDto({
    required this.ratingId,
    required this.movieId,
    required this.score,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  final int ratingId;
  final int movieId;
  final int score;
  final String? comment;
  final DateTime createdAt;

  /// v6 응답부터 포함된다. v5 응답이나 fixture에는 없을 수 있다.
  final DateTime? updatedAt;

  factory RatingDto.fromJson(Map<String, dynamic> json) {
    final updatedAt = json['updatedAt'] as String?;
    return RatingDto(
      ratingId: (json['ratingId'] as num).toInt(),
      movieId: (json['movieId'] as num).toInt(),
      score: (json['score'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: updatedAt == null ? null : DateTime.parse(updatedAt),
    );
  }
}
