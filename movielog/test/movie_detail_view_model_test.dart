import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/session_ratings_store.dart';

import 'support/fake_movie_log_services.dart';
import 'support/fake_tmdb_movie_service.dart';

void main() {
  late FakeRatingApiService ratingService;
  late MemoryTokenStorage storage;
  late AuthViewModel auth;
  late SessionRatingsStore store;

  setUp(() async {
    ratingService = FakeRatingApiService();
    storage = MemoryTokenStorage('token-movie@umc.com');
    auth = AuthViewModel(
      FakeAuthApiService(),
      FakeMemberApiService(storage),
      storage,
    );
    await auth.restoreSession();
    store = SessionRatingsStore(auth);
  });

  MovieDetailViewModel create() =>
      MovieDetailViewModel(ratingService, store, auth, fixtureMovie(550));

  test('memberId 없이 TMDB 영화 id로 등록하고 response Rating을 세션 Store에 넣는다', () async {
    final viewModel = create();
    await viewModel.createRating(score: 5, comment: '최고의 영화!');

    expect(viewModel.submitStatus, SubmitStatus.success);
    expect(viewModel.myScore, 5);
    expect(ratingService.createCalls.single, {
      'movieId': 550,
      'score': 5,
      'comment': '최고의 영화!',
    });
    expect(ratingService.createCalls.single.containsKey('memberId'), isFalse);
    expect(store.ratings.single.ratingId, 100);
  });

  test('400·404는 서버 message, 409는 기존 기록 확인 안내를 덧붙인다', () async {
    final cases = <(FakeFailure, String)>[
      (
        (status: 400, code: 'COMMON400', message: '별점은 5점 이하여야 합니다.'),
        '별점은 5점 이하여야 합니다.',
      ),
      (
        (status: 404, code: 'MEMBER404_1', message: '해당 회원을 찾을 수 없습니다.'),
        '해당 회원을 찾을 수 없습니다.',
      ),
      (
        (status: 409, code: 'RATING409_1', message: '이미 이 영화에 평점을 남기셨습니다.'),
        '이미 이 영화에 평점을 남기셨습니다. 마이페이지에서 기존 기록을 확인해 주세요.',
      ),
    ];
    for (final (failure, expected) in cases) {
      ratingService.createFailure = failure;
      final viewModel = create();
      await viewModel.createRating(score: 3);

      expect(viewModel.submitStatus, SubmitStatus.error);
      expect(viewModel.submitMessage, expected);
      expect(viewModel.submitCode, failure.code);
      expect(viewModel.myScore, isNull);
      // 409는 안내만 하고 로그아웃하지 않는다.
      expect(auth.status, AuthStatus.signedIn);
    }
    expect(store.ratings, isEmpty);
  });

  test('401(AUTH401_4)이면 세션을 정리한다', () async {
    ratingService.createFailure = expiredToken;
    final viewModel = create();
    await viewModel.createRating(score: 4);

    expect(viewModel.submitStatus, SubmitStatus.error);
    expect(auth.status, AuthStatus.signedOut);
    expect(auth.sessionExpired, isTrue);
    expect(storage.token, isNull);
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

  test('응답 전에 로그아웃하면 늦게 온 등록 결과를 Store에 넣지 않는다', () async {
    ratingService.writeGate = Completer<void>();
    final viewModel = create();
    final pending = viewModel.createRating(score: 4);
    await auth.logout();
    ratingService.writeGate!.complete();
    await pending;

    expect(store.ratings, isEmpty);
    expect(viewModel.submitStatus, SubmitStatus.submitting);
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
