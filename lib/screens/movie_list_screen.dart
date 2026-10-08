import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../widgets/genre_filter_chips.dart';
import '../widgets/movie_card.dart';
import '../widgets/search_header.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const _allGenre = '전체';

  // 장르 Chip은 Mock 데이터에 있는 장르로 만든다.
  static final _genres = [
    _allGenre,
    ...{for (final movie in movies) movie.genre},
  ];

  String _selectedGenre = _allGenre;

  @override
  Widget build(BuildContext context) {
    final filteredMovies = _selectedGenre == _allGenre
        ? movies
        : movies.where((movie) => movie.genre == _selectedGenre).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SearchHeader(title: '영화'),
            ),
            const SizedBox(height: 8),
            GenreFilterChips(
              genres: _genres,
              selectedGenre: _selectedGenre,
              onSelected: (genre) => setState(() => _selectedGenre = genre),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const horizontalPadding = 16.0;
                  const crossAxisSpacing = 12.0;
                  // 포스터(3:4)와 글자 영역의 높이를 더해 카드 높이를 정한다.
                  final cardWidth =
                      (constraints.maxWidth -
                          horizontalPadding * 2 -
                          crossAxisSpacing) /
                      2;

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      16,
                    ),
                    itemCount: filteredMovies.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: crossAxisSpacing,
                      mainAxisSpacing: 16,
                      mainAxisExtent: cardWidth * 4 / 3 + 68,
                    ),
                    itemBuilder: (context, index) {
                      final movie = filteredMovies[index];
                      return MovieCard(
                        movie: movie,
                        onTap: () => context.push('/movies/${movie.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
