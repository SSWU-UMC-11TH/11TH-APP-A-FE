import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_colors.dart';

/// 사용자가 0.5점 단위로 별점을 선택하는 Widget.
///
/// 별점을 어떻게 입력할지만 담당하고, 실제 값은 부모 Widget이 관리한다.
///
/// 2주차 추가 미니 실습(`flutter_rating_bar`)에 해당하지만 3주차를 먼저 진행해
/// 3주차에서 구현했다. 선택한 값은 RatingDialog가 `setState`로 갱신한다.
class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
  });

  final double rating;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 0.5,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: 40,
      glow: false,
      itemBuilder: (BuildContext context, int index) {
        return const Icon(Icons.star, color: AppColors.star);
      },
      onRatingUpdate: onChanged,
    );
  }
}
