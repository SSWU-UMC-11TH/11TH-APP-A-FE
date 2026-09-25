import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      // 1주차: 모양만 구현하고 화면 이동은 넣지 않음
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: AppColors.violet,
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: const BorderSide(color: AppColors.violet),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      child: const Text('프로필 수정'),
    );
  }
}
