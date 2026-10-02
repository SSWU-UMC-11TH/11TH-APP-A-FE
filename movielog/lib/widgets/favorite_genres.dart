import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 선호하는 장르 제목과 장르 Chip 목록.
class FavoriteGenres extends StatelessWidget {
  const FavoriteGenres({super.key});

  @override
  Widget build(BuildContext context) {
    // Column의 교차축(가로)을 start로 두어 제목과 Chip을 왼쪽에 맞춘다.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '선호하는 장르',
          style: AppTextStyles.titleMedium.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 12),
        const Row(
          children: <Widget>[
            GenreChip(label: '드라마'),
            SizedBox(width: 8),
            GenreChip(label: 'SF'),
            SizedBox(width: 8),
            GenreChip(label: '애니메이션'),
          ],
        ),
      ],
    );
  }
}

/// 장르 이름 하나를 보여주는 연보라색 Chip.
class GenreChip extends StatelessWidget {
  const GenreChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: AppTextStyles.bodySmall.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
      backgroundColor: AppColors.primaryContainer,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
