import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/widgets/common_app_bar.dart';
import 'package:movielog/widgets/genre_chip_list.dart';
import 'package:movielog/widgets/movie_card.dart';
import 'package:movielog/widgets/movie_grid.dart';
import 'package:movielog/widgets/movie_list_error.dart';
import 'package:movielog/widgets/stat_item.dart';

import 'support/fake_tmdb_movie_service.dart';

late FakeTmdbMovieService service;

/// GoRouter는 앱 전체에서 하나만 사용하므로 테스트마다 시작 위치로 되돌린다.
Future<void> pumpAppAtStart(WidgetTester tester) async {
  await tester.pumpWidget(MovieLogApp(movieService: service));
  AppRouter.router.go('/start');
  await tester.pumpAndSettle();
}

/// 시작 화면에서 회원가입을 거쳐 홈까지 이동한다.
Future<void> goToHome(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ElevatedButton, '시작하기'));
  await tester.pumpAndSettle();
  // 2주차부터 회원가입은 유효한 입력과 약관 동의가 있어야 진행된다.
  await tester.enterText(find.byType(TextFormField).at(0), '무비러버');
  await tester.enterText(find.byType(TextFormField).at(1), 'movie@example.com');
  await tester.enterText(find.byType(TextFormField).at(2), 'password123');
  await tester.tap(find.byType(Checkbox));
  await tester.pumpAndSettle();
  // 테스트 화면(800x600)에서는 가입 버튼이 아래로 벗어나므로 스크롤한 뒤 누른다.
  final Finder submitButton = find.widgetWithText(ElevatedButton, '가입하기');
  await tester.ensureVisible(submitButton);
  await tester.pumpAndSettle();
  await tester.tap(submitButton);
  await tester.pumpAndSettle();
  // 가입 완료 Snackbar 닫힘 Timer가 테스트 종료 후 남지 않도록 시간을 흘려 닫는다.
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// GridView는 화면에 보이는 카드만 만들므로 Grid에 전달된 영화 수로 확인한다.
int gridMovieCountOf(WidgetTester tester) =>
    tester.widget<MovieGrid>(find.byType(MovieGrid)).movies.length;

