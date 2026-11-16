import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/movie_list_view_model.dart';
import '../widgets/genre_chip_list.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';

/// 영화 목록 화면.
///
/// 직접 API를 부르지 않고 [MovieListViewModel]의 상태를 그대로 그린다.
/// 장르 Chip을 누르면 ViewModel에 선택만 전달하고, 재조회는 ViewModel이 한다.
class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  '영화',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('검색은 다음 주차에 연결할 예정이에요.')),
                    );
                  },
                  icon: const Icon(Icons.search, color: AppColors.title),
                ),
              ],
            ),
          ),
          Consumer<MovieListViewModel>(
            builder: (context, viewModel, child) {
              return GenreChipList(
                genres: viewModel.genres,
                selectedGenreId: viewModel.selectedGenreId,
                // Discover 요청 중에는 장르를 바꾸지 못하게 Chip을 잠근다.
                enabled: !viewModel.isLoading,
                onGenreSelected: (int? genreId) =>
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
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}
