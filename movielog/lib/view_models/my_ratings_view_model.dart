import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

export '../data/services/rating_api_service.dart' show RatingWriteException;

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

/// 내가 등록한 평점 화면의 상태 (조회·수정·삭제).
///
/// 자체 백엔드에서 평점 목록을 받고, 각 movieId로 TMDB 영화 정보를 붙여
/// [RatingWithMovie] 목록을 만든다.
/// [memberId]는 회원가입 결과를 보관한 LearningMemberSession에서 전달받는다.
///
/// 쓰기(수정·삭제) 성공과 그 뒤 목록 재조회(GET) 성공은 서로 다른 상태다.
/// 쓰기가 성공했으면 GET이 실패해도 쓰기 실패로 되돌리지 않고 [refreshWarning]만 남긴다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;

  /// 같은 movieId는 한 번만 조회한다. TMDB에 없는 영화(404)는 null로 캐시한다.
  final Map<int, TmdbMovieDto?> _movieCache = {};

  /// 늦게 도착한 이전 요청의 결과를 무시하기 위한 요청 번호.
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;

  /// Error 상태에서는 실패 안내, Success 상태에서는 일부 영화 정보 누락 안내.
  String? message;

  /// 저장(수정·삭제)은 완료됐지만 재조회 GET만 실패했을 때의 안내.
  /// 다음 조회가 성공하면 사라진다.
  String? refreshWarning;

  static const String refreshFailedText =
      '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';

  // ---- Challenge: 다중 선택 삭제 ----

  /// 편집(다중 선택) 모드 여부. 켜지면 카드의 수정·삭제 버튼 대신 CheckBox를 보여준다.
  bool isSelecting = false;

  /// 선택한 ratingId. 삭제에 실패한 항목은 선택 상태로 남겨 다시 시도할 수 있게 한다.
  final Set<int> selectedRatingIds = {};

  /// 여러 건을 순서대로 지우는 동안 true. 화면은 로딩 오버레이와 이탈 방지를 건다.
  bool isDeletingSelected = false;

  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (_disposed || version != _requestVersion) return;

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
      refreshWarning = null;
      // 서버에서 사라진 평점은 선택 목록에서도 뺀다.
      selectedRatingIds.retainAll(
        entries.map((entry) => entry.rating.ratingId),
      );
      // 빈 배열은 실패가 아니라 Empty 상태다.
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (missingMovies > 0) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } on DioException catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    }

    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  /// 쓰기가 성공한 뒤 목록을 서버 상태와 맞춘다. GET 실패는 다시 던지지 않는다.
  Future<void> _refreshAfterWrite() async {
    await load(); // load()는 GET 실패를 status=error로 기록한다.
    if (_disposed) return;
    if (status == MyRatingsLoadStatus.error) {
      refreshWarning = refreshFailedText;
      notifyListeners();
    }
  }

  /// 쓰기 실패를 [RatingWriteException]으로 바꿔 Dialog에 전달한다.
  ///
  /// 403(본인 평점 아님)·404(평점 없음)는 화면 목록이 서버와 어긋난 것이므로 다시 조회한다.
  Future<Never> _failWrite(DioException error) async {
    final failure = RatingWriteException.fromDio(error);
    if (!_disposed && shouldRefreshAfterRatingError(error)) await load();
    throw failure;
  }

  /// 평점 수정. 실패하면 [RatingWriteException]을 던져 Dialog가 입력을 유지한 채 안내한다.
  ///
  /// comment는 생략하지 않고 항상 보낸다(null이면 후기 삭제).
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    try {
      await _service.updateRating(
        memberId: memberId,
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
    } on DioException catch (error) {
      await _failWrite(error);
    }
    if (_disposed) return;
    await _refreshAfterWrite();
  }

  /// 평점 하나 삭제(204). 실패하면 [RatingWriteException]을 던진다.
  Future<void> deleteRating(int ratingId) async {
    try {
      await _service.deleteRating(memberId: memberId, ratingId: ratingId);
    } on DioException catch (error) {
      await _failWrite(error);
    } on StateError {
      throw const RatingWriteException('삭제 결과를 확인하지 못했습니다. 목록을 다시 확인해 주세요.');
    }
    if (_disposed) return;
    await _refreshAfterWrite();
  }

  void startSelecting() {
    if (isDeletingSelected) return;
    isSelecting = true;
    selectedRatingIds.clear();
    notifyListeners();
  }

  /// 선택을 모두 해제하고 기본 목록으로 돌아간다.
  void cancelSelecting() {
    if (isDeletingSelected) return;
    isSelecting = false;
    selectedRatingIds.clear();
    notifyListeners();
  }

  void toggleSelected(int ratingId) {
    if (!isSelecting || isDeletingSelected) return;
    if (!selectedRatingIds.remove(ratingId)) selectedRatingIds.add(ratingId);
    notifyListeners();
  }

  /// 선택한 평점을 하나씩 삭제한다. 삭제하지 못한 개수를 돌려준다.
  ///
  /// 성공한 항목만 선택에서 빼고, 실패한 항목은 선택 상태를 유지한다.
  /// 모두 끝나면 목록을 다시 조회하며, GET 실패는 삭제 결과와 분리한다.
  Future<int> deleteSelectedRatings() async {
    if (isDeletingSelected || selectedRatingIds.isEmpty) return 0;
    isDeletingSelected = true;
    notifyListeners();

    var failed = 0;
    try {
      // 원본 Set을 순회하며 remove하면 ConcurrentModificationError가 나므로 복사본을 돈다.
      for (final ratingId in selectedRatingIds.toList()) {
        if (_disposed) return failed;
        try {
          await _service.deleteRating(memberId: memberId, ratingId: ratingId);
          selectedRatingIds.remove(ratingId);
        } on DioException {
          failed++;
        } on StateError {
          failed++;
        }
      }
    } finally {
      isDeletingSelected = false;
      // 예상하지 못한 오류에도 로딩을 해제한다.
      if (!_disposed) notifyListeners();
    }
    if (_disposed) return failed;

    if (failed == 0) isSelecting = false;
    await _refreshAfterWrite();
    return failed;
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
