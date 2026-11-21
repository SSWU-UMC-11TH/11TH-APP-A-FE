import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
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

  test('v6 평점 응답의 updatedAt을 읽는다', () {
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

  group('오류 응답 처리', () {
    const path = '/v6/members/1/ratings/3';

    test('서버 message를 그대로 쓰고, body가 없으면 기본 문구를 쓴다', () {
      expect(
        writeErrorMessage(
          fakeDioError(
            path,
            statusCode: 404,
            code: 'COMMON404',
            message: '존재하지 않는 평점입니다.',
          ),
        ),
        '존재하지 않는 평점입니다.',
      );
      expect(
        writeErrorMessage(fakeDioError(path)),
        '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.',
      );
      expect(
        writeSignUpErrorMessage(fakeDioError('/v6/members')),
        '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.',
      );
    });

    test('403·404만 목록을 다시 조회하고, 400·409·통신 실패는 다시 조회하지 않는다', () {
      bool refresh(int? status, String? code) => shouldRefreshAfterRatingError(
        fakeDioError(path, statusCode: status, code: code),
      );

      expect(refresh(403, 'COMMON403'), isTrue);
      expect(refresh(404, 'COMMON404'), isTrue);
      expect(refresh(400, 'COMMON400'), isFalse);
      expect(refresh(409, 'COMMON409'), isFalse);
      expect(refresh(null, null), isFalse);
    });

    test('RatingWriteException은 서버 message와 code를 함께 담는다', () {
      final failure = RatingWriteException.fromDio(
        fakeDioError(
          path,
          statusCode: 403,
          code: 'COMMON403',
          message: '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
        ),
      );
      expect(failure.code, 'COMMON403');
      expect(failure.message, '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.');
    });
  });
}
