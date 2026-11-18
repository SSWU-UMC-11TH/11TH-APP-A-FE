import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

import 'support/fake_movie_log_services.dart';
import 'support/fake_tmdb_movie_service.dart';

void main() {
  late FakeRatingApiService ratingService;
  late FakeTmdbMovieService movieService;
  late MyRatingsViewModel viewModel;

  setUp(() async {
    ratingService = FakeRatingApiService();
    movieService = FakeTmdbMovieService()
      ..detailById = {
        680: fixtureMovie(680, title: '펄프 픽션'),
        13: fixtureMovie(13, title: '포레스트 검프'),
      };
    viewModel = MyRatingsViewModel(ratingService, movieService, 101);
    await viewModel.load();
  });

  group('수정', () {
    test('성공하면 score와 comment를 함께 보내고 목록을 다시 조회한다', () async {
      await viewModel.updateRating(
        ratingId: 2,
        score: 5,
        comment: '세 번째 봐도 좋다',
      );

      expect(ratingService.updateCalls.single.memberId, 101);
      expect(ratingService.updateCalls.single.ratingId, 2);
      expect(ratingService.updateCalls.single.body, {
        'score': 5,
        'comment': '세 번째 봐도 좋다',
      });
      expect(ratingService.calls, [101, 101]);
      expect(viewModel.ratings.first.rating.score, 5);
      expect(viewModel.ratings.first.rating.comment, '세 번째 봐도 좋다');
    });

    test('코멘트를 비우면 comment: null을 명시적으로 보낸다', () async {
      await viewModel.updateRating(ratingId: 2, score: 4, comment: null);

      final body = ratingService.updateCalls.single.body;
      expect(body.containsKey('comment'), isTrue);
      expect(body['comment'], isNull);
    });

    test('400은 다시 조회하지 않고 서버 message로 실패를 던진다', () async {
      ratingService.updateFailure = (
        status: 400,
        code: 'COMMON400',
        message: '별점은 5점 이하여야 합니다.',
      );

      await expectLater(
        viewModel.updateRating(ratingId: 2, score: 5),
        throwsA(
          isA<RatingWriteException>().having(
            (e) => e.message,
            'message',
            '별점은 5점 이하여야 합니다.',
          ),
        ),
      );
      expect(ratingService.calls, [101]);
    });

    test('403과 404는 문구를 구분하고, 목록을 다시 조회해 서버 상태와 맞춘다', () async {
      ratingService.updateFailure = (
        status: 403,
        code: 'COMMON403',
        message: '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
      );
      await expectLater(
        viewModel.updateRating(ratingId: 2, score: 5),
        throwsA(
          isA<RatingWriteException>()
              .having((e) => e.code, 'code', 'COMMON403')
              .having(
                (e) => e.message,
                'message',
                '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
              ),
        ),
      );
      expect(ratingService.calls, [101, 101]);

      ratingService.updateFailure = (
        status: 404,
        code: 'COMMON404',
        message: '존재하지 않는 평점입니다.',
      );
      await expectLater(
        viewModel.updateRating(ratingId: 2, score: 5),
        throwsA(
          isA<RatingWriteException>().having(
            (e) => e.message,
            'message',
            '존재하지 않는 평점입니다.',
          ),
        ),
      );
      expect(ratingService.calls, [101, 101, 101]);
    });

    test('저장은 성공했는데 재조회 GET만 실패하면 실패로 던지지 않고 경고만 남긴다', () async {
      ratingService.failFetchAfterWrite = true;

      await viewModel.updateRating(ratingId: 2, score: 5, comment: '좋다');

      expect(ratingService.updateCalls, hasLength(1));
      expect(viewModel.status, MyRatingsLoadStatus.error);
      expect(viewModel.refreshWarning, MyRatingsViewModel.refreshFailedText);

      // 조회만 다시 시도한다. PATCH를 다시 보내지 않는다.
      ratingService.failNetwork = false;
      ratingService.failFetchAfterWrite = false;
      await viewModel.load();
      expect(viewModel.status, MyRatingsLoadStatus.success);
      expect(viewModel.refreshWarning, isNull);
      expect(ratingService.updateCalls, hasLength(1));
    });
  });

  group('삭제', () {
    test('성공(204)하면 다시 조회하고, 마지막 항목까지 지우면 empty다', () async {
      await viewModel.deleteRating(2);
      expect(viewModel.status, MyRatingsLoadStatus.success);
      expect(viewModel.ratings.map((e) => e.rating.ratingId), [3]);

      await viewModel.deleteRating(3);
      expect(viewModel.status, MyRatingsLoadStatus.empty);
      expect(ratingService.deleteCalls.map((c) => c.ratingId), [2, 3]);
    });

    test('404면 목록을 다시 조회하고 실패를 던진다', () async {
      ratingService.deleteFailure = (
        status: 404,
        code: 'COMMON404',
        message: '존재하지 않는 평점입니다.',
      );
      await expectLater(
        viewModel.deleteRating(2),
        throwsA(isA<RatingWriteException>()),
      );
      expect(ratingService.calls, [101, 101]);
    });
  });

  group('다중 삭제 (Challenge)', () {
    test('편집 모드에서 선택·해제하고, 취소하면 선택을 모두 비운다', () {
      viewModel.toggleSelected(2);
      expect(viewModel.selectedRatingIds, isEmpty, reason: '편집 모드 전에는 선택 불가');

      viewModel.startSelecting();
      viewModel.toggleSelected(2);
      viewModel.toggleSelected(3);
      viewModel.toggleSelected(3);
      expect(viewModel.selectedRatingIds, {2});

      viewModel.cancelSelecting();
      expect(viewModel.isSelecting, isFalse);
      expect(viewModel.selectedRatingIds, isEmpty);
    });

    test('일부만 실패하면 성공한 항목만 사라지고 실패한 항목은 선택 상태로 남는다', () async {
      ratingService.deleteFailIds = {3};
      viewModel.startSelecting();
      viewModel.toggleSelected(2);
      viewModel.toggleSelected(3);

      final pending = viewModel.deleteSelectedRatings();
      expect(viewModel.isDeletingSelected, isTrue);
      final failed = await pending;

      expect(failed, 1);
      expect(viewModel.isDeletingSelected, isFalse);
      expect(viewModel.isSelecting, isTrue);
      expect(viewModel.selectedRatingIds, {3});
      expect(viewModel.ratings.map((e) => e.rating.ratingId), [3]);
    });

    test('모두 성공하면 편집 모드를 끝내고 목록을 다시 조회한다', () async {
      viewModel.startSelecting();
      viewModel.toggleSelected(2);
      viewModel.toggleSelected(3);

      expect(await viewModel.deleteSelectedRatings(), 0);
      expect(viewModel.isSelecting, isFalse);
      expect(viewModel.status, MyRatingsLoadStatus.empty);
    });
  });
}
