import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 영화 목록을 불러오지 못했을 때의 Error 상태 화면.
///
/// 내부 Exception이나 StackTrace는 보여주지 않고,
/// 사용자가 할 수 있는 행동인 `다시 시도` 버튼을 함께 제공한다.
class MovieListError extends StatelessWidget {
  const MovieListError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text('영화를 불러오지 못했어요', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '네트워크 상태를 확인한 뒤 다시 시도해주세요',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
