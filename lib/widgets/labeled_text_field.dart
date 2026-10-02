import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.validator,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  static const _labelStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    height: 24 / 16,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: _decoration(),
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
        ),
      ],
    );
  }

  InputDecoration _decoration() {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    // 입력이 시작된 뒤에만 검증 결과 아이콘을 보여준다.
    Widget? suffixIcon;
    if (controller.text.isNotEmpty) {
      suffixIcon = validator(controller.text) == null
          ? const Icon(Icons.check_circle, color: AppColors.violet)
          : const Icon(Icons.error_outline, color: AppColors.error);
    }

    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.gray),
      errorStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.error),
      filled: true,
      fillColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.error)
            ? AppColors.errorContainer
            : AppColors.surfaceLow,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      suffixIcon: suffixIcon == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 12),
              child: suffixIcon,
            ),
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.violet, 2),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, 2),
    );
  }
}
