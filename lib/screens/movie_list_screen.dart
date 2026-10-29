import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../services/fake_movie_service.dart';
import '../services/genre_preference.dart';
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
  static const _allGenre = GenrePreference.defaultGenre;

  // 장르 Chip은 Mock 데이터에 있는 장르로 만든다.
  static final _genres = [
    _allGenre,
    ...{for (final movie in movies) movie.genre},
  ];

  final _movieService = const FakeMovieService();
  final _genrePreference = GenrePreference();

  // TODO: Empty, Error 화면을 확인할 때 MovieLoadMode.empty / failure로 바꿔서 실행
  static const _loadMode = MovieLoadMode.success;

  // Future는 build가 아니라 initState에서 한 번만 만든다.
  late Future<List<Movie>> _moviesFuture;

  String _selectedGenre = _allGenre;

  // 복원이 끝나기 전에 사용자가 장르를 고르면 복원값으로 덮어쓰지 않는다.
  bool _hasUserSelectedGenre = false;

  @override
  void initState() {
    super.initState();
    _moviesFuture = _movieService.fetchMovies(mode: _loadMode);
    _restoreSelectedGenre();
  }

  Future<void> _restoreSelectedGenre() async {
    final savedGenre = await _genrePreference.read();

    // await 사이에 화면이 사라졌다면 setState를 호출하지 않는다.
    if (!mounted || _hasUserSelectedGenre) return;

    // 저장된 장르가 현재 장르 목록에 없으면 전체로 둔다.
    if (!_genres.contains(savedGenre)) return;

    setState(() => _selectedGenre = savedGenre);
  }

  Future<void> _selectGenre(String genre) async {
    _hasUserSelectedGenre = true;
    setState(() => _selectedGenre = genre);
    await _genrePreference.save(genre);
  }

  // 재시도할 때만 새로운 Future를 만든다.
  // Mock에서는 재시도가 성공하도록 success 모드로 다시 요청한다.
  void _retry() {
    setState(() {
      _moviesFuture = _movieService.fetchMovies();
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
              onSelected: _selectGenre,
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
