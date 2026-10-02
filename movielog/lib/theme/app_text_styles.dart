import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 앱에서 공통으로 사용하는 글자 스타일.
///
/// 화면에서는 이 스타일을 그대로 쓰거나, 일부만 바꿀 때 `copyWith`를 사용한다.
abstract final class AppTextStyles {
  /// 화면 대표 제목 (시작 화면, 회원가입)
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 26,
    height: 1.35,
    fontWeight: FontWeight.bold,
    color: AppColors.title,
  );

  /// 섹션 제목, AppBar 제목
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.title,
  );

  /// 카드 제목, 소제목
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.title,
  );

  /// 본문
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: AppColors.body,
  );

  /// 보조 라벨
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    height: 1.5,
    color: AppColors.label,
  );
}
