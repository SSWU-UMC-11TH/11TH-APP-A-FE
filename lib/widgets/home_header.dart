import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.onSearchTap});

  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'MovieLog',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.deepViolet,
          ),
        ),
        IconButton(
          onPressed: onSearchTap,
          icon: const Icon(Icons.search, color: AppColors.deepViolet),
          tooltip: '검색',
        ),
      ],
    );
  }
}
