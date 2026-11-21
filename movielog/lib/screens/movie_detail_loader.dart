import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../theme/app_colors.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/session_ratings_store.dart';
import 'movie_detail_screen.dart';

/// 영화 상세 화면의 시작점.
///
/// 목록·홈에서 넘어오면 `extra`의 [TmdbMovieDto]를 그대로 쓰고,
/// 직접 접근·Deep Link처럼 extra가 없으면 TMDB `GET /movie/{movie_id}`로 다시 조회한다.
/// 영화가 준비되면 [MovieDetailViewModel]을 만들어 [MovieDetailScreen]에 제공한다.
class MovieDetailLoader extends StatefulWidget {
  const MovieDetailLoader({
    super.key,
    required this.movieId,
    this.initialMovie,
  });

  final int movieId;
  final TmdbMovieDto? initialMovie;

  @override
  State<MovieDetailLoader> createState() => _MovieDetailLoaderState();
}

class _MovieDetailLoaderState extends State<MovieDetailLoader> {
  // build마다 새 Future를 만들지 않도록 State에 보관한다. 다시 시도할 때만 교체한다.
  late Future<TmdbMovieDto> _movieFuture = _fetch();

  Future<TmdbMovieDto> _fetch() {
    final TmdbMovieDto? initial = widget.initialMovie;
    if (initial != null) return Future<TmdbMovieDto>.value(initial);
    return context.read<TmdbMovieService>().fetchMovieDetail(widget.movieId);
  }

  void _retry() => setState(() => _movieFuture = _fetch());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TmdbMovieDto>(
      future: _movieFuture,
      builder: (BuildContext context, AsyncSnapshot<TmdbMovieDto> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final TmdbMovieDto? movie = snapshot.data;
        if (snapshot.hasError || movie == null) {
          final Object? error = snapshot.error;
          final bool notFound =
              error is DioException && error.response?.statusCode == 404;
          return MovieDetailFailure(
            message: notFound ? '찾을 수 없는 영화예요' : '영화를 불러오지 못했습니다.',
            onRetry: notFound ? null : _retry,
          );
        }
        return ChangeNotifierProvider<MovieDetailViewModel>(
          create: (BuildContext context) => MovieDetailViewModel(
            context.read<RatingApiService>(),
            // 8주차: memberId 대신 토큰으로 회원을 식별하고, 등록 결과는 세션 Store에 담는다.
            context.read<SessionRatingsStore>(),
            context.read<AuthViewModel>(),
            movie,
          ),
          child: const MovieDetailScreen(),
        );
      },
    );
  }
}

/// 영화 ID가 잘못됐거나, 영화를 찾지 못했거나, 불러오지 못했을 때 보여주는 화면.
class MovieDetailFailure extends StatelessWidget {
  const MovieDetailFailure({super.key, required this.message, this.onRetry});

  final String message;

  /// null이면(404·잘못된 ID) 다시 시도 버튼 없이 목록으로만 안내한다.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/movies'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48, color: AppColors.label),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            if (onRetry != null) ...<Widget>[
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('다시 시도'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => context.go('/movies'),
                child: const Text('영화 목록으로'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
