import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../theme/app_theme.dart';
import '../widgets/home_hero_card.dart';
import '../widgets/movie_horizontal_list.dart';
import '../widgets/section_header.dart';

/// 홈 화면. 추천 신작 한 편과 인기 영화 목록을 보여준다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 홈과 목록, 상세가 같은 Mock Data를 사용한다.
    final Movie heroMovie = movies.first;
    final List<Movie> popularMovies = movies.skip(1).toList();

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
          HomeHeroCard(movie: heroMovie),
          const SizedBox(height: 28),
          SectionHeader(
            title: '인기 영화',
            actionLabel: '전체보기',
            onActionTap: () => context.go('/movies'),
          ),
          const SizedBox(height: 14),
          MovieHorizontalList(movies: popularMovies),
        ],
      ),
    );
  }
}
