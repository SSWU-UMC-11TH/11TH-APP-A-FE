import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      primary: AppColors.violet,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.lavender,
      onPrimaryContainer: AppColors.deepViolet,
      surface: AppColors.warmWhite,
      onSurface: AppColors.black,
      onSurfaceVariant: AppColors.darkGray,
      surfaceContainerLow: AppColors.surfaceLow,
      outline: AppColors.lightViolet,
      outlineVariant: AppColors.lavender,
    ),
    textTheme: const TextTheme(
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      titleSmall: AppTextStyles.titleSmall,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    ),
    scaffoldBackgroundColor: AppColors.warmWhite,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.warmWhite,
      foregroundColor: AppColors.black,
      centerTitle: true,
      titleTextStyle: AppTextStyles.titleMedium.copyWith(
        color: AppColors.violet,
      ),
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.warmWhite,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.warmWhite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: AppColors.lavender,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.deepViolet
              : AppColors.darkGray,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => AppTextStyles.labelMedium.copyWith(
          color: states.contains(WidgetState.selected)
              ? AppColors.deepViolet
              : AppColors.darkGray,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
  );
}
