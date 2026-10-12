import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/movie_home_view_model.dart';
import '../widgets/home_hero_card.dart';
import '../widgets/movie_horizontal_list.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';
import '../widgets/section_header.dart';

/// 홈 화면. TMDB Popular 앞 5개 중 1위를 크게, 5개 전체를 가로 목록으로 보여준다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: <Widget>[
          const Text(
            'MovieLog',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '오늘은 어떤\n영화를 볼까요?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          // 인기 영화 영역만 ViewModel 상태에 따라 다시 그린다.
          Consumer<MovieHomeViewModel>(
            builder: (context, viewModel, child) {
              return switch (viewModel.status) {
                MovieHomeLoadStatus.idle || MovieHomeLoadStatus.loading =>
                  const _HomeStateBox(child: MovieListLoading()),
                MovieHomeLoadStatus.error => _HomeStateBox(
                  child: MovieListError(
                    message: viewModel.message,
                    onRetry: () =>
                        context.read<MovieHomeViewModel>().loadPopular(),
                  ),
                ),
                MovieHomeLoadStatus.empty => const _HomeStateBox(
                  child: MovieListEmpty(),
                ),
                MovieHomeLoadStatus.success => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    HomeHeroCard(movie: viewModel.popularMovies.first),
                    const SizedBox(height: 28),
                    SectionHeader(
                      title: '인기 영화',
                      actionLabel: '전체보기',
                      onActionTap: () => context.go('/movies'),
                    ),
                    const SizedBox(height: 14),
                    MovieHorizontalList(movies: viewModel.popularMovies),
                  ],
                ),
              };
            },
          ),
        ],
      ),
    );
  }
}

/// Loading·Error·Empty 상태를 인기 영화 영역 높이 안에서 가운데에 보여준다.
class _HomeStateBox extends StatelessWidget {
  const _HomeStateBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 360, child: child);
  }
}
