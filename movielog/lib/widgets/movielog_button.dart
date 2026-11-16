import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 여러 화면이 함께 쓰는 공용 버튼.
///
/// 버튼은 상태를 표시만 하고 스스로 바꾸지 않는다.
/// 지금 통신 중인지([isLoading]), 누를 수 있는지([onPressed]),
/// 너비를 얼마나 쓸지([width])는 화면이 ViewModel 상태를 보고 전달한다.
///
/// - 기본: [onPressed]가 있고 [isLoading]이 false
/// - 통신 중: [isLoading]이 true. 회색 배경에 인디케이터만 보이고 눌리지 않는다.
/// - 비활성: [onPressed]가 null. 연보라 배경으로 눌리지 않는다.
class MovieLogButton extends StatelessWidget {
  const MovieLogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// null이면 label 길이에 맞는 내용 기반 크기,
  /// [double.infinity]면 부모가 허용하는 최대 너비, 숫자면 그 값으로 고정한다.
  final double? width;

  /// 입력창과 나란히 놓였을 때 높이가 맞도록 입력창 높이(52)를 기본으로 쓴다.
  final double height;

  bool get _disabled => isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: _disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          // 통신 중은 회색, 조건 미충족 비활성은 연보라로 구분한다.
          disabledBackgroundColor: isLoading
              ? AppColors.loading
              : AppColors.primaryDisabled,
          disabledForegroundColor: Colors.white,
          // AppTheme의 minimumSize는 가로가 무한대라 Row 안에서 쓰면 오류가 나므로
          // 너비 결정은 SizedBox에 맡기고 최소 크기만 다시 지정한다.
          minimumSize: Size(64, height),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        // 통신 중에는 label과 인디케이터 중 인디케이터 하나만 그린다.
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
