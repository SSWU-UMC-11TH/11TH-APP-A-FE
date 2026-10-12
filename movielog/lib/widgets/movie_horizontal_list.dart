import 'package:flutter/material.dart';

import '../data/models/tmdb_movie_dto.dart';
import 'movie_card.dart';

/// 홈에서 영화를 가로로 나열하는 목록.
class MovieHorizontalList extends StatelessWidget {
  const MovieHorizontalList({super.key, required this.movies});

  final List<TmdbMovieDto> movies;

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
          return SizedBox(width: 134, child: MovieCard(movie: movies[index]));
        },
      ),
    );
  }
}
