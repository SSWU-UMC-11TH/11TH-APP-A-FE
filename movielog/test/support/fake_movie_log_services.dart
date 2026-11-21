import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/core/storage/saved_email_store.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

/// 응답이 없으면 통신 실패, [statusCode]가 있으면 서버 오류 응답이다.
/// [code]·[message]를 주면 공통 오류 응답 body를 함께 담는다.
DioException fakeDioError(
  String path, {
  int? statusCode,
  String? code,
  String? message,
}) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    response: statusCode == null
        ? null
        : Response(
            requestOptions: options,
            statusCode: statusCode,
            data: code == null
                ? null
                : <String, dynamic>{
                    'isSuccess': false,
                    'code': code,
                    'message': message ?? '',
                    'result': null,
                  },
          ),
    type: statusCode == null
        ? DioExceptionType.connectionError
        : DioExceptionType.badResponse,
  );
}

/// 서버 오류 응답 한 건을 미리 정해 둔다.
typedef FakeFailure = ({int status, String code, String message});

DioException _failureError(String path, FakeFailure failure) => fakeDioError(
  path,
  statusCode: failure.status,
  code: failure.code,
  message: failure.message,
);

const FakeFailure expiredToken = (
  status: 401,
  code: 'AUTH401_4',
  message: '토큰이 만료되었습니다. 다시 로그인해주세요.',
);

// ---------------------------------------------------------------------------
// 인증
// ---------------------------------------------------------------------------

/// 기기 보안 저장소 대신 메모리에 토큰을 보관한다.
class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage([this.token]);

  String? token;
  bool failRead = false;
  bool failDelete = false;
  int deleteCount = 0;

  @override
  Future<void> saveAccessToken(String value) async => token = value;

  @override
  Future<String?> readAccessToken() async {
    if (failRead) throw StateError('저장소 읽기 실패');
    return token;
  }

  @override
  Future<void> deleteAccessToken() async {
    deleteCount++;
    if (failDelete) throw StateError('저장소 삭제 실패');
    token = null;
  }
}

class MemorySavedEmailStore implements SavedEmailStore {
  String? email;

  @override
  Future<String?> readEmail() async => email;

  @override
  Future<void> saveEmail(String value) async => email = value.trim();

  @override
  Future<void> clearEmail() async => email = null;
}

/// 계정 표: 이메일 → (비밀번호, 닉네임). 로그인하면 `token-{이메일}`을 돌려준다.
class FakeAuthApiService implements AuthApiService {
  FakeAuthApiService({
    Map<String, ({String password, String nickname})>? accounts,
  }) : accounts =
           accounts ??
           {'movie@umc.com': (password: 'Umc1234!', nickname: '영화광')};

  final Map<String, ({String password, String nickname})> accounts;
  final List<LoginRequest> calls = [];
  bool failNetwork = false;
  Completer<void>? gate;

  @override
  Future<LoginResult> login(LoginRequest request) async {
    calls.add(request);
    final pending = gate;
    if (pending != null) await pending.future;
    if (failNetwork) throw fakeDioError('/v7/auth/login');
    final email = request.email.trim();
    final account = accounts[email];
    if (account == null || account.password != request.password) {
      throw fakeDioError(
        '/v7/auth/login',
        statusCode: 401,
        code: 'AUTH401_1',
        message: '이메일 또는 비밀번호가 올바르지 않습니다.',
      );
    }
    return LoginResult(nickname: account.nickname, accessToken: 'token-$email');
  }
}

MemberInfo fixtureMember({
  String nickname = '영화광',
  String email = 'movie@umc.com',
}) {
  return MemberInfo(
    email: email,
    nickname: nickname,
    createdAt: DateTime(2026, 10, 10, 12),
  );
}

/// 토큰을 [tokenStorage]에서 직접 읽어 서버처럼 검증한다.
///
/// 토큰이 없으면 AUTH401_2, [validTokens]에 없으면 AUTH401_3,
/// [expired]면 AUTH401_4로 실패한다.
class FakeMemberApiService implements MemberApiService {
  FakeMemberApiService(this.tokenStorage, {Map<String, MemberInfo>? members})
    : members = members ?? {'token-movie@umc.com': fixtureMember()};

  final MemoryTokenStorage tokenStorage;

  /// 토큰 → 회원 정보.
  final Map<String, MemberInfo> members;
  bool expired = false;
  bool failNetwork = false;
  FakeFailure? updateFailure;
  Set<String> takenNicknames = {'중복닉네임'};
  Completer<void>? gate;
  final List<String> fetchCalls = [];
  final List<String> updateCalls = [];

