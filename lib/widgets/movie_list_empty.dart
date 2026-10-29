import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MovieListEmpty extends StatelessWidget {
  const MovieListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.movie_filter_outlined,
              size: 48,
              color: AppColors.gray,
            ),
            const SizedBox(height: 12),
            Text(
              '조건에 맞는 영화가 없습니다.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(letterSpacing: 0),
            ),
            const SizedBox(height: 4),
            const Text(
              '다른 장르를 선택해보세요.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
