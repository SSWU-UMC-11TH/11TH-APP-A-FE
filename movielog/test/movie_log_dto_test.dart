import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/check_result.dart';
import 'package:movielog/data/models/rating_dto.dart';

void main() {
  test('v5 중복 확인 응답은 Wrapper 없이 available을 그대로 읽는다', () {
    expect(CheckResult.fromJson({'available': true}).available, isTrue);
    expect(CheckResult.fromJson({'available': false}).available, isFalse);
  });

  test('평점 응답의 num을 int로, createdAt을 DateTime으로 바꾼다', () {
    final rating = RatingDto.fromJson({
      'ratingId': 12,
      'movieId': 550,
      'score': 5,
      'comment': '최고의 영화!',
      'createdAt': '2026-09-06T12:14:03.000Z',
      'updatedAt': '2026-09-06T12:14:03.000Z',
    });

    expect(rating.ratingId, 12);
    expect(rating.movieId, 550);
    expect(rating.score, 5);
    expect(rating.comment, '최고의 영화!');
    expect(rating.createdAt, DateTime.utc(2026, 9, 6, 12, 14, 3));
  });

  test('comment가 null이면 null 그대로 둔다', () {
    final rating = RatingDto.fromJson({
      'ratingId': 3,
      'movieId': 13,
      'score': 3,
      'comment': null,
      'createdAt': '2026-11-15T19:00:27.361Z',
    });

    expect(rating.comment, isNull);
  });
}
