import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/widgets/common_app_bar.dart';
import 'package:movielog/widgets/genre_chip_list.dart';
import 'package:movielog/widgets/movie_card.dart';
import 'package:movielog/widgets/movie_grid.dart';
import 'package:movielog/widgets/movie_list_error.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/widgets/my_ratings_entry.dart';
import 'package:movielog/widgets/stat_item.dart';

import 'support/fake_movie_log_services.dart';
import 'support/fake_tmdb_movie_service.dart';

late FakeTmdbMovieService service;
late FakeMovieLogBackend backend;

/// 저장된 토큰으로 세션을 복원한 상태(홈)에서 앱을 시작한다.
Future<void> pumpApp(WidgetTester tester, {String? location}) =>
    pumpMovieLogApp(tester, backend, service, location: location);

/// GridView는 화면에 보이는 카드만 만들므로 Grid에 전달된 영화 수로 확인한다.
int gridMovieCountOf(WidgetTester tester) =>
    tester.widget<MovieGrid>(find.byType(MovieGrid)).movies.length;

void main() {
  setUp(() {
    service = FakeTmdbMovieService(
      popular: [
        for (var id = 1; id <= 20; id++) fixtureMovie(id, title: '인기 영화 $id'),
      ],
    )..detailById = {680: fixtureMovie(680, title: '펄프 픽션')};
    backend = FakeMovieLogBackend();
  });

  testWidgets('세션 확인 중에는 1주차 시작 화면 레이아웃의 Splash와 인디케이터를 보여준다', (
    WidgetTester tester,
  ) async {
    backend.memberApi.gate = Completer<void>();
    await tester.pumpWidget(backend.app(service));
    await tester.pump();

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('영화의 순간을\n기록하세요'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // 1주차의 시작하기 버튼 자리를 상태 표시로 바꿨다.
    expect(find.widgetWithText(ElevatedButton, '시작하기'), findsNothing);

    backend.memberApi.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('저장된 토큰이 GET me로 검증되면 홈으로 가고 뒤로 갈 수 없다', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    expect(routerOf(tester).state.uri.path, '/home');
    expect(find.text('오늘은 어떤\n영화를 볼까요?'), findsOneWidget);
    // Popular 응답 중 앞 5개만 가로 목록에 표시된다.
    expect(find.byType(MovieCard), findsNWidgets(5));
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('토큰이 없으면 로그인 화면이 열리고 보호 화면 URL도 로그인으로 막힌다', (
    WidgetTester tester,
  ) async {
    backend = FakeMovieLogBackend(initialToken: null);
    await pumpApp(tester);
    expect(find.byType(LoginScreen), findsOneWidget);

    routerOf(tester).go('/my');
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(routerOf(tester).state.uri.path, '/login');
  });

  testWidgets('NavigationBar로 영화 목록과 마이페이지를 전환한다', (WidgetTester tester) async {
    await pumpApp(tester);

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
    await pumpApp(tester);

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
    await pumpApp(tester, location: '/movies');
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
    await pumpApp(tester, location: '/movies');

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
    await pumpApp(tester, location: '/movies');
    expect(find.byType(MovieListError), findsOneWidget);

    service.failDiscover = false;
    await tester.tap(find.widgetWithText(FilledButton, '다시 시도'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieGrid), findsOneWidget);
  });

  testWidgets('영화 카드를 누르면 TMDB id로 상세에 가고 평점 Dialog가 열린다', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, location: '/movies');

    // 테스트 화면(800x600)에서는 카드 제목이 아래로 벗어나므로 카드 자체를 누른다.
    await tester.tap(find.byType(MovieCard).first);
    await tester.pumpAndSettle();
    expect(routerOf(tester).state.uri.path, '/movies/1');
    expect(find.text('Cinema Archive'), findsOneWidget);
    // 상세 이미지 아래 줄거리는 스크롤 전이라 화면 밖에 있다.
    expect(find.text('줄거리 1', skipOffstage: false), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, '평점 남기기'));
    await tester.pumpAndSettle();

    expect(find.text('영화는 어떠셨나요?'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '확인'), findsOneWidget);
  });

  testWidgets('URL로 직접 들어오면 TMDB로 다시 조회하고, 없는 영화는 찾을 수 없다고 안내한다', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, location: '/movies/680');
    expect(service.detailCalls, contains(680));
    // 상세 이미지 아래 제목은 테스트 화면(800x600)에서 화면 밖에 있다.
    expect(find.text('펄프 픽션', skipOffstage: false), findsOneWidget);

    routerOf(tester).go('/movies/1');
    await tester.pumpAndSettle();
    expect(find.text('찾을 수 없는 영화예요'), findsOneWidget);

    routerOf(tester).go('/movies/abc');
    await tester.pumpAndSettle();
    expect(find.text('영화 ID가 올바르지 않습니다.'), findsOneWidget);
  });

  testWidgets('즐겨찾기를 누르면 Snackbar로 결과를 안내한다', (WidgetTester tester) async {
    await pumpApp(tester, location: '/movies');
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
    await pumpApp(tester, location: '/my');

    expect(find.byType(CommonAppBar), findsOneWidget);
    expect(find.text('내 프로필'), findsOneWidget);
    // GET me의 닉네임·이메일·가입일을 보여준다.
    expect(find.text('영화광'), findsOneWidget);
    expect(find.text('movie@umc.com'), findsOneWidget);
    expect(find.text('2026.10.10 가입'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '로그아웃'), findsOneWidget);
    expect(find.byType(StatItem), findsNWidgets(3));
    expect(find.text('342'), findsOneWidget);
    expect(find.byType(Chip), findsNWidgets(3));
    expect(find.widgetWithText(TextButton, '프로필 수정'), findsOneWidget);
    expect(find.byType(MyRatingsEntry), findsOneWidget);
  });

  testWidgets('마이페이지에서 내가 등록한 평점으로 들어가면 하단 탭이 없고, 뒤로가면 돌아온다', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, location: '/my');

    await tester.ensureVisible(find.text('내가 등록한 평점'));
    await tester.tap(find.text('내가 등록한 평점'));
    await tester.pumpAndSettle();

    expect(routerOf(tester).state.uri.path, '/my/ratings');
    expect(find.byType(MyRatingsScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    // v7에는 토큰 기반 내 평점 목록 GET이 없으므로 서버 목록을 조회하지 않는다.
    expect(backend.ratingService.publicFetchCalls, isEmpty);
    expect(find.text('이번 세션에 등록한 평점이 없어요'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('내 프로필'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('로그아웃하면 /login으로 가고 만료 Snackbar는 띄우지 않으며 보호 화면이 막힌다', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, location: '/my');

    await tester.tap(find.widgetWithText(TextButton, '로그아웃'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(backend.tokenStorage.token, isNull);

    routerOf(tester).go('/my/ratings');
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MovieLogButton), findsOneWidget);
  });
}
