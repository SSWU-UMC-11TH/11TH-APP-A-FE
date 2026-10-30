import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/movie_formatters.dart';

class MovieInfoSection extends StatelessWidget {
  const MovieInfoSection({super.key, required this.movie});

  final TmdbMovieDto movie;

  @override
  Widget build(BuildContext context) {
    final year = releaseYear(movie.releaseDate);
    final rating = toFiveStarRating(movie.voteAverage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(movie.title, style: AppTextStyles.titleMedium),
        // release_date가 없으면 연도를 표시하지 않는다.
        if (year != null) ...[
          const SizedBox(height: 4),
          Text(year, style: AppTextStyles.bodyMedium),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            // 평균 평점은 읽기 전용으로 표시한다.
            RatingBarIndicator(
              rating: rating,
              itemCount: 5,
              itemSize: 20,
              unratedColor: AppColors.lavender,
              itemBuilder: (context, index) {
                return const Icon(Icons.star, color: AppColors.violet);
              },
            ),
            const SizedBox(width: 8),
            Text(
              rating.toStringAsFixed(1),
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
