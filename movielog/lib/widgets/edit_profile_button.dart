import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 프로필 수정 버튼.
///
/// 보조 동작이라 배경이 있는 ElevatedButton 대신 TextButton을 사용하고,
/// 시안처럼 보라색 테두리만 둘렀다. 1주차에서는 모양만 구현한다.
class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: AppTextStyles.titleMedium,
      ),
      child: const Text('프로필 수정'),
    );
  }
}
