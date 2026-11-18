import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/widgets/rating_card.dart';
import 'package:movielog/widgets/rating_dialog.dart';

import 'support/fake_movie_log_services.dart';
import 'support/fake_tmdb_movie_service.dart';

late FakeTmdbMovieService movieService;
late FakeRatingApiService ratingService;

Future<void> pumpAt(
  WidgetTester tester,
  String location, {
  int? memberId = 101,
}) async {
  await tester.pumpWidget(
    MovieLogApp(
      movieService: movieService,
      signUpService: FakeSignUpService(),
      ratingApiService: ratingService,
      initialMemberId: memberId,
    ),
  );
  AppRouter.router.go(location);
  await tester.pumpAndSettle();
}

final Finder dialogConfirm = find.descendant(
  of: find.byType(RatingDialog),
  matching: find.widgetWithText(MovieLogButton, '확인'),
);

final Finder dialogComment = find.descendant(
  of: find.byType(RatingDialog),
  matching: find.byType(TextField),
);

bool isConfirmEnabled(WidgetTester tester) =>
    tester.widget<MovieLogButton>(dialogConfirm).onPressed != null;

/// RatingDialog 안의 [count]번째 별을 누른다.
Future<void> tapStar(WidgetTester tester, int count) async {
  final Finder stars = find.descendant(
    of: find.byType(RatingDialog),
    matching: find.byIcon(Icons.star),
  );
  await tester.tap(stars.at(count - 1));
  await tester.pumpAndSettle();
}

String commentText(WidgetTester tester) =>
    tester.widget<TextField>(dialogComment).controller!.text;

