import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/screens/sign_up_screen.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/widgets/terms_checkbox.dart';

import 'support/fake_movie_log_services.dart';
import 'support/fake_tmdb_movie_service.dart';

late FakeSignUpService checkService;

/// 로그아웃 상태로 앱을 띄우고 회원가입 화면(공개 Route)으로 이동한다.
Future<void> pumpSignUp(WidgetTester tester) async {
  await pumpMovieLogApp(
    tester,
    FakeMovieLogBackend(initialToken: null, signUpService: checkService),
    FakeTmdbMovieService(),
    location: '/register',
  );
}

final Finder nicknameField = find.byType(TextFormField).at(0);
final Finder emailField = find.byType(TextFormField).at(1);
final Finder passwordField = find.byType(TextFormField).at(2);
final Finder nicknameCheckButton = find.byType(MovieLogButton).at(0);
final Finder emailCheckButton = find.byType(MovieLogButton).at(1);
final Finder submitButton = find.widgetWithText(ElevatedButton, '가입하기');

bool isSubmitEnabled(WidgetTester tester) =>
    tester.widget<ElevatedButton>(submitButton).enabled;

MovieLogButton buttonOf(WidgetTester tester, Finder finder) =>
    tester.widget<MovieLogButton>(finder);

/// 입력창의 errorText(서버 중복·통신 실패 문구)를 읽는다.
String? errorTextOf(WidgetTester tester, Finder field) => tester
    .widget<TextField>(
      find.descendant(of: field, matching: find.byType(TextField)),
    )
    .decoration
    ?.errorText;

/// 테스트 화면(800x600)에서는 버튼이 아래로 벗어나므로 스크롤한 뒤 누른다.
Future<void> tapSubmit(WidgetTester tester) async {
  await tester.ensureVisible(submitButton);
  await tester.pumpAndSettle();
  await tester.tap(submitButton);
  await tester.pumpAndSettle();
}

