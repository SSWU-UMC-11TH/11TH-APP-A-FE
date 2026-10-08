import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 보여줄 영화가 없을 때의 Empty 상태 화면.
///
/// 서버가 빈 목록을 돌려준 경우와 선택한 장르에 영화가 없는 경우 모두 사용한다.
class MovieListEmpty extends StatelessWidget {
  const MovieListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.movie_outlined, size: 48, color: AppColors.label),
          const SizedBox(height: 12),
          Text('조건에 맞는 영화가 없어요', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
