import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PopularMovieCard extends StatelessWidget {
  const PopularMovieCard({
    super.key,
    required this.movie,
    required this.rank,
    this.onTap,
  });

  final Movie movie;
  final int rank;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(movie.posterAsset, fit: BoxFit.cover),
                  ),
                  Positioned(top: 8, left: 8, child: _RankBadge(rank: rank)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: AppColors.star),
                const SizedBox(width: 4),
                Text(
                  movie.rating.toStringAsFixed(1),
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$rank',
        style: AppTextStyles.labelMedium.copyWith(color: AppColors.white),
      ),
    );
  }
}
