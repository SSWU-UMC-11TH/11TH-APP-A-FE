import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';

import 'support/fake_movie_log_services.dart';

void main() {
  group('CommonResponse', () {
    test('회원가입 성공 응답은 result를 SignUpResult로 한 번만 파싱한다', () {
      final response = CommonResponse<SignUpResult>.fromJson({
        'isSuccess': true,
        'code': 'COMMON201',
        'message': '회원가입에 성공했습니다.',
        'result': {'memberId': 7, 'email': 'movie@umc.com', 'nickname': '영화광'},
      }, (value) => SignUpResult.fromJson(value as Map<String, dynamic>));

      expect(response.isSuccess, isTrue);
      expect(response.code, 'COMMON201');
      expect(response.result?.memberId, 7);
      expect(response.result?.nickname, '영화광');
    });

    test('result가 null이면 parseResult를 부르지 않고 null로 둔다', () {
      var called = false;
      final response = CommonResponse<int>.fromJson(
        {
          'isSuccess': true,
          'code': 'COMMON200',
          'message': '평점 수정에 성공했습니다.',
          'result': null,
        },
        (value) {
          called = true;
          return value as int;
        },
      );

      expect(response.result, isNull);
      expect(called, isFalse);
    });

    test('오류 body가 공통 형식이 아니면 tryParseError는 null이다', () {
      expect(CommonResponse.tryParseError(null), isNull);
      expect(CommonResponse.tryParseError('<html>'), isNull);
      expect(CommonResponse.tryParseError({'message': 1}), isNull);
    });
  });

  group('요청 Model', () {
    test('회원가입 요청은 이메일·닉네임만 trim하고 비밀번호는 그대로 보낸다', () {
      const request = CreateMemberRequest(
        email: ' movie@umc.com ',
        password: ' Umc1234! ',
        nickname: ' 영화광 ',
      );

      expect(request.toJson(), {
        'email': 'movie@umc.com',
        'password': ' Umc1234! ',
        'nickname': '영화광',
      });
      expect(request.toString(), isNot(contains('Umc1234!')));
    });

    test('등록 요청은 빈 comment를 생략하고, 값이 있으면 trim해 보낸다', () {
      expect(
        const CreateRatingRequest(
          movieId: 550,
          score: 5,
          comment: '  ',
        ).toJson(),
        {'movieId': 550, 'score': 5},
      );
      expect(
        const CreateRatingRequest(
          movieId: 550,
          score: 5,
          comment: ' 최고! ',
        ).toJson(),
        {'movieId': 550, 'score': 5, 'comment': '최고!'},
      );
    });

    test('수정 요청은 comment 키를 항상 포함해 유지/삭제 의도를 드러낸다', () {
      expect(
        const UpdateRatingRequest(score: 4, comment: '다시 봐도 좋다').toJson(),
        {'score': 4, 'comment': '다시 봐도 좋다'},
      );
      final cleared = const UpdateRatingRequest(score: 4, comment: '').toJson();
      expect(cleared.containsKey('comment'), isTrue);
      expect(cleared['comment'], isNull);
    });

    test('서버 평점은 1~5 정수만 허용한다', () {
      expect(validateServerScore(1), 1);
      expect(validateServerScore(5.0), 5);
      expect(() => validateServerScore(0), throwsArgumentError);
      expect(() => validateServerScore(3.5), throwsArgumentError);
      expect(() => validateServerScore(6), throwsArgumentError);
    });
  });

  test('평점 응답의 updatedAt을 읽는다', () {
    final rating = RatingDto.fromJson({
      'ratingId': 12,
      'movieId': 550,
      'score': 5,
      'comment': null,
      'createdAt': '2026-09-06T12:14:03.000Z',
      'updatedAt': '2026-09-07T08:00:00.000Z',
    });
    expect(rating.updatedAt, DateTime.utc(2026, 9, 7, 8));
  });

  group('v7 로그인·내 정보·평점 result', () {
    test('LoginResult는 nickname·accessToken만 읽고 toString에 토큰을 남기지 않는다', () {
      final result = LoginResult.fromJson({
        'nickname': '영화광',
        'accessToken': 'eyJhbGciOiJIUzI1NiJ9.secret',
      });
      expect(result.nickname, '영화광');
      expect(result.accessToken, 'eyJhbGciOiJIUzI1NiJ9.secret');
      expect(result.toString(), isNot(contains('eyJ')));
    });

    test('로그인 요청은 이메일만 trim하고 비밀번호는 그대로 보낸다', () {
      const request = LoginRequest(
        email: ' movie@umc.com ',
        password: ' Umc1234! ',
      );
      expect(request.toJson(), {
        'email': 'movie@umc.com',
        'password': ' Umc1234! ',
      });
    });

    test('GET me result를 MemberInfo로 파싱하고 가입일을 "yyyy.MM.dd 가입"으로 표시한다', () {
      final member = parseMemberInfo({
        'isSuccess': true,
        'code': 'COMMON200',
        'message': '회원 정보를 조회했습니다.',
        'result': {
          'email': 'movie@umc.com',
          'nickname': '영화광',
          'createdAt': '2026-10-10T03:00:00.000Z',
        },
      });
      expect(member.email, 'movie@umc.com');
      expect(member.joinedLabel, '2026.10.10 가입');
      expect(
        () => parseMemberInfo({
          'isSuccess': true,
          'code': 'COMMON200',
          'message': '',
          'result': null,
        }),
        throwsStateError,
      );
    });

    test('등록·수정 result는 Rating 객체, 공개 조회는 직접 배열이다', () {
      final rating = parseRatingResult({
        'isSuccess': true,
        'code': 'COMMON201',
        'message': '평점을 등록했습니다.',
        'result': {
          'ratingId': 12,
          'movieId': 550,
          'score': 5,
          'comment': null,
          'createdAt': '2026-09-06T12:14:03.000Z',
          'updatedAt': '2026-09-06T12:14:03.000Z',
        },
      });
      expect(rating.ratingId, 12);
      expect(rating.comment, isNull);

      expect(parseRatingList(<Object?>[]), isEmpty);
      expect(() => parseRatingList({'result': []}), throwsStateError);
      expect(() => parseRatingResult('not json'), throwsStateError);
    });
  });

  group('오류 응답 처리', () {
    const path = '/v7/ratings/3';

    test('401·403·404는 다음 행동에 맞는 문구, 나머지는 서버 message를 쓴다', () {
      String message(int? status, String? code, [String? serverMessage]) =>
          writeErrorMessage(
            fakeDioError(
              path,
              statusCode: status,
              code: code,
              message: serverMessage,
            ),
          );

      expect(message(401, 'AUTH401_4'), '로그인이 만료됐어요. 다시 로그인해 주세요.');
      expect(message(403, 'RATING403_1'), '본인이 작성한 평점만 수정하거나 삭제할 수 있어요.');
      expect(message(404, 'RATING404_1'), '이미 삭제된 평점이에요. 목록을 새로고침했어요.');
      expect(
        message(409, 'RATING409_1', '이미 이 영화에 평점을 남기셨습니다.'),
        '이미 이 영화에 평점을 남기셨습니다.',
      );
      expect(message(null, null), '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.');
      expect(
        writeSignUpErrorMessage(fakeDioError('/v7/members')),
        '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.',
      );
    });

    test('세션 만료 후보는 AUTH401_2/3/4뿐이고 로그인 실패 AUTH401_1은 아니다', () {
      expect(isSessionExpiredCode('AUTH401_2'), isTrue);
      expect(isSessionExpiredCode('AUTH401_3'), isTrue);
      expect(isSessionExpiredCode('AUTH401_4'), isTrue);
      expect(isSessionExpiredCode('AUTH401_1'), isFalse);
      expect(isSessionExpiredCode('RATING403_1'), isFalse);
      expect(isSessionExpiredCode(null), isFalse);
    });

    test('RatingWriteException은 화면 문구와 code를 함께 담는다', () {
      final failure = RatingWriteException.fromDio(
        fakeDioError(path, statusCode: 403, code: 'RATING403_1'),
      );
      expect(failure.code, 'RATING403_1');
      expect(failure.message, '본인이 작성한 평점만 수정하거나 삭제할 수 있어요.');
    });
  });
}
