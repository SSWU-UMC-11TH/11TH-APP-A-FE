import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_theme.dart';

/// 사용자가 0.5점 단위로 별점을 선택하는 Widget.
///
/// 별점을 어떻게 입력할지만 담당하고, 실제 값은 부모 Widget이 관리한다.
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
        return const Icon(
          Icons.star,
          color: AppColors.star,
        );
      },
      onRatingUpdate: onChanged,
    );
  }
}
