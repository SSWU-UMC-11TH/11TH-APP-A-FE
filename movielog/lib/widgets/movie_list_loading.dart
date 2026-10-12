import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 영화 목록을 불러오는 동안 보여주는 Loading 상태 화면.
///
/// 빈 화면만 두지 않고 진행 표시와 안내 문구를 함께 보여준다.
class MovieListLoading extends StatelessWidget {
  const MovieListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text('영화를 불러오는 중이에요', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
