import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';

import 'support/fake_movie_log_services.dart';
import 'support/fake_tmdb_movie_service.dart';

void main() {
  late FakeRatingApiService ratingService;

  setUp(() {
    ratingService = FakeRatingApiService();
  });

  MovieDetailViewModel create({int? memberId = 101}) =>
      MovieDetailViewModel(ratingService, memberId, fixtureMovie(550));

  test('학습용 회원 memberId와 TMDB 영화 id로 등록한다', () async {
    final viewModel = create();
    await viewModel.createRating(score: 5, comment: '최고의 영화!');

    expect(viewModel.submitStatus, SubmitStatus.success);
    expect(viewModel.myScore, 5);
    expect(ratingService.createCalls.single.memberId, 101);
    expect(ratingService.createCalls.single.body, {
      'movieId': 550,
      'score': 5,
      'comment': '최고의 영화!',
    });
  });

  test('회원가입 전(memberId null)이면 요청하지 않고 안내한다', () async {
    final viewModel = create(memberId: null);
    expect(viewModel.canRate, isFalse);
    await viewModel.createRating(score: 4);

    expect(viewModel.submitStatus, SubmitStatus.error);
    expect(viewModel.submitMessage, '먼저 회원가입을 완료해 주세요.');
    expect(ratingService.createCalls, isEmpty);
  });

  test('400·404·409는 서버 message와 code를 그대로 담는다', () async {
    final cases = <FakeFailure>[
      (status: 400, code: 'COMMON400', message: '별점은 5점 이하여야 합니다.'),
      (status: 404, code: 'COMMON404', message: '존재하지 않는 유저입니다.'),
      (status: 409, code: 'COMMON409', message: '이미 이 영화에 평점을 남기셨습니다.'),
    ];
    for (final failure in cases) {
      ratingService.createFailure = failure;
      final viewModel = create();
      await viewModel.createRating(score: 3);

      expect(viewModel.submitStatus, SubmitStatus.error);
      expect(viewModel.submitMessage, failure.message);
      expect(viewModel.submitCode, failure.code);
      expect(viewModel.myScore, isNull);
    }
  });

  test('저장 중 다시 눌러도 요청은 한 번만 간다', () async {
    ratingService.writeGate = Completer<void>();
    final viewModel = create();
    final first = viewModel.createRating(score: 4);
    await viewModel.createRating(score: 4);
    ratingService.writeGate!.complete();
    await first;

    expect(ratingService.createCalls, hasLength(1));
  });

  test('응답 전에 화면을 떠나면(dispose) 결과를 반영하지 않는다', () async {
    ratingService.writeGate = Completer<void>();
    final viewModel = create();
    final pending = viewModel.createRating(score: 4);
    viewModel.dispose();
    ratingService.writeGate!.complete();
    await pending;

    expect(viewModel.submitStatus, SubmitStatus.submitting);
  });
}
