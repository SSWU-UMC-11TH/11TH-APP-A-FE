import 'dart:async';

import 'package:dio/dio.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';

/// 응답이 없으면 통신 실패, [statusCode]가 있으면 서버 오류 응답이다.
/// [code]·[message]를 주면 v6 공통 오류 응답 body를 함께 담는다.
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
    return _answer(nickname.trim(), '/v6/members/nickname');
  }

  @override
  Future<bool> checkEmail(String email) {
    emailCalls.add(email);
    return _answer(email.trim(), '/v6/members/email');
  }

  @override
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    signUpCalls.add(request);
    final pending = signUpGate;
    if (pending != null) await pending.future;
    final failure = signUpFailure;
    if (failure != null) {
      throw fakeDioError(
        '/v6/members',
        statusCode: failure.status,
        code: failure.code,
        message: failure.message,
      );
    }
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
  );
}

/// 워크북 서버 대신 메모리의 평점 목록으로 조회·등록·수정·삭제를 처리하는 Service.
///
/// 조회: [failStatus]면 그 HTTP 상태로, [failNetwork]면 응답 없이 실패한다.
/// 쓰기: [createFailure]·[updateFailure]·[deleteFailure]로 서버 오류를 정하고,
/// [deleteFailIds]에 든 ratingId만 삭제에 실패하게 할 수 있다.
/// [failFetchAfterWrite]면 쓰기는 성공하지만 그 직후 GET만 실패한다.
class FakeRatingApiService implements RatingApiService {
  FakeRatingApiService({List<RatingDto>? ratings})
    : ratings =
          ratings ??
          [
            fixtureRating(2, movieId: 680, score: 4, comment: '다시 봐도 좋다'),
            fixtureRating(3, movieId: 13, score: 3, comment: null),
          ];

  List<RatingDto> ratings;
  int? failStatus;
  bool failNetwork = false;
  Completer<void>? gate;

  FakeFailure? createFailure;
  FakeFailure? updateFailure;
  FakeFailure? deleteFailure;
  Set<int> deleteFailIds = {};
  bool failFetchAfterWrite = false;

  /// 설정하면 쓰기 요청이 이 Completer가 끝날 때까지 기다린다.
  Completer<void>? writeGate;

  final List<int> calls = [];
  final List<({int memberId, Map<String, dynamic> body})> createCalls = [];
  final List<({int memberId, int ratingId, Map<String, dynamic> body})>
  updateCalls = [];
  final List<({int memberId, int ratingId})> deleteCalls = [];

  int _nextRatingId = 100;

  DioException _failure(String path, FakeFailure failure) => fakeDioError(
    path,
    statusCode: failure.status,
    code: failure.code,
    message: failure.message,
  );

  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    calls.add(memberId);
    final pending = gate;
    if (pending != null) await pending.future;
    final path = '/v6/members/$memberId/ratings';
    if (failNetwork) throw fakeDioError(path);
    final status = failStatus;
    if (status != null) throw fakeDioError(path, statusCode: status);
    return List<RatingDto>.of(ratings);
  }

  Future<void> _afterWrite() async {
    final pending = writeGate;
    if (pending != null) await pending.future;
  }

  void _maybeBreakNextFetch() {
    if (failFetchAfterWrite) failNetwork = true;
  }

  @override
  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final body = request.toJson();
    createCalls.add((memberId: memberId, body: body));
    await _afterWrite();
    final path = '/v6/members/$memberId/ratings';
    final failure = createFailure;
    if (failure != null) throw _failure(path, failure);
    ratings = [
      ...ratings,
      RatingDto(
        ratingId: _nextRatingId++,
        movieId: body['movieId'] as int,
        score: body['score'] as int,
        comment: body['comment'] as String?,
        createdAt: DateTime.utc(2026, 11, 17, 12),
      ),
    ];
    _maybeBreakNextFetch();
  }

  @override
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final body = UpdateRatingRequest(score: score, comment: comment).toJson();
    updateCalls.add((memberId: memberId, ratingId: ratingId, body: body));
    await _afterWrite();
    final path = '/v6/members/$memberId/ratings/$ratingId';
    final failure = updateFailure;
    if (failure != null) throw _failure(path, failure);
    ratings = [
      for (final rating in ratings)
        if (rating.ratingId == ratingId)
          RatingDto(
            ratingId: rating.ratingId,
            movieId: rating.movieId,
            score: body['score'] as int,
            // PATCH는 전체 교체라 comment가 없으면 null로 덮인다.
            comment: body['comment'] as String?,
            createdAt: rating.createdAt,
          )
        else
          rating,
    ];
    _maybeBreakNextFetch();
  }

  @override
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    deleteCalls.add((memberId: memberId, ratingId: ratingId));
    await _afterWrite();
    final path = '/v6/members/$memberId/ratings/$ratingId';
    final failure = deleteFailure;
    if (failure != null) throw _failure(path, failure);
    if (deleteFailIds.contains(ratingId)) throw fakeDioError(path);
    ratings = ratings.where((rating) => rating.ratingId != ratingId).toList();
    _maybeBreakNextFetch();
  }
}
