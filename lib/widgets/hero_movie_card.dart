import 'package:flutter/material.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/movie_formatters.dart';
import 'tmdb_poster_image.dart';

class HeroMovieCard extends StatelessWidget {
  const HeroMovieCard({super.key, required this.movie, this.onDetailTap});

  final TmdbMovieDto movie;
  final VoidCallback? onDetailTap;

  @override
  Widget build(BuildContext context) {
    final year = releaseYear(movie.releaseDate);

    return AspectRatio(
      aspectRatio: 356 / 504,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            TmdbPosterImage(posterPath: movie.posterPath),
            // 글자가 잘 보이도록 아래쪽을 어둡게 덮는다.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.black.withValues(alpha: 0),
                    AppColors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.4, 1],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _NewBadge(),
                  const SizedBox(height: 8),
                  Text(
                    movie.title,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  // release_date가 없으면 연도 줄을 표시하지 않는다.
                  if (year != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      year,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: onDetailTap,
                    icon: const Icon(Icons.info, size: 20),
                    label: const Text('상세보기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepViolet,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      textStyle: AppTextStyles.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.violet,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '추천 신작',
        style: AppTextStyles.labelMedium.copyWith(color: AppColors.white),
      ),
    );
  }
}
