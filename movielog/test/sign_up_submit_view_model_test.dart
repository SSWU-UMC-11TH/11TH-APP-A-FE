import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

import 'support/fake_movie_log_services.dart';

void main() {
  late FakeSignUpService service;
  late SignUpViewModel viewModel;

  const request = CreateMemberRequest(
    email: 'movie@example.com',
    password: 'Password123!',
    nickname: '무비러버',
  );

  /// 화면처럼 두 값을 입력하고 중복 확인을 모두 통과시킨다.
  Future<void> passChecks() async {
    viewModel.onNicknameChanged(request.nickname);
    viewModel.onEmailChanged(request.email);
    await viewModel.checkNickname(request.nickname);
    await viewModel.checkEmail(request.email);
  }

  setUp(() async {
    service = FakeSignUpService();
    viewModel = SignUpViewModel(service);
    await passChecks();
  });

  test('가입 성공 시 result.memberId를 createdMemberId로 보관한다', () async {
    final pending = viewModel.submit(request);
    expect(viewModel.submitStatus, SubmitStatus.submitting);
    expect(viewModel.isSubmitting, isTrue);
    await pending;

    expect(viewModel.submitStatus, SubmitStatus.success);
    expect(viewModel.createdMemberId, 101);
    expect(viewModel.snackbarMessage, isNull);
  });

  test('제출 중 다시 눌러도 요청은 한 번만 간다', () async {
    service.signUpGate = Completer<void>();
    final first = viewModel.submit(request);
    await viewModel.submit(request);
    service.signUpGate!.complete();
    await first;

    expect(service.signUpCalls, hasLength(1));
  });

  test('비밀번호 형식 400은 passwordErrorText로, 비밀번호를 고치면 지운다', () async {
    service.signUpFailure = (
      status: 400,
      code: 'COMMON400',
      message: '비밀번호는 대문자/소문자/숫자/특수문자를 포함한 8자 이상이어야 합니다.',
    );
    await viewModel.submit(request);

    expect(viewModel.submitStatus, SubmitStatus.error);
    expect(
      viewModel.passwordErrorText,
      '비밀번호는 대문자/소문자/숫자/특수문자를 포함한 8자 이상이어야 합니다.',
    );
    expect(viewModel.snackbarMessage, isNull);
    expect(viewModel.createdMemberId, isNull);

    viewModel.onPasswordChanged();
    expect(viewModel.passwordErrorText, isNull);
    expect(viewModel.submitStatus, SubmitStatus.idle);
  });

  test('비밀번호가 아닌 400은 Snackbar 문구로 보낸다', () async {
    service.signUpFailure = (
      status: 400,
      code: 'COMMON400',
      message: '닉네임은 12자 이하여야 합니다.',
    );
    await viewModel.submit(request);

    expect(viewModel.passwordErrorText, isNull);
    expect(viewModel.snackbarMessage, '닉네임은 12자 이하여야 합니다.');
  });

  test('최종 409는 Snackbar로 알리고 중복된 칸을 다시 잠가 가입 버튼을 끈다', () async {
    expect(viewModel.isAllChecked, isTrue);
    service.signUpFailure = (
      status: 409,
      code: 'COMMON409',
      message: '이미 사용 중인 이메일입니다.',
    );
    await viewModel.submit(request);

    expect(viewModel.snackbarMessage, '이미 사용 중인 이메일입니다.');
    expect(viewModel.emailCheckStatus, CheckStatus.duplicated);
    expect(viewModel.emailErrorText, '이미 사용 중인 이메일입니다.');
    // 이메일을 먼저 검사하므로 닉네임 결과는 그대로다.
    expect(viewModel.nicknameCheckStatus, CheckStatus.available);
    expect(viewModel.isAllChecked, isFalse);

    // 값을 바꾸면 중복 확인 결과와 서버 오류를 함께 무효화한다.
    viewModel.onEmailChanged('other@example.com');
    expect(viewModel.emailCheckStatus, CheckStatus.idle);
    expect(viewModel.snackbarMessage, isNull);
    expect(viewModel.submitStatus, SubmitStatus.idle);
  });

  test('201인데 memberId가 없으면 가입 완료로 표시하지 않는다', () async {
    service.nextMemberId = null;
    await viewModel.submit(request);

    expect(viewModel.submitStatus, SubmitStatus.error);
    expect(viewModel.createdMemberId, isNull);
    expect(viewModel.snackbarMessage, SignUpViewModel.contractErrorText);
  });

  test('통신 실패는 기본 안내 문구로 보낸다', () async {
    service.signUpFailure = null;
    final failing = _NetworkFailingSignUpService();
    final vm = SignUpViewModel(failing);
    await vm.submit(request);

    expect(vm.submitStatus, SubmitStatus.error);
    expect(vm.snackbarMessage, '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.');
  });
}

class _NetworkFailingSignUpService extends FakeSignUpService {
  @override
  Future<Never> signUp(CreateMemberRequest request) async {
    throw fakeDioError('/v6/members');
  }
}
