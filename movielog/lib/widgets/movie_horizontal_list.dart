import 'package:flutter/material.dart';

import '../models/movie.dart';
import 'movie_card.dart';

/// 홈에서 영화를 가로로 나열하는 목록.
class MovieHorizontalList extends StatelessWidget {
  const MovieHorizontalList({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 254,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: movies.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 14),
        itemBuilder: (BuildContext context, int index) {
          final Movie movie = movies[index];
          return SizedBox(
            width: 134,
            child: MovieCard(movie: movie),
          );
        },
      ),
    );
  }
}
