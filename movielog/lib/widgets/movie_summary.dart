import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../models/movie.dart';
import '../theme/app_theme.dart';

/// 상세 화면에서 제목, 평균 평점, 태그를 보여주는 요약 영역.
class MovieSummary extends StatelessWidget {
  const MovieSummary({super.key, required this.movie, required this.myRating});

  final Movie movie;

  /// 사용자가 이번 화면에서 남긴 평점. 아직 남기지 않았다면 null.
  final double? myRating;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(movie.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(movie.subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            // 평균 평점은 수정할 수 없으므로 읽기 전용 Indicator로 표시한다.
            RatingBarIndicator(
              rating: movie.rating,
              itemCount: 5,
              itemSize: 18,
              itemBuilder: (BuildContext context, int index) {
                return const Icon(Icons.star, color: AppColors.star);
              },
            ),
            const SizedBox(width: 8),
            Text(
              movie.rating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.title,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${movie.ratingCount})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        if (myRating != null) ...<Widget>[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '내 평점 ${myRating!.toStringAsFixed(1)}점',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String tag in movie.tags) MovieTagChip(label: tag),
          ],
        ),
      ],
    );
  }
}

/// 상세 화면에서 영화의 분위기를 설명하는 태그 Chip.
class MovieTagChip extends StatelessWidget {
  const MovieTagChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EEF6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.body),
      ),
    );
  }
}
