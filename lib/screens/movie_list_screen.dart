import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../services/fake_movie_service.dart';
import '../services/genre_preference.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_list_states.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  // Empty·Error 상태 확인 시 이 값만 바꿔서 실행합니다.
  static const _loadMode = MovieLoadMode.success;

  final _movieService = const FakeMovieService();
  final _genrePreference = GenrePreference();

  late Future<List<Movie>> _moviesFuture;
  String? selectedGenre;

  @override
  void initState() {
    super.initState();
    _moviesFuture = _movieService.fetchMovies(mode: _loadMode);
    _restoreSelectedGenre();
  }

  Future<void> _restoreSelectedGenre() async {
    final savedGenre = await _genrePreference.read();

    if (!mounted) return;

    setState(() {
      selectedGenre = savedGenre == GenrePreference.allGenre
          ? null
          : savedGenre;
    });
  }

  Future<void> _onGenreSelected(String? genre) async {
    setState(() {
      selectedGenre = genre;
    });
    await _genrePreference.save(genre ?? GenrePreference.allGenre);
  }

  void _retry() {
    setState(() {
      _moviesFuture = _movieService.fetchMovies(mode: _loadMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          '영화',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.violet),
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: Column(
        children: [
          GenreChipBar(
            genres: movieGenres,
            selectedGenre: selectedGenre,
            onSelected: _onGenreSelected,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: _moviesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const MovieListLoading();
                }

                if (snapshot.hasError) {
                  return MovieListError(onRetry: _retry);
                }

                final loadedMovies = snapshot.data ?? const <Movie>[];
                final filteredMovies = selectedGenre == null
                    ? loadedMovies
                    : loadedMovies
                          .where(
                            (movie) => movie.genres.contains(selectedGenre),
                          )
                          .toList();

                if (filteredMovies.isEmpty) {
                  return const MovieListEmpty();
                }

                return MovieGrid(movieList: filteredMovies);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GenreChipBar extends StatelessWidget {
  const GenreChipBar({
    super.key,
    required this.genres,
    required this.selectedGenre,
    required this.onSelected,
  });

  final List<String> genres;
  final String? selectedGenre;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final labels = <String?>[null, ...genres];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = labels[index];
          final isSelected = genre == selectedGenre;

          return ChoiceChip(
            label: Text(genre ?? '전체'),
            selected: isSelected,
            onSelected: (_) => onSelected(genre),
            showCheckmark: false,
            selectedColor: AppColors.violet,
            backgroundColor: AppColors.inputFill,
            labelStyle: AppTextStyles.bodySmall.copyWith(
              color: isSelected ? AppColors.onPrimary : AppColors.black,
              fontWeight: FontWeight.w700,
            ),
            side: BorderSide.none,
            shape: const StadiumBorder(),
          );
        },
      ),
    );
  }
}

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movieList});

  final List<Movie> movieList;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: movieList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.52,
      ),
      itemBuilder: (context, index) {
        return MovieCard(movie: movieList[index]);
      },
    );
  }
}
