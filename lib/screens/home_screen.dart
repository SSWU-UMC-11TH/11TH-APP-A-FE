import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../theme/app_text_styles.dart';
import '../widgets/hero_movie_card.dart';
import '../widgets/popular_movie_card.dart';
import '../widgets/search_header.dart';
import '../widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final heroMovie = movies.first;
    // 인기 영화는 별점이 높은 순서로 보여준다. 별점이 같으면 ID 순서로 정렬한다.
    final popularMovies = [...movies]
      ..sort((a, b) {
        final byRating = b.rating.compareTo(a.rating);
        return byRating != 0 ? byRating : a.id.compareTo(b.id);
      });

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
                SizedBox(
                  height: 264,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: popularMovies.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final movie = popularMovies[index];
                      return PopularMovieCard(
                        movie: movie,
                        rank: index + 1,
                        onTap: () => context.push('/movies/${movie.id}'),
                      );
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