void main() {
  setUp(() {
    service = FakeTmdbMovieService(
      popular: [
        for (var id = 1; id <= 20; id++) fixtureMovie(id, title: '인기 영화 $id'),
      ],
    );
  });

  testWidgets('시작 화면의 로고, 문구, 버튼이 표시된다', (WidgetTester tester) async {
    await pumpAppAtStart(tester);

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('영화의 순간을\n기록하세요'), findsOneWidget);
    expect(find.text('보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '시작하기'), findsOneWidget);
  });

  testWidgets('시작하기와 회원가입을 거쳐 홈으로 이동하고 뒤로 갈 수 없다', (WidgetTester tester) async {
    await pumpAppAtStart(tester);
    await goToHome(tester);

    expect(find.text('오늘은 어떤\n영화를 볼까요?'), findsOneWidget);
    // Popular 응답 중 앞 5개만 가로 목록에 표시된다.
    expect(find.byType(MovieCard), findsNWidgets(5));
    expect(find.text('인기 영화 6'), findsNothing);
    // go로 이동했으므로 홈에서는 돌아갈 화면이 없다.
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('NavigationBar로 영화 목록과 마이페이지를 전환한다', (WidgetTester tester) async {
    await pumpAppAtStart(tester);
    await goToHome(tester);

    await tester.tap(find.byIcon(Icons.movie_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('전체'), findsOneWidget);
    expect(find.text('액션'), findsOneWidget);
    expect(gridMovieCountOf(tester), 30);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('내 프로필'), findsOneWidget);
  });

  testWidgets('홈에서 상세로 이동하고 뒤로 돌아온다', (WidgetTester tester) async {
    await pumpAppAtStart(tester);
    await goToHome(tester);

    final Finder detailButton = find.widgetWithText(ElevatedButton, '상세보기');
    await tester.ensureVisible(detailButton);
    await tester.pumpAndSettle();
    await tester.tap(detailButton);
    await tester.pumpAndSettle();
    expect(find.text('Cinema Archive'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '평점 남기기'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    // 상세 화면이 닫히고 스크롤 위치가 유지된 홈 화면으로 돌아온다.
    expect(find.text('Cinema Archive'), findsNothing);
    expect(detailButton, findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('장르 Chip을 누르면 with_genres로 다시 요청해 목록을 바꾼다', (
    WidgetTester tester,
  ) async {
    await pumpAppAtStart(tester);
    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();
    expect(find.text('영화 1'), findsOneWidget);
    service.discoverCalls.clear();

    await tester.tap(find.text('액션'));
    await tester.pumpAndSettle();

    expect(service.discoverCalls.first, (page: 1, genreId: 28));
    expect(find.text('영화 280001'), findsOneWidget);
    expect(find.text('영화 1'), findsNothing);

    service.discoverCalls.clear();
    await tester.tap(find.text('전체'));
    await tester.pumpAndSettle();
    expect(service.discoverCalls.first, (page: 1, genreId: null));
    expect(find.text('영화 1'), findsOneWidget);
  });

  testWidgets('Discover 요청 중에는 장르 Chip이 잠긴다', (WidgetTester tester) async {
    await pumpAppAtStart(tester);
    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();

    final Completer<void> gate = Completer<void>();
    service.discoverGate = gate;
    await tester.tap(find.text('액션'));
    await tester.pump();
    expect(
      tester.widget<GenreChipList>(find.byType(GenreChipList)).enabled,
      isFalse,
    );

    await tester.tap(find.text('코미디'));
    await tester.pump();
    gate.complete();
    await tester.pumpAndSettle();

    expect(
      tester.widget<GenreChipList>(find.byType(GenreChipList)).selectedGenreId,
      28,
    );
    expect(service.discoverCalls.any((call) => call.genreId == 35), isFalse);
  });

  testWidgets('목록 요청이 실패하면 Error 화면에서 다시 시도할 수 있다', (
    WidgetTester tester,
  ) async {
    service.failDiscover = true;
    await pumpAppAtStart(tester);
    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();
    expect(find.byType(MovieListError), findsOneWidget);

    service.failDiscover = false;
    await tester.tap(find.widgetWithText(FilledButton, '다시 시도'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieGrid), findsOneWidget);
  });

  testWidgets('영화 카드를 누르면 TMDB id로 상세에 가고 평점 Dialog가 열린다', (
    WidgetTester tester,
  ) async {
    await pumpAppAtStart(tester);
    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();

    // 테스트 화면(800x600)에서는 카드 제목이 아래로 벗어나므로 카드 자체를 누른다.
    await tester.tap(find.byType(MovieCard).first);
    await tester.pumpAndSettle();
    expect(AppRouter.router.state.uri.path, '/movies/1');
    expect(find.text('Cinema Archive'), findsOneWidget);
    // 상세 이미지 아래 줄거리는 스크롤 전이라 화면 밖에 있다.
    expect(find.text('줄거리 1', skipOffstage: false), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, '평점 남기기'));
    await tester.pumpAndSettle();

    expect(find.text('영화는 어떠셨나요?'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '확인'), findsOneWidget);
  });

  testWidgets('URL로 직접 들어와 영화 정보가 없으면 찾을 수 없다고 안내한다', (
    WidgetTester tester,
  ) async {
    await pumpAppAtStart(tester);
    AppRouter.router.go('/movies/1');
    await tester.pumpAndSettle();

    expect(find.text('찾을 수 없는 영화예요'), findsOneWidget);
  });

  testWidgets('즐겨찾기를 누르면 Snackbar로 결과를 안내한다', (WidgetTester tester) async {
    await pumpAppAtStart(tester);
    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();
    // 테스트 화면(800x600)에서는 카드 제목이 아래로 벗어나므로 카드 자체를 누른다.
    await tester.tap(find.byType(MovieCard).first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, '즐겨찾기'));
    await tester.pump();
    expect(find.text('영화 1을(를) 즐겨찾기에 추가했어요.'), findsOneWidget);

    // Snackbar 표시 애니메이션이 끝나야 닫힘 Timer가 시작되므로
    // 먼저 settle한 뒤 시간을 흘려 앞선 Snackbar를 닫는다.
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '즐겨찾기 완료'));
    await tester.pump();
    expect(find.text('영화 1을(를) 즐겨찾기에서 삭제했어요.'), findsOneWidget);
  });

  testWidgets('프로필 화면에 공용 AppBar, 통계 3개, 장르 Chip 3개, 수정 버튼이 표시된다', (
    WidgetTester tester,
  ) async {
    await pumpAppAtStart(tester);
    AppRouter.router.go('/my');
    await tester.pumpAndSettle();

    expect(find.byType(CommonAppBar), findsOneWidget);
    expect(find.text('내 프로필'), findsOneWidget);
    expect(find.text('무비러버'), findsOneWidget);
    expect(find.byType(StatItem), findsNWidgets(3));
    expect(find.text('342'), findsOneWidget);
    expect(find.byType(Chip), findsNWidgets(3));
    expect(find.widgetWithText(TextButton, '프로필 수정'), findsOneWidget);
  });
}
