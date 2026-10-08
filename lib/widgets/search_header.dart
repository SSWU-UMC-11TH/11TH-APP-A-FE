import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader({super.key, required this.title, this.onSearchTap});

  final String title;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
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
