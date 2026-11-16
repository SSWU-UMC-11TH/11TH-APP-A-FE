import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 마이페이지에서 "내가 등록한 평점" 자식 화면으로 들어가는 진입 행.
///
/// 뒤로가면 마이페이지로 돌아와야 하므로 go가 아닌 push로 연다.
class MyRatingsEntry extends StatelessWidget {
  const MyRatingsEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(14);

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.primaryContainer, width: 2),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: radius),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        title: const Text('내가 등록한 평점', style: AppTextStyles.titleMedium),
        trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
        onTap: () => context.push('/my/ratings'),
      ),
    );
  }
}
