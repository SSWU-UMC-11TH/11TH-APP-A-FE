import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsStatus { idle, loading, empty, error, success }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._ratingsService, this._movieService);

  static const sampleMemberId = 1;
  final RatingApiService _ratingsService;
  final TmdbMovieService _movieService;

  MyRatingsStatus status = MyRatingsStatus.idle;
  List<RatingDto> ratings = [];
  Map<int, TmdbMovieDto> moviesById = {};
  String? errorMessage;
  String? movieWarning;

  bool _disposed = false;
  int _version = 0;

  Future<void> load() async {
    if (_disposed) return;
    final version = ++_version;
    status = MyRatingsStatus.loading;
    errorMessage = null;
    movieWarning = null;
    notifyListeners();

    bool isCurrent() => !_disposed && version == _version;

    try {
      final loaded = await _ratingsService.fetchMyRatings(sampleMemberId);
      if (!isCurrent()) return;

      if (loaded.isEmpty) {
        ratings = [];
        moviesById = {};
        status = MyRatingsStatus.empty;
        notifyListeners();
        return;
      }

      final movies = <int, TmdbMovieDto>{};
      var detailFailed = false;

      await Future.wait(
        loaded.map((rating) => rating.movieId).toSet().map((id) async {
          try {
            final movie = await _movieService.findMovieById(id);
            if (movie != null) {
              movies[id] = movie;
            } else {
              detailFailed = true;
            }
          } catch (_) {
            detailFailed = true;
          }
        }),
      );

      if (!isCurrent()) return;
      ratings = loaded;
      moviesById = movies;
      movieWarning = detailFailed
          ? '일부 영화 정보를 가져오지 못했습니다. 평점은 정상 표시합니다.'
          : null;
      status = MyRatingsStatus.success;
    } on DioException catch (error) {
      if (!isCurrent()) return;
      errorMessage = writeMyRatingsErrorMessage(error);
      status = MyRatingsStatus.error;
    } catch (_) {
      if (!isCurrent()) return;
      errorMessage = '평점 응답을 읽지 못했습니다. 다시 시도해 주세요.';
      status = MyRatingsStatus.error;
    }

    if (isCurrent()) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    super.dispose();
  }
}
