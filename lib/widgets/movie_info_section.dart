import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MovieInfoSection extends StatelessWidget {
  const MovieInfoSection({super.key, required this.movie});

  final Movie movie;

  // 1245 -> 1,245
  String _formatCount(int count) => count.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(movie.title, style: AppTextStyles.titleMedium),
        const SizedBox(height: 4),
        Text(
          '${movie.year} • ${movie.genre} • ${movie.runtimeMinutes}분',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // 평균 평점은 읽기 전용으로 표시한다.
            RatingBarIndicator(
              rating: movie.rating,
              itemCount: 5,
              itemSize: 20,
              unratedColor: AppColors.lavender,
              itemBuilder: (context, index) {
                return const Icon(Icons.star, color: AppColors.violet);
              },
            ),
            const SizedBox(width: 8),
            Text(
              movie.rating.toStringAsFixed(1),
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${_formatCount(movie.ratingCount)})',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final tag in movie.tags) _TagChip(label: tag)],
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: AppTextStyles.labelMedium),
    );
  }
}
