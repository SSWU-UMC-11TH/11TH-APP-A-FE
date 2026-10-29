import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/detail_action_bar.dart';
import '../widgets/movie_info_section.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movie});

  // 목록·홈 카드가 extra로 넘긴 TMDB 영화. 주소만으로 들어오면 null이다.
  final TmdbMovieDto? movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  // 즐겨찾기와 내 평점은 API 없이 화면 내부 상태로만 관리한다.
  bool _isFavorite = false;
  double _myRating = 0;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _showMessage(_isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.');
  }

  Future<void> _rateMovie(TmdbMovieDto movie) async {
    final rating = await showDialog<double>(
      context: context,
      builder: (context) =>
          RatingDialog(movieId: movie.id, initialRating: _myRating),
    );

    if (rating == null || !mounted) return;

    // 평점 API 연동 전까지 전달될 movieId를 로그로 확인한다.
    debugPrint('[평점] movieId=${movie.id} score=$rating');
    setState(() => _myRating = rating);
    _showMessage('평점 ${rating.toStringAsFixed(1)}점을 남겼습니다.');
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Cinema Archive',
        centerTitle: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
        actions: const [
          IconButton(
            onPressed: null,
            icon: Icon(Icons.share_outlined, color: AppColors.violet),
            tooltip: '공유',
          ),
        ],
      ),
      body: movie == null
          ? const Center(child: Text('영화를 찾을 수 없습니다.'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 2 / 3,
                    child: TmdbPosterImage(posterPath: movie.posterPath),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: MovieInfoSection(movie: movie),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '시놉시스',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _Overview(overview: movie.overview),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: movie == null
          ? null
          : DetailActionBar(
              isFavorite: _isFavorite,
              onFavoriteTap: _toggleFavorite,
              onRateTap: () => _rateMovie(movie),
            ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.overview});

  final String overview;

  @override
  Widget build(BuildContext context) {
    // 줄거리가 없으면 화면 중앙에 안내 문구를 보여준다.
    if (overview.trim().isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('줄거리 정보가 없어요.', style: AppTextStyles.bodyMedium),
        ),
      );
    }

    return Text(
      overview,
      style: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.darkGray,
        letterSpacing: 0,
      ),
    );
  }
}