/// 유효한 값 세 개를 입력하고 닉네임·이메일 중복 확인까지 마친다. 약관은 따로 체크한다.
Future<void> enterValidInputs(WidgetTester tester) async {
  await tester.enterText(nicknameField, '무비러버');
  await tester.enterText(emailField, 'movie@example.com');
  await tester.enterText(passwordField, 'Password123!');
  await tester.pumpAndSettle();
  await tester.tap(nicknameCheckButton);
  await tester.tap(emailCheckButton);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    checkService = FakeSignUpService();
  });

  testWidgets('입력 전에는 오류 메시지가 없고 가입 버튼이 비활성화된다', (WidgetTester tester) async {
    await pumpSignUp(tester);

    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.byType(TermsCheckbox), findsOneWidget);
    expect(find.textContaining('입력해주세요.'), findsNothing);
    expect(isSubmitEnabled(tester), isFalse);
    // 형식이 맞지 않는(빈) 값은 중복 확인을 누를 수 없다.
    expect(buttonOf(tester, nicknameCheckButton).onPressed, isNull);
    expect(buttonOf(tester, emailCheckButton).onPressed, isNull);
  });

  testWidgets('조건에 맞지 않는 입력에는 한국어 오류 메시지와 오류 아이콘이 표시된다', (
    WidgetTester tester,
  ) async {
    await pumpSignUp(tester);

    await tester.enterText(nicknameField, 'a');
    await tester.enterText(emailField, 'test@');
    await tester.enterText(passwordField, '123');
    await tester.pumpAndSettle();

    expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
    expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
    expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNWidgets(3));
    expect(isSubmitEnabled(tester), isFalse);
    expect(buttonOf(tester, nicknameCheckButton).onPressed, isNull);
  });

  testWidgets('입력값을 지우면 빈 값 오류 메시지가 표시된다', (WidgetTester tester) async {
    await pumpSignUp(tester);

    await tester.enterText(nicknameField, 'a');
    await tester.enterText(nicknameField, '');
    await tester.pumpAndSettle();

    expect(find.text('닉네임을 입력해주세요.'), findsOneWidget);
  });

  testWidgets('중복 확인 중에는 회색 인디케이터와 확인 중 안내, 끝나면 사용 가능 안내가 보인다', (
    WidgetTester tester,
  ) async {
    await pumpSignUp(tester);
    await tester.enterText(nicknameField, '영화광');
    await tester.pumpAndSettle();

    checkService.gate = Completer<void>();
    await tester.tap(nicknameCheckButton);
    await tester.pump();

    expect(buttonOf(tester, nicknameCheckButton).isLoading, isTrue);
    expect(
      find.descendant(
        of: nicknameCheckButton,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(find.text('닉네임 사용 가능 여부를 확인 중입니다.'), findsOneWidget);

    checkService.gate!.complete();
    await tester.pumpAndSettle();

    expect(find.text('사용 가능한 닉네임입니다.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(errorTextOf(tester, nicknameField), isNull);
  });

  testWidgets('서버가 중복이라고 하면 입력창이 에러 상태가 되고 버튼이 잠긴다', (
    WidgetTester tester,
  ) async {
    await pumpSignUp(tester);
    await tester.enterText(nicknameField, '중복닉네임');
    await tester.pumpAndSettle();
    await tester.tap(nicknameCheckButton);
    await tester.pumpAndSettle();

    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    expect(errorTextOf(tester, nicknameField), '이미 사용 중인 닉네임입니다.');
    expect(buttonOf(tester, nicknameCheckButton).onPressed, isNull);
  });

  testWidgets('입력을 바꾸면 결과가 사라지고, 중복이던 값을 다시 입력하면 재요청 없이 에러가 된다', (
    WidgetTester tester,
  ) async {
    await pumpSignUp(tester);
    await tester.enterText(nicknameField, '중복닉네임');
    await tester.pumpAndSettle();
    await tester.tap(nicknameCheckButton);
    await tester.pumpAndSettle();

    await tester.enterText(nicknameField, '중복닉네');
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsNothing);
    expect(errorTextOf(tester, nicknameField), isNull);
    expect(buttonOf(tester, nicknameCheckButton).onPressed, isNotNull);

    await tester.enterText(nicknameField, '중복닉네임');
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    expect(buttonOf(tester, nicknameCheckButton).onPressed, isNull);
    expect(checkService.nicknameCalls, ['중복닉네임']);
  });

  testWidgets('통신 실패는 중복과 다른 문구로 보여주고 다시 시도할 수 있다', (
    WidgetTester tester,
  ) async {
    checkService.failing = {'movie@example.com'};
    await pumpSignUp(tester);
    await tester.enterText(emailField, 'movie@example.com');
    await tester.pumpAndSettle();
    await tester.tap(emailCheckButton);
    await tester.pumpAndSettle();

    expect(find.text(SignUpViewModel.networkErrorText), findsOneWidget);
    expect(find.text('이미 사용 중인 이메일입니다.'), findsNothing);
    expect(buttonOf(tester, emailCheckButton).onPressed, isNotNull);
  });

  testWidgets('중복 확인 버튼은 내용 크기, 가입하기는 전체 너비를 쓴다', (WidgetTester tester) async {
    await pumpSignUp(tester);

    expect(buttonOf(tester, nicknameCheckButton).width, isNull);
    final double checkWidth = tester.getSize(nicknameCheckButton).width;
    final double fieldWidth = tester.getSize(nicknameField).width;
    expect(checkWidth, lessThan(fieldWidth));

    final Finder submit = find.widgetWithText(MovieLogButton, '가입하기');
    expect(tester.widget<MovieLogButton>(submit).width, double.infinity);
    // 좌우 padding 24를 뺀 Form 전체 너비(800 - 48)를 채운다.
    expect(tester.getSize(submit).width, 752);
  });

  testWidgets('중복 확인을 마치고 약관에 동의해야 가입 버튼이 활성화된다', (WidgetTester tester) async {
    await pumpSignUp(tester);
    await tester.enterText(nicknameField, '무비러버');
    await tester.enterText(emailField, 'movie@example.com');
    await tester.enterText(passwordField, 'Password123!');
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    // 형식이 모두 맞고 약관에 동의해도 중복 확인 전에는 비활성이다.
    expect(isSubmitEnabled(tester), isFalse);

    await tester.tap(nicknameCheckButton);
    await tester.tap(emailCheckButton);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
    expect(isSubmitEnabled(tester), isTrue);

    // 약관을 다시 해제하면 버튼도 다시 비활성화된다.
    await tester.tap(find.text('필수 약관에 동의합니다'));
    await tester.pumpAndSettle();
    expect(isSubmitEnabled(tester), isFalse);
  });

  testWidgets('가입하기를 누르면 v7 POST 후 완료 Snackbar와 함께 로그인 화면으로 이동한다', (
    WidgetTester tester,
  ) async {
    await pumpSignUp(tester);
    await enterValidInputs(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tapSubmit(tester);

    expect(checkService.signUpCalls, hasLength(1));
    expect(checkService.signUpCalls.single.toJson(), {
      'email': 'movie@example.com',
      'password': 'Password123!',
      'nickname': '무비러버',
    });
    // 가입은 로그인이 아니므로 토큰 없이 로그인 화면으로 간다.
    expect(find.text('무비러버님, 가입이 완료되었습니다. 로그인해 주세요.'), findsOneWidget);
    expect(routerOf(tester).state.uri.path, '/login');
    expect(find.byType(SignUpScreen), findsNothing);

    // Snackbar 닫힘 Timer가 테스트 종료 후 남지 않도록 시간을 흘려 닫는다.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('비밀번호는 대·소문자·숫자·특수문자를 모두 포함해야 한다', (WidgetTester tester) async {
    await pumpSignUp(tester);
    await tester.enterText(passwordField, 'password123');
    await tester.pumpAndSettle();

    expect(
      find.text('소문자·대문자·숫자·특수문자(!@#\$%^&*)를 모두 포함해야 합니다.'),
      findsOneWidget,
    );
  });

  testWidgets('제출 중에는 가입하기가 로딩으로 바뀌고, 서버 비밀번호 400은 비밀번호 칸 errorText가 된다', (
    WidgetTester tester,
  ) async {
    checkService.signUpGate = Completer<void>();
    checkService.signUpFailure = (
      status: 400,
      code: 'COMMON400',
      message: '비밀번호는 대문자/소문자/숫자/특수문자를 포함한 8자 이상이어야 합니다.',
    );
    await pumpSignUp(tester);
    await enterValidInputs(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    // 로딩 중에는 label 대신 인디케이터만 그리므로 순서로 찾는다.
    final Finder submit = find.byType(MovieLogButton).at(2);
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pump();

    expect(tester.widget<MovieLogButton>(submit).isLoading, isTrue);
    // 제출 중에는 로그인 화면으로 돌아가지 않는다.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    expect(find.byType(SignUpScreen), findsOneWidget);

    checkService.signUpGate!.complete();
    await tester.pumpAndSettle();

    expect(
      errorTextOf(tester, passwordField),
      '비밀번호는 대문자/소문자/숫자/특수문자를 포함한 8자 이상이어야 합니다.',
    );
    expect(find.byType(SnackBar), findsNothing);

    // 비밀번호를 고치면 서버 오류가 사라진다.
    await tester.enterText(passwordField, 'Password123!!');
    await tester.pumpAndSettle();
    expect(errorTextOf(tester, passwordField), isNull);
  });

  testWidgets('최종 가입 409는 Snackbar로 알리고 가입 버튼을 다시 잠근다', (
    WidgetTester tester,
  ) async {
    checkService.signUpFailure = (
      status: 409,
      code: 'COMMON409',
      message: '이미 사용 중인 닉네임입니다.',
    );
    await pumpSignUp(tester);
    await enterValidInputs(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tapSubmit(tester);

    expect(find.widgetWithText(SnackBar, '이미 사용 중인 닉네임입니다.'), findsOneWidget);
    expect(errorTextOf(tester, nicknameField), '이미 사용 중인 닉네임입니다.');
    expect(isSubmitEnabled(tester), isFalse);
    expect(find.byType(SignUpScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('뒤로가기를 누르면 로그인 화면으로 돌아간다', (WidgetTester tester) async {
    await pumpSignUp(tester);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
