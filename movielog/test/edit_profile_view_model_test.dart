import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';

import 'support/fake_movie_log_services.dart';

void main() {
  late MemoryTokenStorage storage;
  late FakeMemberApiService memberApi;
  late AuthViewModel auth;
  late EditProfileViewModel viewModel;

  setUp(() async {
    storage = MemoryTokenStorage('token-movie@umc.com');
    memberApi = FakeMemberApiService(storage);
    auth = AuthViewModel(FakeAuthApiService(), memberApi, storage);
    await auth.restoreSession();
    viewModel = EditProfileViewModel(memberApi, auth);
  });

  test('2~12자 규칙을 요청 전에 검사한다', () async {
    expect(await viewModel.save('a'), isFalse);
    expect(viewModel.nicknameError, '닉네임은 2~12자로 입력해 주세요.');
    expect(await viewModel.save('열세글자닉네임열세글자닉네'), isFalse);
    expect(memberApi.updateCalls, isEmpty);
  });

  test('현재 닉네임과 같으면 요청 없이 완료한다', () async {
    expect(await viewModel.save(' 영화광 '), isTrue);
    expect(memberApi.updateCalls, isEmpty);
  });

  test('성공하면 GET me 없이 응답으로 AuthViewModel.member를 교체한다', () async {
    final fetchesBefore = memberApi.fetchCalls.length;
    expect(await viewModel.save('새닉네임'), isTrue);
    expect(auth.member?.nickname, '새닉네임');
    expect(memberApi.fetchCalls.length, fetchesBefore);
  });

  test('MEMBER409_1은 필드 오류로 보여주고 로그인 상태를 유지한다', () async {
    expect(await viewModel.save('중복닉네임'), isFalse);
    expect(viewModel.nicknameError, '이미 사용 중인 닉네임이에요.');
    expect(viewModel.message, isNull);
    expect(auth.status, AuthStatus.signedIn);

    viewModel.onNicknameChanged();
    expect(viewModel.nicknameError, isNull);
  });

  test('COMMON400은 서버 message를 필드 아래에 그대로 보여준다', () async {
    memberApi.updateFailure = (
      status: 400,
      code: 'COMMON400',
      message: '닉네임은 2자 이상 12자 이하여야 합니다.',
    );
    await viewModel.save('새닉네임');
    expect(viewModel.nicknameError, '닉네임은 2자 이상 12자 이하여야 합니다.');
  });

  test('네트워크 실패는 Snackbar 문구로 보내고 로그아웃하지 않는다', () async {
    memberApi.failNetwork = true;
    expect(await viewModel.save('새닉네임'), isFalse);
    expect(viewModel.message, '네트워크 상태를 확인하고 다시 시도해 주세요.');
    expect(auth.status, AuthStatus.signedIn);
    expect(storage.token, isNotNull);
  });

  test('401이면 세션을 정리하고 false를 돌려준다', () async {
    memberApi.expired = true;
    expect(await viewModel.save('새닉네임'), isFalse);
    expect(auth.status, AuthStatus.signedOut);
    expect(auth.sessionExpired, isTrue);
  });

  test('저장 중 다시 눌러도 요청은 한 번만 간다', () async {
    memberApi.gate = Completer<void>();
    final first = viewModel.save('새닉네임');
    expect(viewModel.isSaving, isTrue);
    expect(await viewModel.save('새닉네임'), isFalse);
    memberApi.gate!.complete();
    await first;
    expect(memberApi.updateCalls, hasLength(1));
  });

  test('응답 전에 로그아웃하면 늦은 성공을 반영하지 않는다', () async {
    memberApi.gate = Completer<void>();
    final pending = viewModel.save('새닉네임');
    await auth.logout();
    memberApi.gate!.complete();
    expect(await pending, isFalse);
    expect(auth.member, isNull);
  });
}
