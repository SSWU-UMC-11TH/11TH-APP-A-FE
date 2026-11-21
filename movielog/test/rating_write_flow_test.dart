import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/widgets/delete_rating_dialog.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/widgets/rating_card.dart';
import 'package:movielog/widgets/rating_dialog.dart';

import 'support/fake_movie_log_services.dart';
import 'support/fake_tmdb_movie_service.dart';

late FakeTmdbMovieService movieService;
late FakeMovieLogBackend backend;

Future<void> pumpAt(WidgetTester tester, String location) =>
    pumpMovieLogApp(tester, backend, movieService, location: location);

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

/// 상세 화면에서 Dialog를 열어 별점·코멘트를 등록한다.
Future<void> registerOnDetail(
  WidgetTester tester,
  int movieId, {
  int score = 4,
  String comment = '',
}) async {
  routerOf(tester).go('/movies/$movieId');
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ElevatedButton, '평점 남기기'));
  await tester.pumpAndSettle();
  await tapStar(tester, score);
  if (comment.isNotEmpty) await tester.enterText(dialogComment, comment);
  await tester.tap(dialogConfirm);
  await tester.pumpAndSettle();
  await flushSnackBar(tester);
}

void main() {
  setUp(() {
    movieService = FakeTmdbMovieService()
      ..detailById = {
        550: fixtureMovie(550, title: '파이트 클럽'),
        680: fixtureMovie(680, title: '펄프 픽션'),
        13: fixtureMovie(13, title: '포레스트 검프'),
      };
    backend = FakeMovieLogBackend();
  });

  group('영화 상세 평점 등록 (v7 토큰 기반)', () {
    testWidgets('별점을 골라야 확인이 활성화되고, 등록하면 memberId 없이 POST한다', (tester) async {
      await pumpAt(tester, '/movies/550');
      await tester.tap(find.widgetWithText(ElevatedButton, '평점 남기기'));
      await tester.pumpAndSettle();
      expect(isConfirmEnabled(tester), isFalse);

      await tapStar(tester, 5);
      await tester.enterText(dialogComment, '최고의 영화!');
      expect(isConfirmEnabled(tester), isTrue);
      await tester.tap(dialogConfirm);
      await tester.pumpAndSettle();

      expect(find.byType(RatingDialog), findsNothing);
      expect(backend.ratingService.createCalls.single, {
        'movieId': 550,
        'score': 5,
        'comment': '최고의 영화!',
      });
      expect(
        find.text('평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.'),
        findsOneWidget,
      );
      await flushSnackBar(tester);
    });

    testWidgets('409면 Dialog를 유지한 채 기존 기록 확인을 안내하고 로그인 상태를 유지한다', (
      tester,
    ) async {
      backend.ratingService.createFailure = (
        status: 409,
        code: 'RATING409_1',
        message: '이미 이 영화에 평점을 남기셨습니다.',
      );
      await pumpAt(tester, '/movies/550');
      await tester.tap(find.widgetWithText(ElevatedButton, '평점 남기기'));
      await tester.pumpAndSettle();
      await tapStar(tester, 3);
      await tester.enterText(dialogComment, '두 번째 기록');
      await tester.tap(dialogConfirm);
      await tester.pumpAndSettle();

      expect(find.byType(RatingDialog), findsOneWidget);
      expect(
        find.text('이미 이 영화에 평점을 남기셨습니다. 마이페이지에서 기존 기록을 확인해 주세요.'),
        findsOneWidget,
      );
      expect(commentText(tester), '두 번째 기록');
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('취소하면 등록 요청을 보내지 않는다', (tester) async {
      await pumpAt(tester, '/movies/550');
      await tester.tap(find.widgetWithText(ElevatedButton, '평점 남기기'));
      await tester.pumpAndSettle();
      await tapStar(tester, 4);
      await tester.tap(find.widgetWithText(OutlinedButton, '취소'));
      await tester.pumpAndSettle();

      expect(backend.ratingService.createCalls, isEmpty);
    });

    testWidgets('토큰이 만료(401)되면 로그인 화면으로 이동하고 만료 Snackbar를 한 번 보여준다', (
      tester,
    ) async {
      backend.ratingService.createFailure = expiredToken;
      await pumpAt(tester, '/movies/550');
      await tester.tap(find.widgetWithText(ElevatedButton, '평점 남기기'));
      await tester.pumpAndSettle();
      await tapStar(tester, 4);
      await tester.tap(dialogConfirm);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(RatingDialog), findsNothing);
      expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsOneWidget);
      expect(backend.tokenStorage.token, isNull);
      await flushSnackBar(tester);
    });
  });

  group('이번 세션에 등록한 평점 수정·삭제', () {
    testWidgets('등록 response Rating이 목록 카드가 되고, 수정은 기존 값을 채워 PATCH한다', (
      tester,
    ) async {
      await pumpAt(tester, '/home');
      await registerOnDetail(tester, 680, score: 4, comment: '다시 봐도 좋다');
      routerOf(tester).go('/my/ratings');
      await tester.pumpAndSettle();

      expect(find.byType(RatingCard), findsOneWidget);
      expect(find.text('펄프 픽션'), findsOneWidget);
      expect(find.text('별점 4 / 5'), findsOneWidget);

      await tester.tap(find.byTooltip('수정'));
      await tester.pumpAndSettle();
      expect(find.text('평점을 수정해 주세요'), findsOneWidget);
      expect(commentText(tester), '다시 봐도 좋다');

      await tapStar(tester, 2);
      await tester.tap(dialogConfirm);
      await tester.pumpAndSettle();

      expect(backend.ratingService.updateCalls.single.body, {
        'score': 2,
        'comment': '다시 봐도 좋다',
      });
      expect(find.text('별점 2 / 5'), findsOneWidget);
      expect(find.text('평점을 수정했습니다.'), findsOneWidget);
      await flushSnackBar(tester);
    });

    testWidgets('삭제가 403이면 Dialog를 유지하고 안내만 하며, 성공하면 Empty가 된다', (
      tester,
    ) async {
      await pumpAt(tester, '/home');
      await registerOnDetail(tester, 680);
      routerOf(tester).go('/my/ratings');
      await tester.pumpAndSettle();

      backend.ratingService.deleteFailure = (
        status: 403,
        code: 'RATING403_1',
        message: '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
      );
      await tester.tap(find.byTooltip('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(DeleteRatingDialog),
          matching: find.widgetWithText(MovieLogButton, '삭제'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DeleteRatingDialog), findsOneWidget);
      expect(find.text('본인이 작성한 평점만 수정하거나 삭제할 수 있어요.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      await flushSnackBar(tester);

      backend.ratingService.deleteFailure = null;
      await tester.tap(
        find.descendant(
          of: find.byType(DeleteRatingDialog),
          matching: find.widgetWithText(MovieLogButton, '삭제'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DeleteRatingDialog), findsNothing);
      expect(find.text('이번 세션에 등록한 평점이 없어요'), findsOneWidget);
      await flushSnackBar(tester);
    });

    testWidgets('편집에서 선택한 N개를 삭제하고 일부 실패를 안내한다', (tester) async {
      await pumpAt(tester, '/home');
      await registerOnDetail(tester, 680);
      await registerOnDetail(tester, 13);
      routerOf(tester).go('/my/ratings');
      await tester.pumpAndSettle();
      expect(find.byType(RatingCard), findsNWidgets(2));

      // 최근 등록(13)이 위에 있다. 13(ratingId 101)만 삭제 실패하게 한다.
      backend.ratingService.deleteFailIds = {101};
      await tester.tap(find.widgetWithText(TextButton, '편집'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).at(0));
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MovieLogButton, '선택한 2개 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MovieLogButton, '삭제'));
      await tester.pumpAndSettle();

      expect(
        find.text('1개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.'),
        findsOneWidget,
      );
      expect(find.byType(RatingCard), findsOneWidget);
      expect(find.text('포레스트 검프'), findsOneWidget);
      await flushSnackBar(tester);
    });

    testWidgets('로그아웃 후 다시 로그인하면 이전 세션 평점은 보이지 않는다', (tester) async {
      await pumpAt(tester, '/home');
      await registerOnDetail(tester, 680);

      routerOf(tester).go('/my');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '로그아웃'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'movie@umc.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Umc1234!');
      await tester.tap(find.widgetWithText(MovieLogButton, '로그인'));
      await tester.pumpAndSettle();

      routerOf(tester).go('/my/ratings');
      await tester.pumpAndSettle();
      expect(find.byType(RatingCard), findsNothing);
      expect(find.text('이번 세션에 등록한 평점이 없어요'), findsOneWidget);
    });
  });
}
