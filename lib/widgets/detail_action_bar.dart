import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DetailActionBar extends StatelessWidget {
  const DetailActionBar({
    super.key,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onRateTap,
  });

  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onRateTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.warmWhite,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFavoriteTap,
                  icon: Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    size: 20,
                  ),
                  label: const Text('즐겨찾기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.violet,
                    side: const BorderSide(color: AppColors.violet),
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                    textStyle: AppTextStyles.labelLarge,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRateTap,
                  icon: const Icon(Icons.rate_review_outlined, size: 20),
                  label: const Text('평점 남기기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.violet,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                    textStyle: AppTextStyles.labelLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
