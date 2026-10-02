import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 회원가입 화면 하단의 로그인 안내 문구.
///
/// 로그인 화면은 이번 미션 범위에 없으므로 시안의 모양만 표시한다.
class SignUpFooter extends StatelessWidget {
  const SignUpFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '이미 계정이 있나요?  ',
        style: AppTextStyles.bodyMedium,
        children: <InlineSpan>[
          TextSpan(
            text: '로그인',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
