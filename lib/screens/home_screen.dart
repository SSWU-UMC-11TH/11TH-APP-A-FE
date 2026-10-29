import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
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
                Consumer<MovieHomeViewModel>(
                  builder: (context, viewModel, child) {
                    return _HeroSection(
                      isLoading:
                          viewModel.status == MovieHomeLoadStatus.idle ||
                          viewModel.status == MovieHomeLoadStatus.loading,
                      movie: viewModel.heroMovie,
                    );
                  },
                ),
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
          onTap: () => context.push('/movies/${movie.id}', extra: movie),
        );
      },
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.isLoading, required this.movie});

  final bool isLoading;
  final TmdbMovieDto? movie;

  @override
  Widget build(BuildContext context) {
    final movie = this.movie;

    // 실패했거나 추천할 영화가 없으면 영역을 숨긴다. 재시도는 인기 영역에서 한다.
    if (!isLoading && movie == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: movie == null
          // 로딩 중에도 카드 크기를 미리 잡아 화면이 밀리지 않게 한다.
          ? AspectRatio(
              aspectRatio: 356 / 504,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            )
          : HeroMovieCard(
              movie: movie,
              onDetailTap: () =>
                  context.push('/movies/${movie.id}', extra: movie),
            ),
    );
  }
}
