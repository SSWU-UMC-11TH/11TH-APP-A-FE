import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_colors.dart';

/// 사용자가 별 한 개(1점) 단위로 별점을 선택하는 Widget.
///
/// 별점을 어떻게 입력할지만 담당하고, 실제 값은 부모 Widget이 관리한다.
///
/// 7주차 서버 연동 모드: v6 평점 score는 1~5 정수이므로 반 점 입력을 끈다.
/// RatingBar는 항상 double을 돌려주므로 [onChanged]에는 1.0, 2.0처럼
/// 정수를 나타내는 double이 전달된다. [enabled]가 false면 탭을 무시한다(저장 중).
class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.enabled = true,
  });

  final double rating;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 1,
      allowHalfRating: false,
      ignoreGestures: !enabled,
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