/// Snackbar 닫힘 Timer가 테스트 종료 후 남지 않도록 시간을 흘려 닫는다.
Future<void> flushSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    movieService = FakeTmdbMovieService()
      ..detailById = {
        550: fixtureMovie(550, title: '파이트 클럽'),
        680: fixtureMovie(680, title: '펄프 픽션'),
        13: fixtureMovie(13, title: '포레스트 검프'),
      };
    ratingService = FakeRatingApiService();
  });

  group('영화 상세 평점 등록', () {
    testWidgets('별점 아래 코멘트 칸이 있고, 별점을 골라야 확인이 활성화된다', (tester) async {
      await pumpAt(tester, '/movies/550');
      await tester.tap(find.widgetWithText(ElevatedButton, '평점 남기기'));
      await tester.pumpAndSettle();

      expect(dialogComment, findsOneWidget);
      expect(find.text('코멘트를 남겨보세요 (선택)'), findsOneWidget);

      await tester.enterText(dialogComment, '코멘트만 먼저');
      await tester.pump();
      expect(isConfirmEnabled(tester), isFalse);

      await tapStar(tester, 4);
      expect(find.text('4점'), findsOneWidget);
      expect(isConfirmEnabled(tester), isTrue);
      // 별점을 바꿔도(setState) 입력하던 코멘트가 유지된다.
      expect(commentText(tester), '코멘트만 먼저');
    });

    testWidgets('등록하면 TMDB id로 POST하고 같은 화면에서 성공 Snackbar를 보여준다', (
      tester,
    ) async {
      await pumpAt(tester, '/movies/550');
      await tester.tap(find.widgetWithText(ElevatedButton, '평점 남기기'));
      await tester.pumpAndSettle();
      await tapStar(tester, 5);
      await tester.enterText(dialogComment, '  최고의 영화!  ');
      await tester.tap(dialogConfirm);
      await tester.pumpAndSettle();

      expect(find.byType(RatingDialog), findsNothing);
      expect(ratingService.createCalls.single.memberId, 101);
      expect(ratingService.createCalls.single.body, {
        'movieId': 550,
        'score': 5,
        'comment': '최고의 영화!',
      });
      expect(
        find.text('평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.'),
        findsOneWidget,
      );
      await flushSnackBar(tester);

      // 마이페이지 목록에서 다시 조회해 확인한다.
      AppRouter.router.go('/my/ratings');
      await tester.pumpAndSettle();
      expect(find.text('파이트 클럽'), findsOneWidget);
      expect(find.text('최고의 영화!'), findsOneWidget);
    });

    testWidgets('409면 Dialog가 닫히지 않고 입력을 유지한 채 서버 message를 보여준다', (
      tester,
    ) async {
      ratingService.createFailure = (
        status: 409,
        code: 'COMMON409',
        message: '이미 이 영화에 평점을 남기셨습니다.',
      );
      await pumpAt(tester, '/movies/550');
      await tester.tap(find.widgetWithText(ElevatedButton, '평점 남기기'));
      await tester.pumpAndSettle();
      await tapStar(tester, 3);
      await tester.enterText(dialogComment, '다시 남기기');
      await tester.tap(dialogConfirm);
      await tester.pumpAndSettle();

      expect(find.byType(RatingDialog), findsOneWidget);
      expect(find.text('이미 이 영화에 평점을 남기셨습니다.'), findsOneWidget);
      expect(commentText(tester), '다시 남기기');
      expect(find.text('3점'), findsOneWidget);
      expect(isConfirmEnabled(tester), isTrue, reason: '로딩이 풀려 다시 시도할 수 있다');

      await tester.tap(find.widgetWithText(OutlinedButton, '취소'));
      await tester.pumpAndSettle();
      expect(find.text('평점을 등록하지 못했습니다. 이미 이 영화에 평점을 남기셨습니다.'), findsOneWidget);
      await flushSnackBar(tester);
    });

    testWidgets('취소하면 등록 요청을 보내지 않는다', (tester) async {
      await pumpAt(tester, '/movies/550');
      await tester.tap(find.widgetWithText(ElevatedButton, '평점 남기기'));
      await tester.pumpAndSettle();
      await tapStar(tester, 2);
      await tester.tap(find.widgetWithText(OutlinedButton, '취소'));
      await tester.pumpAndSettle();

      expect(find.byType(RatingDialog), findsNothing);
      expect(ratingService.createCalls, isEmpty);
    });

    testWidgets('학습용 회원가입 전에는 평점 버튼이 잠기고 가입으로 안내한다', (tester) async {
      await pumpAt(tester, '/movies/550', memberId: null);

      final ElevatedButton button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '평점 남기기'),
      );
      expect(button.enabled, isFalse);
      expect(find.text('평점을 남기려면 학습용 회원가입이 필요해요.'), findsOneWidget);

      AppRouter.router.go('/my/ratings');
      await tester.pumpAndSettle();
      expect(find.text('학습용 회원가입이 필요합니다.'), findsOneWidget);
      expect(ratingService.calls, isEmpty);
    });
  });

  group('내가 등록한 평점 수정·삭제', () {
    testWidgets('카드마다 수정·삭제 버튼이 있고, 수정은 기존 별점·코멘트를 채워 연다', (tester) async {
      await pumpAt(tester, '/my/ratings');

      expect(find.byTooltip('수정'), findsNWidgets(2));
      expect(find.byTooltip('삭제'), findsNWidgets(2));

      await tester.tap(find.byTooltip('수정').first);
      await tester.pumpAndSettle();
      expect(find.text('평점을 수정해 주세요'), findsOneWidget);
      expect(find.text('4점'), findsOneWidget);
      expect(commentText(tester), '다시 봐도 좋다');

      await tapStar(tester, 5);
      await tester.enterText(dialogComment, '세 번째 봐도 좋다');
      await tester.tap(dialogConfirm);
      await tester.pumpAndSettle();

      expect(ratingService.updateCalls.single.body, {
        'score': 5,
        'comment': '세 번째 봐도 좋다',
      });
      // 성공 후 목록을 다시 조회해 바뀐 값을 보여준다.
      expect(ratingService.calls, [101, 101]);
      expect(find.text('세 번째 봐도 좋다'), findsOneWidget);
      expect(find.text('별점 5 / 5'), findsOneWidget);
      await flushSnackBar(tester);
    });

    testWidgets('comment가 null인 평점은 빈 칸으로 열린다', (tester) async {
      await pumpAt(tester, '/my/ratings');
      await tester.tap(find.byTooltip('수정').last);
      await tester.pumpAndSettle();

      expect(find.text('3점'), findsOneWidget);
      expect(commentText(tester), '');
    });

    testWidgets('수정 저장 후 GET만 실패하면 Dialog는 닫히고 조회만 다시 시도할 수 있다', (
      tester,
    ) async {
      await pumpAt(tester, '/my/ratings');
      ratingService.failFetchAfterWrite = true;

      await tester.tap(find.byTooltip('수정').first);
      await tester.pumpAndSettle();
      await tapStar(tester, 2);
      await tester.tap(dialogConfirm);
      await tester.pumpAndSettle();

      expect(find.byType(RatingDialog), findsNothing);
      expect(
        find.text('저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.'),
        findsOneWidget,
      );
      await flushSnackBar(tester);

      ratingService.failFetchAfterWrite = false;
      ratingService.failNetwork = false;
      await tester.tap(find.widgetWithText(MovieLogButton, '조회 다시 시도'));
      await tester.pumpAndSettle();

      expect(find.text('별점 2 / 5'), findsOneWidget);
      expect(
        ratingService.updateCalls,
        hasLength(1),
        reason: 'PATCH는 다시 보내지 않는다',
      );
    });

    testWidgets('삭제 확인 Dialog에서 취소하면 요청하지 않고, 삭제하면 목록이 갱신되고 마지막엔 Empty다', (
      tester,
    ) async {
      await pumpAt(tester, '/my/ratings');

      await tester.tap(find.byTooltip('삭제').first);
      await tester.pumpAndSettle();
      expect(find.text('평점을 삭제할까요?'), findsOneWidget);
      expect(find.text('삭제한 평점은 복구할 수 없습니다.'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, '취소'));
      await tester.pumpAndSettle();
      expect(ratingService.deleteCalls, isEmpty);
      expect(find.byType(RatingCard), findsNWidgets(2));

      for (var remaining = 2; remaining > 0; remaining--) {
        await tester.tap(find.byTooltip('삭제').first);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(MovieLogButton, '삭제'));
        await tester.pumpAndSettle();
        await flushSnackBar(tester);
      }

      expect(ratingService.deleteCalls.map((c) => c.ratingId), [2, 3]);
      expect(find.text('아직 등록한 평점이 없어요'), findsOneWidget);
    });

    testWidgets('삭제가 403으로 실패하면 Dialog를 유지하고 Snackbar로 안내한다', (tester) async {
      ratingService.deleteFailure = (
        status: 403,
        code: 'COMMON403',
        message: '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
      );
      await pumpAt(tester, '/my/ratings');
      await tester.tap(find.byTooltip('삭제').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MovieLogButton, '삭제'));
      await tester.pumpAndSettle();

      expect(find.text('평점을 삭제할까요?'), findsOneWidget);
      expect(find.text('본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.'), findsOneWidget);
      await flushSnackBar(tester);
    });
  });

  group('다중 선택 삭제 (Challenge)', () {
    testWidgets('편집을 누르면 CheckBox가 나오고, 선택한 N개 삭제 후 일부 실패를 안내한다', (
      tester,
    ) async {
      ratingService.deleteFailIds = {3};
      await pumpAt(tester, '/my/ratings');

      await tester.tap(find.widgetWithText(TextButton, '편집'));
      await tester.pumpAndSettle();
      expect(find.text('0개 선택'), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(2));
      expect(find.byTooltip('수정'), findsNothing);
      final Finder deleteSelected = find.widgetWithText(
        MovieLogButton,
        '선택한 0개 삭제',
      );
      expect(tester.widget<MovieLogButton>(deleteSelected).onPressed, isNull);

      await tester.tap(find.byType(Checkbox).at(0));
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();
      expect(find.text('2개 선택'), findsOneWidget);

      await tester.tap(find.widgetWithText(MovieLogButton, '선택한 2개 삭제'));
      await tester.pumpAndSettle();
      expect(find.text('선택한 2개 평점을 삭제할까요?'), findsOneWidget);
      await tester.tap(find.widgetWithText(MovieLogButton, '삭제'));
      await tester.pumpAndSettle();

      expect(ratingService.deleteCalls.map((c) => c.ratingId), [2, 3]);
      expect(find.byType(RatingCard), findsOneWidget);
      expect(find.text('1개 선택'), findsOneWidget);
      expect(
        find.text('1개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.'),
        findsOneWidget,
      );
      await flushSnackBar(tester);

      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('수정'), findsOneWidget);
    });
  });
}
