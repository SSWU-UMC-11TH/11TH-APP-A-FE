import 'package:flutter/material.dart';
import 'app_colors.dart';

// Design System Typography Guide 기준 (fontSize / lineHeight / letterSpacing)
abstract final class AppTextStyles {
  // Title Large (Headline Large) 28 / 36 / 0
  static const titleLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
    height: 36 / 28,
  );

  // Title Medium (Headline Medium) 24 / 32 / 0
  static const titleMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
    height: 32 / 24,
  );

  // Body Large 16 / 24 / 0.5
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
    height: 24 / 16,
    letterSpacing: 0.5,
  );

  // Body Medium 14 / 20 / 0.25
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.darkGray,
    height: 20 / 14,
    letterSpacing: 0.25,
  );

  // Label Large (Button Label) 14 / 20 / 0.1
  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.1,
  );

  // Label Small (Metadata & Captions) 11 / 16 / 0.5
  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.darkGray,
    height: 16 / 11,
    letterSpacing: 0.5,
  );
}
