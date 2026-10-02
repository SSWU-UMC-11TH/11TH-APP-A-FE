import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 필수 약관 동의 Checkbox.
///
/// 선택 여부(`value`)는 부모 화면의 State가 소유하고,
/// 이 Widget은 사용자의 변경을 `onChanged`로 알리기만 한다.
/// 문구를 눌러도 체크가 바뀌도록 Row 전체를 InkWell로 감쌌다.
class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: <Widget>[
          Checkbox(
            value: value,
            // Checkbox의 onChanged는 nullable이므로 null은 해제로 취급한다.
            onChanged: (bool? checked) => onChanged(checked ?? false),
            activeColor: AppColors.primary,
            side: const BorderSide(color: AppColors.fieldBorder, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '필수 약관에 동의합니다',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
