import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/auth_view_model.dart';

import 'support/fake_movie_log_services.dart';

void main() {
  late MemoryTokenStorage storage;
  late FakeMemberApiService memberApi;
  late FakeAuthApiService authApi;
  late AuthViewModel auth;

  setUp(() {
    storage = MemoryTokenStorage();
    memberApi = FakeMemberApiService(storage);
    authApi = FakeAuthApiService();
    auth = AuthViewModel(authApi, memberApi, storage);
  });

  group('restoreSession', () {
    test('토큰이 없으면 GET me 없이 signedOut', () async {
      await auth.restoreSession();
      expect(auth.status, AuthStatus.signedOut);
      expect(memberApi.fetchCalls, isEmpty);
    });

    test('토큰이 있어도 GET me 검증 뒤에만 signedIn이 되고 member를 채운다', () async {
      storage.token = 'token-movie@umc.com';
      memberApi.gate = Completer<void>();
      final pending = auth.restoreSession();
      await Future<void>.delayed(Duration.zero);
      // 토큰만 읽은 단계에서는 아직 initializing이다.
      expect(auth.status, AuthStatus.initializing);

      memberApi.gate!.complete();
      await pending;
      expect(auth.status, AuthStatus.signedIn);
      expect(auth.member?.nickname, '영화광');
      expect(auth.memberStatus, MemberLoadStatus.success);
    });

    test('만료 토큰(AUTH401_4)이면 토큰을 지우고 만료 안내 플래그를 켠다', () async {
      storage.token = 'token-movie@umc.com';
      memberApi.expired = true;
      await auth.restoreSession();

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isTrue);
      expect(storage.token, isNull);
    });

    test('무효 토큰(AUTH401_3)도 세션을 정리한다', () async {
      storage.token = 'forged-token';
      await auth.restoreSession();
      expect(auth.status, AuthStatus.signedOut);
      expect(storage.token, isNull);
    });

    test('네트워크 실패는 토큰을 지우지 않고 retryRequired로 남긴다', () async {
      storage.token = 'token-movie@umc.com';
      memberApi.failNetwork = true;
      await auth.restoreSession();

      expect(auth.status, AuthStatus.retryRequired);
      expect(auth.message, '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.');
      expect(storage.token, 'token-movie@umc.com');

      memberApi.failNetwork = false;
      await auth.restoreSession();
      expect(auth.status, AuthStatus.signedIn);
    });

    test('저장소 읽기 실패는 서버 401과 다른 문구의 retryRequired다', () async {
      storage.failRead = true;
      await auth.restoreSession();
      expect(auth.status, AuthStatus.retryRequired);
      expect(auth.message, '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.');
    });
  });

  group('login', () {
    test('성공하면 토큰을 저장하고 signedIn. GET me는 MainScreen이 부른다', () async {
      await auth.login('movie@umc.com', 'Umc1234!');

      expect(auth.status, AuthStatus.signedIn);
      expect(storage.token, 'token-movie@umc.com');
      expect(memberApi.fetchCalls, isEmpty);
      expect(auth.member, isNull);
      // 비밀번호는 요청에만 쓰이고 저장소에는 토큰만 남는다.
      expect(storage.token, isNot(contains('Umc1234!')));
    });

    test('AUTH401_1은 Form 오류 문구이고 세션 만료 안내를 켜지 않는다', () async {
      await auth.login('movie@umc.com', 'wrong');
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.message, '이메일 또는 비밀번호를 확인해 주세요.');
      expect(auth.sessionExpired, isFalse);
      expect(storage.token, isNull);
    });

    test('네트워크 실패는 다른 문구로 구분한다', () async {
      authApi.failNetwork = true;
      await auth.login('movie@umc.com', 'Umc1234!');
      expect(auth.message, '로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.');
    });

    test('로그인 요청 중 다시 눌러도 한 번만 보낸다', () async {
      authApi.gate = Completer<void>();
      final first = auth.login('movie@umc.com', 'Umc1234!');
      expect(auth.status, AuthStatus.authenticating);
      await auth.login('movie@umc.com', 'Umc1234!');
      authApi.gate!.complete();
      await first;
      expect(authApi.calls, hasLength(1));
    });
  });

  group('loadMember · 만료 · 로그아웃', () {
    setUp(() async {
      await auth.login('movie@umc.com', 'Umc1234!');
    });

    test('loadMember는 한 번만 GET me를 부르고 member를 보관한다', () async {
      await auth.loadMember();
      await auth.loadMember();
      expect(memberApi.fetchCalls, hasLength(1));
      expect(auth.member?.email, 'movie@umc.com');
    });

    test('loadMember 네트워크 실패는 로그아웃하지 않고 error로 남긴다', () async {
      memberApi.failNetwork = true;
      await auth.loadMember();
      expect(auth.status, AuthStatus.signedIn);
      expect(auth.memberStatus, MemberLoadStatus.error);
      expect(storage.token, isNotNull);
    });

    test('loadMember가 401이면 세션을 정리한다', () async {
      memberApi.expired = true;
      await auth.loadMember();
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isTrue);
      expect(storage.token, isNull);
    });

    test('직접 로그아웃은 토큰·member를 지우지만 만료 안내는 켜지 않는다', () async {
      await auth.loadMember();
      await auth.logout();
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.member, isNull);
      expect(auth.sessionExpired, isFalse);
      expect(storage.token, isNull);
    });

    test('동시에 여러 401이 와도 정리는 한 번만 한다', () async {
      final version = auth.sessionVersion;
      await Future.wait([
        auth.expireSession(version: version),
        auth.expireSession(version: version),
        auth.expireSession(version: version),
      ]);
      expect(storage.deleteCount, 1);
    });

    test('이전 세션에서 늦게 온 401은 새 로그인 세션을 지우지 않는다', () async {
      final oldVersion = auth.sessionVersion;
      await auth.logout();
      await auth.login('movie@umc.com', 'Umc1234!');

      await auth.expireSession(version: oldVersion);
      expect(auth.status, AuthStatus.signedIn);
      expect(storage.token, 'token-movie@umc.com');
    });

    test('로그아웃 뒤 늦게 도착한 GET me 응답은 반영하지 않는다', () async {
      memberApi.gate = Completer<void>();
      final pending = auth.loadMember();
      await auth.logout();
      memberApi.gate!.complete();
      await pending;
      expect(auth.member, isNull);
    });

    test('저장소 삭제에 실패하면 안내를 남긴다', () async {
      storage.failDelete = true;
      await auth.logout();
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.message, contains('저장된 인증 정보를 지우지 못했어요'));
    });
  });

  group('authRedirect', () {
    test('초기화·재시도 중에는 Splash에 머문다', () {
      expect(authRedirect(AuthStatus.initializing, '/home'), '/start');
      expect(authRedirect(AuthStatus.initializing, '/start'), isNull);
      expect(authRedirect(AuthStatus.retryRequired, '/login'), '/start');
    });

    test('로그아웃 상태에서는 공개 화면만 허용하고 보호 화면은 /login으로 보낸다', () {
      expect(authRedirect(AuthStatus.signedOut, '/login'), isNull);
      expect(authRedirect(AuthStatus.signedOut, '/register'), isNull);
      expect(authRedirect(AuthStatus.signedOut, '/my'), '/login');
      expect(authRedirect(AuthStatus.signedOut, '/movies/550'), '/login');
      expect(authRedirect(AuthStatus.authenticating, '/start'), '/login');
    });

    test('로그인 상태에서는 Splash·로그인·회원가입을 홈으로 보낸다', () {
      expect(authRedirect(AuthStatus.signedIn, '/start'), '/home');
      expect(authRedirect(AuthStatus.signedIn, '/login'), '/home');
      expect(authRedirect(AuthStatus.signedIn, '/register'), '/home');
      expect(authRedirect(AuthStatus.signedIn, '/my/profile/edit'), isNull);
    });
  });
}
