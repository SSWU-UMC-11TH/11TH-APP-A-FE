import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/screens/edit_profile_screen.dart';
import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/screens/profile_screen.dart';
import 'package:movielog/screens/splash_screen.dart';
import 'package:movielog/widgets/movielog_button.dart';

import 'support/fake_movie_log_services.dart';
import 'support/fake_tmdb_movie_service.dart';

late FakeMovieLogBackend backend;

Future<void> pumpApp(WidgetTester tester, {String? location}) =>
    pumpMovieLogApp(
      tester,
      backend,
      FakeTmdbMovieService(),
      location: location,
    );

final Finder emailField = find.byType(TextFormField).at(0);
final Finder passwordField = find.byType(TextFormField).at(1);
final Finder loginButton = find.widgetWithText(MovieLogButton, '로그인');

Future<void> login(WidgetTester tester, String email, String password) async {
  await tester.enterText(emailField, email);
  await tester.enterText(passwordField, password);
  await tester.ensureVisible(loginButton);
  await tester.tap(loginButton);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    backend = FakeMovieLogBackend(initialToken: null);
  });

  group('로그인', () {
    testWidgets('AUTH401_1은 Form 아래 문구로 보여주고 만료 Snackbar는 띄우지 않는다', (
      tester,
    ) async {
      await pumpApp(tester);
      await login(tester, 'movie@umc.com', 'wrong');

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('이메일 또는 비밀번호를 확인해 주세요.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('성공하면 토큰을 저장하고 홈으로 가며, MainScreen이 GET me를 한 번 부른다', (
      tester,
    ) async {
      await pumpApp(tester);
      await login(tester, 'movie@umc.com', 'Umc1234!');

      expect(routerOf(tester).state.uri.path, '/home');
      expect(backend.tokenStorage.token, 'token-movie@umc.com');
      expect(backend.memberApi.fetchCalls, hasLength(1));

      // 홈을 거쳐 마이로 가도 다시 부르지 않고 같은 member를 쓴다.
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.text('영화광'), findsOneWidget);
      expect(backend.memberApi.fetchCalls, hasLength(1));
    });

    testWidgets('이메일 저장을 켜면 이메일만 저장하고 다음에 채워 준다', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('이메일 저장'));
      await tester.pumpAndSettle();
      await login(tester, 'movie@umc.com', 'Umc1234!');

      expect(backend.emailStore.email, 'movie@umc.com');

      routerOf(tester).go('/my');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '로그아웃'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'movie@umc.com'),
        findsOneWidget,
      );
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });
  });

  group('앱 재시작 세션 복원', () {
    testWidgets('만료된 토큰이면 로그인 화면으로 가고 만료 Snackbar를 한 번 보여준다', (tester) async {
      backend = FakeMovieLogBackend();
      backend.memberApi.expired = true;
      await pumpApp(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsOneWidget);
      expect(backend.tokenStorage.token, isNull);
      await flushSnackBar(tester);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('네트워크 실패면 토큰을 지우지 않고 Splash 재시도 버튼을 보여준다', (tester) async {
      backend = FakeMovieLogBackend();
      backend.memberApi.failNetwork = true;
      await pumpApp(tester);

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      expect(backend.tokenStorage.token, isNotNull);

      backend.memberApi.failNetwork = false;
      await tester.tap(find.widgetWithText(MovieLogButton, '다시 시도'));
      await tester.pumpAndSettle();
      expect(routerOf(tester).state.uri.path, '/home');
    });
  });

  group('마이페이지 · 프로필 수정', () {
    setUp(() {
      backend = FakeMovieLogBackend();
    });

    testWidgets('내 정보 GET이 실패하면 다시 시도 버튼을 보여주고, 성공하면 프로필을 그린다', (tester) async {
      // 신규 로그인처럼 member 없이 시작하도록 로그아웃 상태에서 로그인한다.
      backend = FakeMovieLogBackend(initialToken: null);
      await pumpApp(tester);
      backend.memberApi.failNetwork = true;
      await login(tester, 'movie@umc.com', 'Umc1234!');
      routerOf(tester).go('/my');
      await tester.pumpAndSettle();

      expect(find.text('내 정보를 불러오지 못했어요.'), findsOneWidget);
      // 네트워크 실패로는 로그아웃하지 않는다.
      expect(find.byType(LoginScreen), findsNothing);

      backend.memberApi.failNetwork = false;
      await tester.tap(find.widgetWithText(MovieLogButton, '다시 시도'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileBody), findsOneWidget);
      expect(find.text('2026.10.10 가입'), findsOneWidget);
    });

    testWidgets('닉네임을 바꿔 저장하면 Snackbar와 함께 마이페이지에 바로 반영된다', (tester) async {
      await pumpApp(tester, location: '/my');
      await tester.tap(find.widgetWithText(TextButton, '프로필 수정'));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(
        find.widgetWithText(TextFormField, 'movie@umc.com'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField).last, '새닉네임');
      await tester.tap(find.widgetWithText(MovieLogButton, '저장'));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileScreen), findsNothing);
      expect(find.text('프로필을 수정했어요.'), findsOneWidget);
      expect(find.text('새닉네임'), findsOneWidget);
      await flushSnackBar(tester);
    });

    testWidgets('409면 화면에 남아 입력값을 유지하고 필드 아래 오류를 보여준다', (tester) async {
      await pumpApp(tester, location: '/my/profile/edit');
      await tester.enterText(find.byType(TextField).last, '중복닉네임');
      await tester.tap(find.widgetWithText(MovieLogButton, '저장'));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.text('이미 사용 중인 닉네임이에요.'), findsOneWidget);
      expect(find.widgetWithText(TextField, '중복닉네임'), findsOneWidget);
    });

    testWidgets('변경 내용이 있으면 뒤로가기 확인 Dialog를 띄우고, 계속 수정하면 머문다', (tester) async {
      await pumpApp(tester, location: '/my');
      await tester.tap(find.widgetWithText(TextButton, '프로필 수정'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '바뀐닉네임');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('수정을 그만둘까요?'), findsOneWidget);

      await tester.tap(find.text('계속 수정'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('나가기'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsNothing);
      expect(find.text('영화광'), findsOneWidget);
    });

    testWidgets('저장 중 토큰이 만료되면 로그인 화면으로 이동해 만료를 안내한다', (tester) async {
      await pumpApp(tester, location: '/my/profile/edit');
      backend.memberApi.expired = true;
      await tester.enterText(find.byType(TextField).last, '새닉네임');
      await tester.tap(find.widgetWithText(MovieLogButton, '저장'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsOneWidget);
      await flushSnackBar(tester);
    });
  });
}