  Future<String> _authorize(String path) async {
    final pending = gate;
    if (pending != null) await pending.future;
    if (failNetwork) throw fakeDioError(path);
    final token = tokenStorage.token;
    if (token == null) {
      throw fakeDioError(path, statusCode: 401, code: 'AUTH401_2');
    }
    if (expired) throw _failureError(path, expiredToken);
    if (!members.containsKey(token)) {
      throw fakeDioError(path, statusCode: 401, code: 'AUTH401_3');
    }
    return token;
  }

  @override
  Future<MemberInfo> fetchMe() async {
    fetchCalls.add(tokenStorage.token ?? '');
    final token = await _authorize('/v7/members/me');
    return members[token]!;
  }

  @override
  Future<MemberInfo> updateNickname(String nickname) async {
    updateCalls.add(nickname);
    final token = await _authorize('/v7/members/me');
    final failure = updateFailure;
    if (failure != null) throw _failureError('/v7/members/me', failure);
    if (takenNicknames.contains(nickname)) {
      throw fakeDioError(
        '/v7/members/me',
        statusCode: 409,
        code: 'MEMBER409_1',
        message: '이미 사용 중인 닉네임입니다.',
      );
    }
    final current = members[token]!;
    final updated = MemberInfo(
      email: current.email,
      nickname: nickname,
      createdAt: current.createdAt,
    );
    members[token] = updated;
    return updated;
  }
}

// ---------------------------------------------------------------------------
// 회원가입
// ---------------------------------------------------------------------------

/// 워크북 서버 대신 정해 둔 값으로 중복 여부·가입 결과를 답하는 Service.
///
/// [taken]에 든 값은 중복(`available: false`), [failing]에 든 값은 통신 실패다.
/// [gate]를 설정하면 그 Completer가 끝날 때까지 중복 확인 응답을 미룬다.
class FakeSignUpService implements SignUpService {
  FakeSignUpService({Set<String>? taken, Set<String>? failing})
    : taken = taken ?? {'중복닉네임', 'taken@example.com'},
      failing = failing ?? {};

  Set<String> taken;
  Set<String> failing;
  Completer<void>? gate;

  final List<String> nicknameCalls = [];
  final List<String> emailCalls = [];

  /// 가입 성공 시 돌려줄 memberId. null이면 result가 null인 계약 오류 응답이다.
  int? nextMemberId = 101;

  /// 설정하면 가입 요청이 이 서버 오류로 끝난다.
  FakeFailure? signUpFailure;

  /// 설정하면 가입 응답이 이 Completer가 끝날 때까지 기다린다.
  Completer<void>? signUpGate;

  final List<CreateMemberRequest> signUpCalls = [];

  Future<bool> _answer(String value, String path) async {
    final pending = gate;
    if (pending != null) await pending.future;
    if (failing.contains(value)) throw fakeDioError(path);
    return !taken.contains(value);
  }

  @override
  Future<bool> checkNickname(String nickname) {
    nicknameCalls.add(nickname);
    return _answer(nickname.trim(), '/v7/members/nickname');
  }

  @override
  Future<bool> checkEmail(String email) {
    emailCalls.add(email);
    return _answer(email.trim(), '/v7/members/email');
  }

