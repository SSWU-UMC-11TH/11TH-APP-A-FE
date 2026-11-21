import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/session_ratings_store.dart';

import 'support/fake_movie_log_services.dart';
import 'support/fake_tmdb_movie_service.dart';

void main() {
  late FakeRatingApiService ratingService;
  late FakeTmdbMovieService movieService;
  late MemoryTokenStorage storage;
  late AuthViewModel auth;
  late SessionRatingsStore store;

  /// 상세 화면처럼 서버에 등록하고 response Rating을 세션 Store에 넣는다.
  Future<int> createInSession(
    int movieId, {
    int score = 4,
    String? comment,
  }) async {
    final created = await ratingService.createRating(
      CreateRatingRequest(movieId: movieId, score: score, comment: comment),
    );
    store.upsert(auth.sessionVersion, created);
    return created.ratingId;
  }

  MyRatingsViewModel createViewModel() =>
      MyRatingsViewModel(ratingService, movieService, store, auth);

  setUp(() async {
    ratingService = FakeRatingApiService();
    movieService = FakeTmdbMovieService()
      ..detailById = {
        680: fixtureMovie(680, title: '펄프 픽션'),
        13: fixtureMovie(13, title: '포레스트 검프'),
      };
    storage = MemoryTokenStorage('token-movie@umc.com');
    auth = AuthViewModel(
      FakeAuthApiService(),
      FakeMemberApiService(storage),
      storage,
    );
    await auth.restoreSession();
    store = SessionRatingsStore(auth);
  });

  group('조회', () {
    test('서버 목록 GET 없이 이번 세션에 등록한 평점을 최근 순으로 보여준다', () async {
      await createInSession(680, comment: '다시 봐도 좋다');
      await createInSession(13);
      final viewModel = createViewModel();
      await viewModel.load();

      expect(ratingService.publicFetchCalls, isEmpty);
      expect(viewModel.status, MyRatingsLoadStatus.success);
      expect(viewModel.ratings.map((entry) => entry.movie?.title), [
        '포레스트 검프',
        '펄프 픽션',
      ]);
    });

    test('세션에 등록한 평점이 없으면 empty다', () async {
      final viewModel = createViewModel();
      await viewModel.load();
      expect(viewModel.status, MyRatingsLoadStatus.empty);
    });

    test('TMDB에 없는 movieId도 평점은 남기고 placeholder 안내를 한다', () async {
      await createInSession(999);
      final viewModel = createViewModel();
      await viewModel.load();

      expect(viewModel.ratings.single.movie, isNull);
      expect(viewModel.message, '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.');
    });

    test('로그아웃·재로그인으로 세션이 바뀌면 이전 세션 평점을 비운다', () async {
      await createInSession(680);
      final viewModel = createViewModel();
      await viewModel.load();
      expect(viewModel.ratings, hasLength(1));

      await auth.logout();
      await Future<void>.delayed(Duration.zero);
      expect(store.ratings, isEmpty);
      expect(viewModel.status, MyRatingsLoadStatus.empty);
    });
  });

  group('수정', () {
    test('score·comment를 함께 PATCH하고 response Rating으로 카드를 교체한다', () async {
      final id = await createInSession(680, score: 4, comment: '좋았어요');
      final viewModel = createViewModel();
      await viewModel.load();

      await viewModel.updateRating(ratingId: id, score: 2, comment: '다시 보니 별로');
      await Future<void>.delayed(Duration.zero);

      expect(ratingService.updateCalls.single.body, {
        'score': 2,
        'comment': '다시 보니 별로',
      });
      expect(viewModel.ratings.single.rating.score, 2);
      expect(viewModel.ratings.single.rating.comment, '다시 보니 별로');
    });

    test('코멘트를 비우면 comment: null을 명시적으로 보낸다', () async {
      final id = await createInSession(680);
      final viewModel = createViewModel();
      await viewModel.updateRating(ratingId: id, score: 3, comment: null);
      expect(ratingService.updateCalls.single.body, {
        'score': 3,
        'comment': null,
      });
    });

    test('403은 안내만 하고 로그아웃하지 않는다', () async {
      final id = await createInSession(680);
      ratingService.updateFailure = (
        status: 403,
        code: 'RATING403_1',
        message: '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
      );
      final viewModel = createViewModel();
      await viewModel.load();

      await expectLater(
        viewModel.updateRating(ratingId: id, score: 1),
        throwsA(
          isA<RatingWriteException>()
              .having((e) => e.code, 'code', 'RATING403_1')
              .having(
                (e) => e.message,
                'message',
                '본인이 작성한 평점만 수정하거나 삭제할 수 있어요.',
              ),
        ),
      );
      expect(auth.status, AuthStatus.signedIn);
      expect(store.ratings, hasLength(1));
    });

    test('404면 이미 없는 평점이므로 목록에서 빼고 실패를 던진다', () async {
      final id = await createInSession(680);
      ratingService.server.clear();
      final viewModel = createViewModel();
      await viewModel.load();

      await expectLater(
        viewModel.updateRating(ratingId: id, score: 1),
        throwsA(isA<RatingWriteException>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.status, MyRatingsLoadStatus.empty);
    });

    test('401이면 세션을 정리하고 실패를 던진다', () async {
      final id = await createInSession(680);
      ratingService.updateFailure = expiredToken;
      final viewModel = createViewModel();

      await expectLater(
        viewModel.updateRating(ratingId: id, score: 1),
        throwsA(isA<RatingWriteException>()),
      );
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isTrue);
    });
  });

  group('삭제', () {
    test('200이면 목록에서 빼고, 마지막 항목까지 지우면 empty다', () async {
      final id = await createInSession(680);
      final viewModel = createViewModel();
      await viewModel.load();

      await viewModel.deleteRating(id);
      await Future<void>.delayed(Duration.zero);
      expect(ratingService.deleteCalls, [id]);
      expect(viewModel.status, MyRatingsLoadStatus.empty);
    });

    test('다중 선택 삭제에서 일부만 실패하면 실패한 항목은 선택 상태로 남는다', () async {
      final first = await createInSession(680);
      final second = await createInSession(13);
      ratingService.deleteFailIds = {second};
      final viewModel = createViewModel();
      await viewModel.load();

      viewModel.startSelecting();
      viewModel.toggleSelected(first);
      viewModel.toggleSelected(second);
      final failed = await viewModel.deleteSelectedRatings();

      expect(failed, 1);
      expect(viewModel.selectedRatingIds, {second});
      expect(viewModel.isSelecting, isTrue);
      expect(viewModel.ratings.map((e) => e.rating.ratingId), [second]);
    });

    test('다중 삭제 중 401이면 남은 요청을 보내지 않고 세션을 정리한다', () async {
      final first = await createInSession(680);
      final second = await createInSession(13);
      ratingService.deleteFailure = expiredToken;
      final viewModel = createViewModel();
      await viewModel.load();

      viewModel.startSelecting();
      viewModel.toggleSelected(first);
      viewModel.toggleSelected(second);
      final failed = await viewModel.deleteSelectedRatings();

      expect(ratingService.deleteCalls, hasLength(1));
      expect(failed, 2);
      expect(auth.status, AuthStatus.signedOut);
    });

    test('응답 전에 로그아웃하면 늦게 온 삭제 결과로 새 세션 목록을 건드리지 않는다', () async {
      final id = await createInSession(680);
      ratingService.writeGate = Completer<void>();
      final viewModel = createViewModel();
      final pending = viewModel.deleteRating(id);
      await auth.logout();
      await auth.login('movie@umc.com', 'Umc1234!');
      // 쓰기 Gate가 아직 닫혀 있으므로 새 세션 평점은 Store에 직접 넣는다.
      store.upsert(auth.sessionVersion, fixtureRating(7, movieId: 13));
      ratingService.writeGate!.complete();
      await pending;

      expect(store.ratings.single.movieId, 13);
    });
  });
}
