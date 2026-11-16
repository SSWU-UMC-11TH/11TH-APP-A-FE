import 'dart:async';

import 'package:dio/dio.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';

DioException fakeDioError(String path, {int? statusCode}) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    response: statusCode == null
        ? null
        : Response(requestOptions: options, statusCode: statusCode),
    type: statusCode == null
        ? DioExceptionType.connectionError
        : DioExceptionType.badResponse,
  );
}

/// 워크북 서버 대신 정해 둔 값으로 중복 여부를 답하는 Service.
///
/// [taken]에 든 값은 중복(`available: false`), [failing]에 든 값은 통신 실패다.
/// [gate]를 설정하면 그 Completer가 끝날 때까지 응답을 미룬다.
class FakeMemberCheckService implements MemberCheckService {
  FakeMemberCheckService({Set<String>? taken, Set<String>? failing})
    : taken = taken ?? {'중복닉네임', 'taken@example.com'},
      failing = failing ?? {};

  Set<String> taken;
  Set<String> failing;
  Completer<void>? gate;

  final List<String> nicknameCalls = [];
  final List<String> emailCalls = [];

  Future<bool> _answer(String value, String path) async {
    final pending = gate;
    if (pending != null) await pending.future;
    if (failing.contains(value)) throw fakeDioError(path);
    return !taken.contains(value);
  }

  @override
  Future<bool> checkNickname(String nickname) {
    nicknameCalls.add(nickname);
    return _answer(nickname.trim(), '/v5/members/nickname');
  }

  @override
  Future<bool> checkEmail(String email) {
    emailCalls.add(email);
    return _answer(email.trim(), '/v5/members/email');
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

/// 워크북 서버 대신 fixture 평점을 돌려주는 Service.
///
/// [failStatus]를 정하면 그 HTTP 상태로, [failNetwork]면 응답 없이 실패한다.
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

  final List<int> calls = [];

  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    calls.add(memberId);
    final pending = gate;
    if (pending != null) await pending.future;
    final path = '/v5/members/$memberId/ratings';
    if (failNetwork) throw fakeDioError(path);
    final status = failStatus;
    if (status != null) throw fakeDioError(path, statusCode: status);
    return ratings;
  }
}
