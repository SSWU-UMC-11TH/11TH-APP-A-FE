import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

import 'support/fake_movie_log_services.dart';

void main() {
  late FakeMemberCheckService service;
  late SignUpViewModel viewModel;

  setUp(() {
    service = FakeMemberCheckService();
    viewModel = SignUpViewModel(service);
  });

  /// 화면처럼 입력 변경을 먼저 알린 뒤 중복 확인을 요청한다.
  Future<void> typeAndCheckNickname(String value) {
    viewModel.onNicknameChanged(value);
    return viewModel.checkNickname(value);
  }

  test('확인 전에는 idle이고 버튼을 누를 수 있다', () {
    expect(viewModel.nicknameCheckStatus, CheckStatus.idle);
    expect(viewModel.nicknameErrorText, isNull);
    expect(viewModel.canCheckNickname, isTrue);
  });

  test('요청 중에는 checking이고 다시 누를 수 없다', () async {
    service.gate = Completer<void>();
    viewModel.onNicknameChanged('영화광');
    final pending = viewModel.checkNickname('영화광');

    expect(viewModel.nicknameCheckStatus, CheckStatus.checking);
    expect(viewModel.canCheckNickname, isFalse);
    // 통신 중 다시 눌러도 요청이 늘지 않는다.
    await viewModel.checkNickname('영화광');
    expect(service.nicknameCalls, ['영화광']);

    service.gate!.complete();
    await pending;
    expect(viewModel.nicknameCheckStatus, CheckStatus.available);
  });

  test('사용 가능하면 available, 중복이면 duplicated와 에러 문구', () async {
    await typeAndCheckNickname('영화광');
    expect(viewModel.nicknameCheckStatus, CheckStatus.available);
    expect(viewModel.nicknameErrorText, isNull);

    await typeAndCheckNickname('중복닉네임');
    expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);
    expect(viewModel.nicknameErrorText, '이미 사용 중인 닉네임입니다.');
    // 중복으로 확인된 값은 바꾸기 전까지 다시 확인할 수 없다.
    expect(viewModel.canCheckNickname, isFalse);
  });

  test('통신 실패는 중복과 다른 error 상태와 문구가 된다', () async {
    service.failing = {'영화광'};
    await typeAndCheckNickname('영화광');

    expect(viewModel.nicknameCheckStatus, CheckStatus.error);
    expect(viewModel.nicknameErrorText, SignUpViewModel.networkErrorText);
    expect(viewModel.nicknameErrorText, isNot('이미 사용 중인 닉네임입니다.'));
    // 통신 실패는 같은 값으로 다시 시도할 수 있다.
    expect(viewModel.canCheckNickname, isTrue);
  });

  test('입력을 바꾸면 이전 결과가 idle로 무효화된다', () async {
    await typeAndCheckNickname('영화광');
    viewModel.onNicknameChanged('영화광2');

    expect(viewModel.nicknameCheckStatus, CheckStatus.idle);
    expect(viewModel.nicknameErrorText, isNull);
  });

  test('중복이었던 값을 다시 입력하면 재요청 없이 즉시 duplicated가 된다', () async {
    await typeAndCheckNickname('중복닉네임');
    viewModel.onNicknameChanged('중복닉네임1');
    expect(viewModel.nicknameCheckStatus, CheckStatus.idle);
    expect(viewModel.canCheckNickname, isTrue);

    // 앞뒤 공백은 trim 후 비교한다.
    viewModel.onNicknameChanged(' 중복닉네임 ');
    expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);
    expect(viewModel.nicknameErrorText, '이미 사용 중인 닉네임입니다.');
    expect(viewModel.canCheckNickname, isFalse);
    expect(service.nicknameCalls, ['중복닉네임']);
  });

  test('응답 전에 입력이 바뀌면 늦게 온 응답을 무시한다', () async {
    service.gate = Completer<void>();
    viewModel.onNicknameChanged('중복닉네임');
    final pending = viewModel.checkNickname('중복닉네임');
    viewModel.onNicknameChanged('다른닉네임');

    service.gate!.complete();
    await pending;
    expect(viewModel.nicknameCheckStatus, CheckStatus.idle);
    expect(viewModel.nicknameErrorText, isNull);
  });

  test('닉네임과 이메일 결과는 서로 영향을 주지 않는다', () async {
    await typeAndCheckNickname('중복닉네임');
    viewModel.onEmailChanged('movie@example.com');
    await viewModel.checkEmail('movie@example.com');

    expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);
    expect(viewModel.emailCheckStatus, CheckStatus.available);
    expect(viewModel.isAllChecked, isFalse);

    viewModel.onEmailChanged('taken@example.com');
    await viewModel.checkEmail('taken@example.com');
    expect(viewModel.emailErrorText, '이미 사용 중인 이메일입니다.');
    expect(viewModel.nicknameErrorText, '이미 사용 중인 닉네임입니다.');
  });

  test('두 값이 모두 사용 가능으로 확인되어야 isAllChecked가 true다', () async {
    await typeAndCheckNickname('영화광');
    viewModel.onEmailChanged('movie@example.com');
    await viewModel.checkEmail('movie@example.com');

    expect(viewModel.isAllChecked, isTrue);
  });

  test('dispose 후 도착한 응답은 반영하지 않는다', () async {
    service.gate = Completer<void>();
    viewModel.onNicknameChanged('영화광');
    final pending = viewModel.checkNickname('영화광');
    viewModel.dispose();

    service.gate!.complete();
    await pending;
    expect(viewModel.nicknameCheckStatus, CheckStatus.checking);
  });
}
