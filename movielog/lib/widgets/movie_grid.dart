import 'package:flutter/material.dart';

import '../data/models/tmdb_movie_dto.dart';
import 'movie_card.dart';

/// 영화 카드를 2열 Grid로 보여주는 Success 상태 화면.
class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<TmdbMovieDto> movies;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      itemCount: movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 20,
        childAspectRatio: 0.58,
      ),
      itemBuilder: (BuildContext context, int index) {
        return MovieCard(movie: movies[index]);
      },
    );
  }
}