  @override
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    signUpCalls.add(request);
    final pending = signUpGate;
    if (pending != null) await pending.future;
    final failure = signUpFailure;
    if (failure != null) throw _failureError('/v7/members', failure);
    final id = nextMemberId;
    final body = request.toJson();
    return CommonResponse<SignUpResult>(
      isSuccess: true,
      code: 'COMMON201',
      message: '회원가입에 성공했습니다.',
      result: id == null
          ? null
          : SignUpResult(
              memberId: id,
              email: body['email'] as String,
              nickname: body['nickname'] as String,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// 평점
// ---------------------------------------------------------------------------

RatingDto fixtureRating(
  int ratingId, {
  required int movieId,
  int score = 4,
  String? comment = '좋았어요',
}) {
  return RatingDto(
    ratingId: ratingId,
    movieId: movieId,
    score: score,
    comment: comment,
    createdAt: DateTime.utc(2026, 9, 6, 12),
    updatedAt: DateTime.utc(2026, 9, 6, 12),
  );
}

/// 워크북 서버 대신 메모리로 v7 평점 등록·수정·삭제를 처리하는 Service.
///
/// 보호 요청은 memberId 없이 호출되며, 결과로 Rating 객체를 돌려준다.
/// [createFailure]·[updateFailure]·[deleteFailure]로 서버 오류를 정하고,
/// [deleteFailIds]에 든 ratingId만 삭제(통신 실패)에 실패하게 할 수 있다.
class FakeRatingApiService implements RatingApiService {
  FakeRatingApiService();

  /// 서버에 저장된 평점(ratingId → Rating).
  final Map<int, RatingDto> server = {};

  FakeFailure? createFailure;
  FakeFailure? updateFailure;
  FakeFailure? deleteFailure;
  Set<int> deleteFailIds = {};

  /// 설정하면 쓰기 요청이 이 Completer가 끝날 때까지 기다린다.
  Completer<void>? writeGate;

  final List<Map<String, dynamic>> createCalls = [];
  final List<({int ratingId, Map<String, dynamic> body})> updateCalls = [];
  final List<int> deleteCalls = [];
  final List<int> publicFetchCalls = [];

  int _nextRatingId = 100;

  Future<void> _afterWrite() async {
    final pending = writeGate;
    if (pending != null) await pending.future;
  }

  @override
  Future<List<RatingDto>> fetchMemberRatings(int memberId) async {
    publicFetchCalls.add(memberId);
    return server.values.toList();
  }

  @override
  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final body = request.toJson();
    createCalls.add(body);
    await _afterWrite();
    final failure = createFailure;
    if (failure != null) throw _failureError('/v7/ratings', failure);
    final created = RatingDto(
      ratingId: _nextRatingId++,
      movieId: body['movieId'] as int,
      score: body['score'] as int,
      comment: body['comment'] as String?,
      createdAt: DateTime.utc(2026, 11, 21, 12),
      updatedAt: DateTime.utc(2026, 11, 21, 12),
    );
    server[created.ratingId] = created;
    return created;
  }

  @override
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final body = UpdateRatingRequest(score: score, comment: comment).toJson();
    updateCalls.add((ratingId: ratingId, body: body));
    await _afterWrite();
    final path = '/v7/ratings/$ratingId';
    final failure = updateFailure;
    if (failure != null) throw _failureError(path, failure);
    final current = server[ratingId];
    if (current == null) {
      throw fakeDioError(path, statusCode: 404, code: 'RATING404_1');
    }
    final updated = RatingDto(
      ratingId: ratingId,
      movieId: current.movieId,
      score: body['score'] as int,
      // PATCH는 전체 교체라 comment가 없으면 null로 덮인다.
      comment: body['comment'] as String?,
      createdAt: current.createdAt,
      updatedAt: DateTime.utc(2026, 11, 21, 13),
    );
    server[ratingId] = updated;
    return updated;
  }

  @override
  Future<void> deleteRating(int ratingId) async {
    deleteCalls.add(ratingId);
    await _afterWrite();
    final path = '/v7/ratings/$ratingId';
    final failure = deleteFailure;
    if (failure != null) throw _failureError(path, failure);
    if (deleteFailIds.contains(ratingId)) throw fakeDioError(path);
    if (server.remove(ratingId) == null) {
      throw fakeDioError(path, statusCode: 404, code: 'RATING404_1');
    }
  }
}

// ---------------------------------------------------------------------------
// 앱 전체 테스트 도우미
// ---------------------------------------------------------------------------

/// 앱 위젯 테스트에서 함께 쓰는 Fake 묶음.
class FakeMovieLogBackend {
  FakeMovieLogBackend({
    String? initialToken = 'token-movie@umc.com',
    FakeSignUpService? signUpService,
  }) : tokenStorage = MemoryTokenStorage(initialToken),
       signUpService = signUpService ?? FakeSignUpService() {
    memberApi = FakeMemberApiService(tokenStorage);
  }

  final MemoryTokenStorage tokenStorage;
  late final FakeMemberApiService memberApi;
  final FakeAuthApiService authApi = FakeAuthApiService();
  final FakeSignUpService signUpService;
  final FakeRatingApiService ratingService = FakeRatingApiService();
  final MemorySavedEmailStore emailStore = MemorySavedEmailStore();

  MovieLogApp app(TmdbMovieService movieService) => MovieLogApp(
    movieService: movieService,
    signUpService: signUpService,
    ratingApiService: ratingService,
    authApiService: authApi,
    memberApiService: memberApi,
    tokenStorage: tokenStorage,
    savedEmailStore: emailStore,
  );
}

/// 앱의 GoRouter. 테스트에서 URL로 직접 이동할 때 쓴다.
GoRouter routerOf(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Navigator).last));

/// 앱을 띄우고 세션 복원(토큰 읽기 → GET me)이 끝날 때까지 기다린다.
/// [location]을 주면 복원 뒤 그 위치로 이동한다.
Future<void> pumpMovieLogApp(
  WidgetTester tester,
  FakeMovieLogBackend backend,
  TmdbMovieService movieService, {
  String? location,
}) async {
  await tester.pumpWidget(backend.app(movieService));
  await tester.pumpAndSettle();
  if (location != null) {
    routerOf(tester).go(location);
    await tester.pumpAndSettle();
  }
}

/// Snackbar 닫힘 Timer가 테스트 종료 후 남지 않도록 시간을 흘려 닫는다.
Future<void> flushSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}
