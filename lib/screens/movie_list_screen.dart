import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/movie_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  String? selectedGenre;

  @override
  Widget build(BuildContext context) {
    final filteredMovies = selectedGenre == null
        ? movies
        : movies
              .where((movie) => movie.genres.contains(selectedGenre))
              .toList();

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
            onSelected: (genre) {
              setState(() {
                selectedGenre = genre;
              });
            },
          ),
          const SizedBox(height: 12),
          Expanded(child: MovieGrid(movieList: filteredMovies)),
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
    if (movieList.isEmpty) {
      return const Center(child: Text('해당 장르의 영화가 없습니다.'));
    }

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
