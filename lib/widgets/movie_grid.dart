import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import 'movie_card.dart';

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 16.0;
        const crossAxisSpacing = 12.0;
        // 포스터(3:4)와 글자 영역의 높이를 더해 카드 높이를 정한다.
        final cardWidth =
            (constraints.maxWidth - horizontalPadding * 2 - crossAxisSpacing) /
            2;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            16,
          ),
          itemCount: movies.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: 16,
            mainAxisExtent: cardWidth * 4 / 3 + 68,
          ),
          itemBuilder: (context, index) {
            final movie = movies[index];
            return MovieCard(
              movie: movie,
              onTap: () => context.push('/movies/${movie.id}'),
            );
          },
        );
      },
    );
  }
}
