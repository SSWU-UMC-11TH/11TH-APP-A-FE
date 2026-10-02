import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/main.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/sign_up_screen.dart';
import 'package:movielog/widgets/terms_checkbox.dart';

/// 앱을 띄우고 회원가입 화면으로 이동한다.
Future<void> pumpSignUp(WidgetTester tester) async {
  await tester.pumpWidget(const MovieLogApp());
  AppRouter.router.go('/register');
  await tester.pumpAndSettle();
}

final Finder nicknameField = find.byType(TextFormField).at(0);
final Finder emailField = find.byType(TextFormField).at(1);
final Finder passwordField = find.byType(TextFormField).at(2);
final Finder submitButton = find.widgetWithText(ElevatedButton, '가입하기');

bool isSubmitEnabled(WidgetTester tester) =>
    tester.widget<ElevatedButton>(submitButton).enabled;

/// 테스트 화면(800x600)에서는 버튼이 아래로 벗어나므로 스크롤한 뒤 누른다.
Future<void> tapSubmit(WidgetTester tester) async {
  await tester.ensureVisible(submitButton);
  await tester.pumpAndSettle();
  await tester.tap(submitButton);
  await tester.pumpAndSettle();
}

/// 유효한 값 세 개를 모두 입력한다. 약관은 따로 체크한다.
Future<void> enterValidInputs(WidgetTester tester) async {
  await tester.enterText(nicknameField, '무비러버');
  await tester.enterText(emailField, 'movie@example.com');
  await tester.enterText(passwordField, 'password123');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('입력 전에는 오류 메시지가 없고 가입 버튼이 비활성화된다', (
    WidgetTester tester,
  ) async {
    await pumpSignUp(tester);

    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.byType(TermsCheckbox), findsOneWidget);
    expect(find.textContaining('입력해주세요.'), findsNothing);
    expect(isSubmitEnabled(tester), isFalse);
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
  });

  testWidgets('입력값을 지우면 빈 값 오류 메시지가 표시된다', (WidgetTester tester) async {
    await pumpSignUp(tester);

    await tester.enterText(nicknameField, 'a');
    await tester.enterText(nicknameField, '');
    await tester.pumpAndSettle();

    expect(find.text('닉네임을 입력해주세요.'), findsOneWidget);
  });

  testWidgets('모든 입력이 유효하고 약관에 동의해야 가입 버튼이 활성화된다', (
    WidgetTester tester,
  ) async {
    await pumpSignUp(tester);

    await enterValidInputs(tester);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
    expect(find.byIcon(Icons.error_outline), findsNothing);
    // 약관 동의 전에는 입력이 모두 유효해도 비활성 상태를 유지한다.
    expect(isSubmitEnabled(tester), isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(isSubmitEnabled(tester), isTrue);

    // 약관을 다시 해제하면 버튼도 다시 비활성화된다.
    await tester.tap(find.text('필수 약관에 동의합니다'));
    await tester.pumpAndSettle();
    expect(isSubmitEnabled(tester), isFalse);
  });

  testWidgets('가입하기를 누르면 완료 Snackbar와 함께 홈으로 이동한다', (
    WidgetTester tester,
  ) async {
    await pumpSignUp(tester);
    await enterValidInputs(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tapSubmit(tester);

    expect(find.text('무비러버님, 가입이 완료되었습니다.'), findsOneWidget);
    expect(find.text('오늘은 어떤\n영화를 볼까요?'), findsOneWidget);
    expect(find.byType(SignUpScreen), findsNothing);

    // Snackbar 닫힘 Timer가 테스트 종료 후 남지 않도록 시간을 흘려 닫는다.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('뒤로가기를 누르면 시작 화면으로 돌아간다', (WidgetTester tester) async {
    await pumpSignUp(tester);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, '시작하기'), findsOneWidget);
  });
}
