import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/auth_view_model.dart';

/// 프로필 수정 버튼.
///
/// 보조 동작이라 배경이 있는 ElevatedButton 대신 테두리만 있는 TextButton을 쓴다.
/// 8주차부터 내 정보(member)가 있을 때만 켜고, 뒤로가면 마이페이지로 돌아오도록 push한다.
class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    final bool hasMember = context.select<AuthViewModel, bool>(
      (AuthViewModel auth) => auth.member != null,
    );
    return TextButton(
      onPressed: hasMember ? () => context.push('/my/profile/edit') : null,
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
