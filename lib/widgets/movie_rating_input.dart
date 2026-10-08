import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_colors.dart';

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
    // 좁은 화면에서도 별 5개가 한 줄에 보이도록 필요할 때만 줄인다.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: RatingBar.builder(
        initialRating: rating,
        minRating: 0.5,
        allowHalfRating: true,
        itemCount: 5,
        itemSize: 40,
        unratedColor: AppColors.lavender,
        itemBuilder: (context, index) {
          return const Icon(Icons.star, color: AppColors.violet);
        },
        onRatingUpdate: onChanged,
      ),
    );
  }
}
