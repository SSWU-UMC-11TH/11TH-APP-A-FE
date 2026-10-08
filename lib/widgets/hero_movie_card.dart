import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class HeroMovieCard extends StatelessWidget {
  const HeroMovieCard({super.key, required this.movie, this.onDetailTap});

  final Movie movie;
  final VoidCallback? onDetailTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 356 / 504,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(movie.posterAsset, fit: BoxFit.cover),
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
                  const SizedBox(height: 4),
                  Text(
                    '${movie.genre} · ${movie.year}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),
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
