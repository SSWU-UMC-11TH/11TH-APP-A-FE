import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600),
        ),
        if (actionLabel != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onActionTap,
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.deepViolet,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.deepViolet,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
