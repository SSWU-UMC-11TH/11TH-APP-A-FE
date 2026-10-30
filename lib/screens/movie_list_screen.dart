import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/movie_list_view_model.dart';
import '../widgets/genre_filter_chips.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';
import '../widgets/search_header.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

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
            Consumer<MovieListViewModel>(
              builder: (context, viewModel, child) {
                return GenreFilterChips(
                  genres: viewModel.genres,
                  selectedGenreId: viewModel.selectedGenreId,
                  // Discover 요청 중에는 장르를 바꾸지 못하게 막는다.
                  enabled: !viewModel.isLoading,
                  onSelected: (genreId) =>
                      context.read<MovieListViewModel>().selectGenre(genreId),
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<MovieListViewModel>(
                builder: (context, viewModel, child) {
                  return switch (viewModel.status) {
                    MovieListLoadStatus.idle ||
                    MovieListLoadStatus.loading => const MovieListLoading(),
                    MovieListLoadStatus.error => MovieListError(
                      message: viewModel.message,
                      onRetry: () => context.read<MovieListViewModel>().retry(),
                    ),
                    MovieListLoadStatus.empty => const MovieListEmpty(),
                    MovieListLoadStatus.success => MovieGrid(
                      movies: viewModel.movies,
                      genreNameById: viewModel.genreNameById,
                    ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
