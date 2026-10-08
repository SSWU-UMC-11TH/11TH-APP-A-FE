import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary Scale
  static const violet = Color(0xFF6750A4); // 500
  static const deepViolet = Color(0xFF4F378A); // 600
  static const lightViolet = Color(0xFFD0BCFF); // 300
  static const lavender = Color(0xFFE9DDFF); // 200

  // Surface Tones
  static const warmWhite = Color(0xFFFAF9F5); // Base Surface
  static const surfaceLow = Color(0xFFF5F3F0); // Low
  static const white = Color(0xFFFFFFFF); // Lowest

  // Text
  static const black = Color(0xFF1C1B1F);
  static const darkGray = Color(0xFF49454F);
  static const gray = Color(0xFF79747E);

  // Input
  static const border = Color(0xFFCAC4D0);

  // Rating
  static const star = Color(0xFFC9A24B);

  // Error
  static const error = Color(0xFFB3261E);
  static const errorContainer = Color(0xFFFFDAD6);
}
