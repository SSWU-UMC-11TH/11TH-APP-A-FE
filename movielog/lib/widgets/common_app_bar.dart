import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 모든 화면이 공유하는 AppBar.
///
/// AppBar의 공통 구조는 여기서 관리하고, 화면마다 달라지는
/// 제목·뒤로가기 이벤트·오른쪽 버튼만 생성자로 전달받는다.
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.centerTitle = false,
    this.titleStyle,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        // 스타일을 따로 주지 않으면 보라색 titleLarge를 기본으로 사용한다.
        style:
            titleStyle ??
            AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
      ),
      centerTitle: centerTitle,
      leading: onBack == null
          ? null
          : IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
      actions: actions,
    );
  }

  /// Scaffold의 appBar 영역에서 사용할 높이
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
