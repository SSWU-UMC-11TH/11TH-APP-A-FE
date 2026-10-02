import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';

/// 포스터, 평점 Badge, 제목을 함께 보여주는 영화 카드.
///
/// Tap하면 Path Parameter로 영화 ID를 전달하며 상세 Route로 이동한다.
class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // 목록 화면을 유지한 채 상세 화면을 쌓아야 하므로 push를 사용한다.
      onTap: () => context.push('/movies/${movie.id}'),
      child: MovieCardContent(movie: movie),
    );
  }
}

/// 영화 카드의 표시 영역. 부모가 정해준 크기를 채운다.
class MovieCardContent extends StatelessWidget {
  const MovieCardContent({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(movie.posterAsset, fit: BoxFit.cover),
                Positioned(
                  top: 8,
                  right: 8,
                  child: MovieRatingBadge(rating: movie.rating),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          movie.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          movie.listLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// 포스터 위에 올리는 평점 Badge.
class MovieRatingBadge extends StatelessWidget {
  const MovieRatingBadge({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.badge,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.star, size: 13, color: AppColors.star),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
