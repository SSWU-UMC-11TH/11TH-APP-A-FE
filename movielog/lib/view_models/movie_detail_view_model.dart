import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'session_ratings_store.dart';
import 'submit_status.dart';

export 'submit_status.dart';

/// 영화 상세 화면의 상태. 이 화면은 평점 "등록"만 한다.
///
/// v7 등록은 `POST /v7/ratings`에 토큰만으로 보내고, path·body에 memberId가 없다.
/// 등록 response의 Rating 객체를 [SessionRatingsStore]에 넣어
/// 마이페이지의 "이번 세션에 등록한 평점"에서 바로 수정·삭제할 수 있게 한다.
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._ratingService,
    this._store,
    this._auth,
    this.movie,
  );

  final RatingApiService _ratingService;
  final SessionRatingsStore _store;
  final AuthViewModel _auth;

  /// 제목·포스터는 TMDB DTO를 쓰고, 평점 요청의 movieId는 이 DTO의 id다.
  final TmdbMovieDto movie;

  SubmitStatus submitStatus = SubmitStatus.idle;

  /// 실패 안내. 400·404·409는 서버 message를 그대로 담는다.
  String? submitMessage;

  /// 실패한 요청의 서버 code. 화면 문구가 아니라 다음 행동을 정할 때 쓴다.
  String? submitCode;

  /// 이 화면에서 등록에 성공한 점수. 상세 요약에 "내 평점"으로 보여준다.
  int? myScore;

  bool _disposed = false;

  Future<void> createRating({required int score, String? comment}) async {
    if (submitStatus == SubmitStatus.submitting) return;
    final sessionVersion = _auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    submitCode = null;
    notifyListeners();

    bool isStale() => _disposed || sessionVersion != _auth.sessionVersion;

    try {
      final created = await _ratingService.createRating(
        CreateRatingRequest(movieId: movie.id, score: score, comment: comment),
      );
      if (isStale()) return;
      _store.upsert(sessionVersion, created);
      submitStatus = SubmitStatus.success;
      myScore = created.score;
    } on DioException catch (error) {
      if (isStale()) return;
      final failure = RatingWriteException.fromDio(error);
      submitStatus = SubmitStatus.error;
      submitMessage = failure.code == 'RATING409_1'
          ? '${failure.message} 마이페이지에서 기존 기록을 확인해 주세요.'
          : failure.message;
      submitCode = failure.code;
      if (isSessionExpiredCode(failure.code)) {
        await _auth.expireSession(version: sessionVersion);
        if (_disposed) return;
      }
    } on StateError {
      if (isStale()) return;
      submitStatus = SubmitStatus.error;
      submitMessage = '등록 결과를 확인하지 못했습니다. 잠시 후 다시 확인해 주세요.';
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
