import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class FavoriteGenres extends StatelessWidget {
  const FavoriteGenres({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 통계 영역과 떨어뜨리는 바깥 여백
      margin: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '선호하는 장르',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GenreChip(label: '드라마'),
              GenreChip(label: 'SF'),
              GenreChip(label: '애니메이션'),
            ],
          ),
        ],
      ),
    );
  }
}

class GenreChip extends StatelessWidget {
  const GenreChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.deepViolet,
        fontWeight: FontWeight.w500,
      ),
      labelPadding: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      backgroundColor: AppColors.lavender,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
