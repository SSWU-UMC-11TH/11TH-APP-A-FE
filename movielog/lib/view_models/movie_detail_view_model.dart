import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'submit_status.dart';

export 'submit_status.dart';

/// 영화 상세 화면의 상태. 이 화면은 평점 "등록"만 한다.
///
/// 조회·수정·삭제는 마이페이지의 내가 등록한 평점 화면([MyRatingsViewModel])이 맡는다.
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._ratingService, this.memberId, this.movie);

  final RatingApiService _ratingService;

  /// 학습용 현재 회원(LearningMemberSession). 로그인 인증은 아니다.
  /// null이면 회원가입 전이므로 평점 등록 버튼을 잠근다.
  final int? memberId;

  /// 제목·포스터는 TMDB DTO를 쓰고, 평점 요청의 movieId는 이 DTO의 id다.
  final TmdbMovieDto movie;

  SubmitStatus submitStatus = SubmitStatus.idle;

  /// 실패하면 서버 message(400/404/409를 구분한 문장)를 그대로 담는다.
  String? submitMessage;

  /// 실패한 요청의 서버 code. 화면 문구가 아니라 다음 행동을 정할 때 쓴다.
  String? submitCode;

  /// 이 화면에서 등록에 성공한 점수. 상세 요약에 "내 평점"으로 보여준다.
  int? myScore;

  bool _disposed = false;

  bool get canRate => memberId != null;

  Future<void> createRating({required int score, String? comment}) async {
    final id = memberId;
    if (id == null) {
      submitStatus = SubmitStatus.error;
      submitMessage = '먼저 회원가입을 완료해 주세요.';
      submitCode = null;
      notifyListeners();
      return;
    }
    if (submitStatus == SubmitStatus.submitting) return;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    submitCode = null;
    notifyListeners();

    try {
      await _ratingService.createRating(
        memberId: id,
        request: CreateRatingRequest(
          movieId: movie.id,
          score: score,
          comment: comment,
        ),
      );
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
      myScore = score;
    } on DioException catch (error) {
      if (_disposed) return;
      final failure = RatingWriteException.fromDio(error);
      submitStatus = SubmitStatus.error;
      submitMessage = failure.message;
      submitCode = failure.code;
    } on StateError {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      submitMessage = '등록 결과를 확인하지 못했습니다. 마이페이지에서 목록을 확인해 주세요.';
      submitCode = null;
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
