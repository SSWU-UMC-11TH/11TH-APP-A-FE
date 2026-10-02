import 'package:flutter/material.dart';

import 'stat_item.dart';

/// 본 영화·평점·즐겨찾기 통계를 가로로 나란히 보여주는 영역.
class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    // Row의 주축(가로)은 Expanded가 세 칸을 같은 너비로 나누고,
    // 교차축(세로)은 center로 카드 높이를 맞춘다.
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: StatItem(label: '본 영화', value: '342'),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatItem(label: '평점', value: '4.2'),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatItem(label: '즐겨찾기', value: '58'),
        ),
      ],
    );
  }
}
