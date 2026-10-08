import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../services/fake_movie_service.dart';
import '../widgets/genre_filter_chips.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';
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

  final _movieService = const FakeMovieService();

  // TODO: Empty, Error 화면을 확인할 때 MovieLoadMode.empty / failure로 바꿔서 실행
  static const _loadMode = MovieLoadMode.success;

  // Future는 build가 아니라 initState에서 한 번만 만든다.
  late Future<List<Movie>> _moviesFuture;

  String _selectedGenre = _allGenre;

  @override
  void initState() {
    super.initState();
    _moviesFuture = _movieService.fetchMovies(mode: _loadMode);
  }

  // 재시도할 때만 새로운 Future를 만든다.
  void _retry() {
    setState(() {
      _moviesFuture = _movieService.fetchMovies(mode: _loadMode);
    });
  }

  @override
  Widget build(BuildContext context) {
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
              child: FutureBuilder<List<Movie>>(
                future: _moviesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const MovieListLoading();
                  }

                  // 오류를 빈 목록보다 먼저 확인한다.
                  if (snapshot.hasError) {
                    return MovieListError(onRetry: _retry);
                  }

                  final loadedMovies = snapshot.data ?? const <Movie>[];
                  final filteredMovies = _selectedGenre == _allGenre
                      ? loadedMovies
                      : loadedMovies
                            .where((movie) => movie.genre == _selectedGenre)
                            .toList();

                  if (filteredMovies.isEmpty) {
                    return const MovieListEmpty();
                  }

                  return MovieGrid(movies: filteredMovies);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
