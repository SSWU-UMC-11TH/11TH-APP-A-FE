import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 회원가입 화면 상단의 환영 문구.
///
/// 입력 Form과 분리해 두어 문구가 바뀌어도 화면 State를 건드리지 않는다.
class SignUpHeader extends StatelessWidget {
  const SignUpHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
      textAlign: TextAlign.center,
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 15,
        height: 1.6,
        color: AppColors.title,
      ),
    );
  }
}
