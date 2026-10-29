import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/mock_movies.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_text_styles.dart';
import '../view_models/movie_home_view_model.dart';
import '../widgets/hero_movie_card.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';
import '../widgets/popular_movie_card.dart';
import '../widgets/search_header.dart';
import '../widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final heroMovie = movies.first;

    // 홈 화면에서는 뒤로 가기를 막는다.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SearchHeader(title: 'MovieLog'),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '오늘은 어떤\n영화를 볼까요?',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: HeroMovieCard(
                    movie: heroMovie,
                    onDetailTap: () => context.push('/movies/${heroMovie.id}'),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader(
                    title: '인기 영화',
                    actionLabel: '전체보기',
                    onActionTap: () => context.go('/movies'),
                  ),
                ),
                const SizedBox(height: 12),
                // 인기 영화 영역만 ViewModel 상태에 따라 다시 그린다.
                SizedBox(
                  height: 264,
                  child: Consumer<MovieHomeViewModel>(
                    builder: (context, viewModel, child) {
                      return switch (viewModel.status) {
                        MovieHomeLoadStatus.idle ||
                        MovieHomeLoadStatus.loading => const MovieListLoading(),
                        MovieHomeLoadStatus.error => MovieListError(
                          onRetry: () =>
                              context.read<MovieHomeViewModel>().loadPopular(),
                        ),
                        MovieHomeLoadStatus.empty => const Center(
                          child: Text(
                            '인기 영화가 없습니다.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        MovieHomeLoadStatus.success => _PopularMovieList(
                          movies: viewModel.popularMovies,
                        ),
                      };
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PopularMovieList extends StatelessWidget {
  const _PopularMovieList({required this.movies});

  final List<TmdbMovieDto> movies;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: movies.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final movie = movies[index];
        return PopularMovieCard(
          movie: movie,
          rank: index + 1,
          // 배열 index가 아니라 TMDB id를 넘겨야 이후 평점 movieId로 쓸 수 있다.
          onTap: () => context.push('/movies/${movie.id}'),
        );
      },
    );
  }
}
