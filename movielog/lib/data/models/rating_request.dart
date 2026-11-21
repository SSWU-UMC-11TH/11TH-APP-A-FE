/// 서버 평점은 1~5 사이 정수다. 반 점(3.5 등)을 조용히 toInt()로 버리지 않고 막는다.
///
/// 별점 입력 Widget이 이미 정수 단위로만 선택하게 하지만, 남겨 두는 안전장치다.
int validateServerScore(double value) {
  if (value < 1 || value > 5 || value != value.roundToDouble()) {
    throw ArgumentError('서버 평점은 1~5 사이 정수여야 합니다.');
  }
  return value.toInt();
}

/// 코멘트 최대 길이. 서버 CreateRatingDto·UpdateRatingDto의 maxLength와 같다.
const int maxCommentLength = 500;

/// 평점 등록 요청 body (`POST /v7/ratings`, CreateRatingDto). memberId는 body에 넣지 않는다.
///
/// [movieId]는 영화 배열 index가 아니라 TMDB 영화 id(`TmdbMovieDto.id`)다.
class CreateRatingRequest {
  const CreateRatingRequest({
    required this.movieId,
    required this.score,
    this.comment,
  });

  final int movieId;
  final int score;
  final String? comment;

  /// 등록 comment는 선택 항목이므로 비어 있으면 빈 문자열 대신 생략한다.
  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'score': score,
    if (comment != null && comment!.trim().isNotEmpty)
      'comment': comment!.trim(),
  };
}

/// 평점 수정 요청 body (`PATCH .../ratings/{ratingId}`, UpdateRatingDto).
///
/// PATCH지만 부분 수정이 아니라 전체 교체다. score는 필수이고,
/// comment를 생략하면 기존 후기가 null로 덮인다.
/// 그래서 comment는 항상 키를 포함해 "유지(기존 값)"와 "삭제(null)" 의도를 드러낸다.
class UpdateRatingRequest {
  const UpdateRatingRequest({required this.score, required this.comment});

  final int score;
  final String? comment;

  Map<String, dynamic> toJson() {
    final trimmed = comment?.trim();
    return {
      'score': score,
      'comment': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    };
  }
}
