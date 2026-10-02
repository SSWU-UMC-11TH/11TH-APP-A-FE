import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'movie_rating_input.dart';

/// 별점을 직접 선택하는 커스텀 Dialog.
///
/// 확인을 누르면 선택한 별점을 `Navigator.pop`의 결과로 돌려준다.
///
/// 2주차 추가 미니 실습(`flutter_rating_bar`로 평점 입력 상태 다루기)에 해당하지만,
/// 3주차를 먼저 진행하면서 상세 화면의 평점 남기기 기능으로 구현했다.
/// 별점을 선택하기 전에는 확인 버튼이 비활성화되고, 선택하면 활성화된다.
class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key, this.initialRating = 0});

  final double initialRating;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late double rating = widget.initialRating;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              '영화는 어떠셨나요?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              rating == 0 ? '별을 눌러 평점을 남겨주세요' : '${rating.toStringAsFixed(1)}점',
              style: const TextStyle(fontSize: 14, color: AppColors.body),
            ),
            const SizedBox(height: 24),
            MovieRatingInput(
              rating: rating,
              onChanged: (double value) {
                setState(() {
                  rating = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    // 별점을 아직 고르지 않았다면 저장 버튼을 비활성화한다.
                    onPressed: rating == 0
                        ? null
                        : () => Navigator.pop(context, rating),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
