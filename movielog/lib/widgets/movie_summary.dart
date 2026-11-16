import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';

/// 상세 화면에서 제목, 개봉 연도, TMDB 평균 평점을 보여주는 요약 영역.
class MovieSummary extends StatelessWidget {
  const MovieSummary({super.key, required this.movie, required this.myRating});

  final TmdbMovieDto movie;

  /// 사용자가 이번 화면에서 남긴 평점. 아직 남기지 않았다면 null.
  final double? myRating;

  @override
  Widget build(BuildContext context) {
    final String? year = movie.releaseYear;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(movie.title, style: Theme.of(context).textTheme.headlineMedium),
        // 개봉일이 없으면 연도를 표시하지 않는다.
        if (year != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(year, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            // TMDB 평점은 10점 만점이므로 별 5개에 맞춰 절반으로 표시한다.
            RatingBarIndicator(
              rating: movie.voteAverage / 2,
              itemCount: 5,
              itemSize: 18,
              itemBuilder: (BuildContext context, int index) {
                return const Icon(Icons.star, color: AppColors.star);
              },
            ),
            const SizedBox(width: 8),
            Text(
              movie.voteAverage.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.title,
              ),
            ),
            const SizedBox(width: 4),
            Text('/ 10 (TMDB)', style: Theme.of(context).textTheme.bodySmall),
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
      ],
    );
  }
}
