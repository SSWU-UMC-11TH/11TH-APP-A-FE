import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/main.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/widgets/common_app_bar.dart';
import 'package:movielog/widgets/stat_item.dart';

/// GoRouter는 앱 전체에서 하나만 사용하므로 테스트마다 시작 위치로 되돌린다.
Future<void> pumpAppAtStart(WidgetTester tester) async {
  await tester.pumpWidget(const MovieLogApp());
  AppRouter.router.go('/start');
  await tester.pumpAndSettle();
}

/// 시작 화면에서 회원가입을 거쳐 홈까지 이동한다.
Future<void> goToHome(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ElevatedButton, '시작하기'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ElevatedButton, '회원가입'));
  await tester.pumpAndSettle();
}

void main() {
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
    // go로 이동했으므로 홈에서는 돌아갈 화면이 없다.
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('NavigationBar로 영화 목록과 마이페이지를 전환한다', (WidgetTester tester) async {
    await pumpAppAtStart(tester);
    await goToHome(tester);

    await tester.tap(find.byIcon(Icons.movie_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('전체'), findsOneWidget);

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

  testWidgets('장르 Chip을 누르면 해당 장르의 영화만 보여준다', (WidgetTester tester) async {
    await pumpAppAtStart(tester);
    await goToHome(tester);

    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();
    expect(find.text('별빛 아래 우리'), findsOneWidget);

    await tester.tap(find.text('SF'));
    await tester.pumpAndSettle();
    expect(find.text('우주의 끝에서'), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsNothing);
  });

  testWidgets('평점 남기기 버튼을 누르면 별점 Dialog가 열린다', (WidgetTester tester) async {
    await pumpAppAtStart(tester);
    AppRouter.router.go('/movies/1');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, '평점 남기기'));
    await tester.pumpAndSettle();

    expect(find.text('영화는 어떠셨나요?'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '확인'), findsOneWidget);
  });

  testWidgets('즐겨찾기를 누르면 Snackbar로 결과를 안내한다', (WidgetTester tester) async {
    await pumpAppAtStart(tester);
    AppRouter.router.go('/movies/1');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, '즐겨찾기'));
    await tester.pump();
    expect(find.text('별빛 아래 우리을(를) 즐겨찾기에 추가했어요.'), findsOneWidget);

    // Snackbar 표시 애니메이션이 끝나야 닫힘 Timer가 시작되므로
    // 먼저 settle한 뒤 시간을 흘려 앞선 Snackbar를 닫는다.
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '즐겨찾기 완료'));
    await tester.pump();
    expect(find.text('별빛 아래 우리을(를) 즐겨찾기에서 삭제했어요.'), findsOneWidget);
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
