import 'package:flutter/material.dart';

/// MovieLog의 모든 화면이 공유하는 색상 값.
class AppColors {
  AppColors._();

  /// 기본 보라색. 버튼, 선택된 Chip, 강조 텍스트에 사용한다.
  static const Color primary = Color(0xFF5B3E8E);

  /// 선택되지 않은 Chip, 통계 카드처럼 옅은 강조가 필요할 때 사용한다.
  static const Color primaryContainer = Color(0xFFEDE4F8);

  /// 앱 공통 크림색 배경
  static const Color background = Color(0xFFFBF8F3);

  /// 카드, 상세 화면처럼 배경 위에 올라가는 면
  static const Color surface = Color(0xFFFFFFFF);

  /// 제목 텍스트
  static const Color title = Color(0xFF1F1B24);

  /// 본문 텍스트
  static const Color body = Color(0xFF6B6572);

  /// 보조 라벨 텍스트
  static const Color label = Color(0xFF8A8491);

  /// 별점 아이콘
  static const Color star = Color(0xFFFFB400);

  /// 포스터 위 평점 Badge 배경
  static const Color badge = Color(0xCC2C2735);
}

/// 앱 전체에서 사용하는 Material 3 Theme.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.primary,
          surface: AppColors.background,
          onSurface: AppColors.title,
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.title,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 26,
          height: 1.35,
          fontWeight: FontWeight.bold,
          color: AppColors.title,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.title,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.title,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: AppColors.body,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.5,
          color: AppColors.label,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.bold
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.label,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.label,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.title,
        contentTextStyle: const TextStyle(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
