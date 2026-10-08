import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/detail_action_bar.dart';
import '../widgets/movie_info_section.dart';
import '../widgets/rating_dialog.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final String? movieId;

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

  Future<void> _rateMovie() async {
    final rating = await showDialog<double>(
      context: context,
      builder: (context) => RatingDialog(initialRating: _myRating),
    );

    if (rating == null || !mounted) return;

    setState(() => _myRating = rating);
    _showMessage('평점 ${rating.toStringAsFixed(1)}점을 남겼습니다.');
  }

  @override
  Widget build(BuildContext context) {
    final movie = findMovieById(int.tryParse(widget.movieId ?? ''));

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
                    child: Image.asset(movie.posterAsset, fit: BoxFit.cover),
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
                        Text(
                          movie.synopsis,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.darkGray,
                            letterSpacing: 0,
                          ),
                        ),
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
              onRateTap: _rateMovie,
            ),
    );
  }
}
