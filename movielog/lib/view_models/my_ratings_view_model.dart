import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'auth_view_model.dart';
import 'session_ratings_store.dart';

export '../data/services/rating_api_service.dart' show RatingWriteException;

enum MyRatingsLoadStatus { idle, loading, success, empty }

/// "이번 세션에 등록한 평점" 화면의 상태 (조회·수정·삭제).
///
/// v7에는 토큰 기반 내 평점 목록 GET이 없으므로 서버 목록을 조회하지 않는다.
/// 영화 상세에서 등록한 response의 Rating을 [SessionRatingsStore]에서 꺼내
/// 각 movieId로 TMDB 영화 정보를 붙인다.
///
/// 수정·삭제는 v7 보호 API로 보내고, 수정 response의 Rating으로 카드를 바로 교체한다.
/// - AUTH401_2/3/4: 세션 정리 → Router가 /login으로 이동
/// - RATING403_1: 안내만 하고 로그아웃하지 않는다
/// - RATING404_1: 이미 없는 평점이므로 목록에서 빼고 새로 그린다
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._service,
    this._movieService,
    this._store,
    this._auth,
  ) {
    _store.addListener(_onStoreChanged);
  }

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final SessionRatingsStore _store;
  final AuthViewModel _auth;

  /// 같은 movieId는 한 번만 조회한다. TMDB에 없는 영화(404)는 null로 캐시한다.
  final Map<int, TmdbMovieDto?> _movieCache = {};

  /// 늦게 도착한 이전 요청의 결과를 무시하기 위한 요청 번호.
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;

  /// 일부 영화 정보 누락 안내.
  String? message;

  // ---- Challenge: 다중 선택 삭제 ----

  bool isSelecting = false;

  /// 선택한 ratingId. 삭제에 실패한 항목은 선택 상태로 남겨 다시 시도할 수 있게 한다.
  final Set<int> selectedRatingIds = {};

  bool isDeletingSelected = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// 다른 화면(영화 상세)에서 등록하거나 세션이 바뀌면 목록을 다시 만든다.
  void _onStoreChanged() {
    if (status != MyRatingsLoadStatus.idle) load(showLoading: false);
  }

  Future<void> load({bool showLoading = true}) async {
    final version = ++_requestVersion;
    if (showLoading) {
      status = MyRatingsLoadStatus.loading;
      message = null;
      _notify();
    }

    final List<RatingDto> rawRatings = _store.ratings;
    final entries = <RatingWithMovie>[];
    var missingMovies = 0;
    // 영화 조회 실패가 평점 목록을 지우지 않도록 영화 한 편씩 따로 처리한다.
    for (final rating in rawRatings) {
      if (_disposed || version != _requestVersion) return;
      if (!_movieCache.containsKey(rating.movieId)) {
        try {
          _movieCache[rating.movieId] = await _movieService.findMovieById(
            rating.movieId,
          );
        } on DioException {
          // 일시적 네트워크 실패는 캐시하지 않고 다음 로딩에서 다시 시도한다.
        }
      }
      final movie = _movieCache[rating.movieId];
      if (movie == null) missingMovies++;
      entries.add(RatingWithMovie(rating: rating, movie: movie));
    }

    if (_disposed || version != _requestVersion) return;
    ratings = entries;
    selectedRatingIds.retainAll(entries.map((entry) => entry.rating.ratingId));
    if (entries.isEmpty) isSelecting = false;
    status = entries.isEmpty
        ? MyRatingsLoadStatus.empty
        : MyRatingsLoadStatus.success;
    message = missingMovies > 0 ? '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.' : null;
    _notify();
  }

  /// 쓰기 실패를 code별로 처리한 뒤 [RatingWriteException]으로 Dialog에 전달한다.
  Future<Never> _failWrite(
    DioException error, {
    required int sessionVersion,
    required int ratingId,
  }) async {
    final failure = RatingWriteException.fromDio(error);
    final code = failure.code;
    if (isSessionExpiredCode(code)) {
      await _auth.expireSession(version: sessionVersion);
    } else if (code == 'RATING404_1') {
      // 서버에 없는 평점이 화면에 남아 있으므로 목록에서 빼고 다시 그린다.
      _store.remove(sessionVersion, ratingId);
    }
    throw failure;
  }

  /// 평점 수정. comment는 생략하지 않고 항상 보낸다(null이면 후기 삭제).
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final sessionVersion = _auth.sessionVersion;
    final RatingDto updated;
    try {
      updated = await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
    } on DioException catch (error) {
      await _failWrite(
        error,
        sessionVersion: sessionVersion,
        ratingId: ratingId,
      );
    } on StateError {
      throw const RatingWriteException('수정 결과를 확인하지 못했습니다. 잠시 후 다시 확인해 주세요.');
    }
    // 로그아웃·회원 전환 뒤 도착한 이전 세션 응답은 Store가 무시한다.
    _store.upsert(sessionVersion, updated);
  }

  /// 평점 하나 삭제(v7은 200 + result null).
  Future<void> deleteRating(int ratingId) async {
    final sessionVersion = _auth.sessionVersion;
    try {
      await _service.deleteRating(ratingId);
    } on DioException catch (error) {
      await _failWrite(
        error,
        sessionVersion: sessionVersion,
        ratingId: ratingId,
      );
    } on StateError {
      throw const RatingWriteException('삭제 결과를 확인하지 못했습니다. 잠시 후 다시 확인해 주세요.');
    }
    _store.remove(sessionVersion, ratingId);
  }

  void startSelecting() {
    if (isDeletingSelected) return;
    isSelecting = true;
    selectedRatingIds.clear();
    _notify();
  }

  void cancelSelecting() {
    if (isDeletingSelected) return;
    isSelecting = false;
    selectedRatingIds.clear();
    _notify();
  }

  void toggleSelected(int ratingId) {
    if (!isSelecting || isDeletingSelected) return;
    if (!selectedRatingIds.remove(ratingId)) selectedRatingIds.add(ratingId);
    _notify();
  }

  /// 선택한 평점을 하나씩 삭제한다. 삭제하지 못한 개수를 돌려준다.
  ///
  /// 세션이 만료되면(401) 남은 요청을 보내지 않고 멈춘다.
  Future<int> deleteSelectedRatings() async {
    if (isDeletingSelected || selectedRatingIds.isEmpty) return 0;
    final sessionVersion = _auth.sessionVersion;
    isDeletingSelected = true;
    _notify();

    var failed = 0;
    try {
      // 원본 Set을 순회하며 remove하면 ConcurrentModificationError가 나므로 복사본을 돈다.
      final targets = selectedRatingIds.toList();
      for (var i = 0; i < targets.length; i++) {
        final ratingId = targets[i];
        if (_disposed || sessionVersion != _auth.sessionVersion) {
          return failed + targets.length - i;
        }
        try {
          await _service.deleteRating(ratingId);
          selectedRatingIds.remove(ratingId);
          _store.remove(sessionVersion, ratingId);
        } on DioException catch (error) {
          final code = apiErrorCode(error);
          if (isSessionExpiredCode(code)) {
            await _auth.expireSession(version: sessionVersion);
            return failed + targets.length - i;
          }
          if (code == 'RATING404_1') {
            // 이미 없는 평점은 지우려던 목표와 같으므로 목록에서만 뺀다.
            selectedRatingIds.remove(ratingId);
            _store.remove(sessionVersion, ratingId);
          } else {
            failed++;
          }
        } on StateError {
          failed++;
        }
      }
    } finally {
      isDeletingSelected = false;
      _notify();
    }
    if (_disposed) return failed;
    if (failed == 0) isSelecting = false;
    await load(showLoading: false);
    return failed;
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }
}
