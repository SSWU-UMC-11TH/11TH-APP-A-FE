import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../widgets/movie_card.dart';

// TODO: 홈 화면 구현 전까지 영화 카드 하나만 보여주는 임시 화면
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final movie = movies.first;

    // 홈 화면에서는 뒤로 가기를 막는다.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 172,
                child: MovieCard(
                  movie: movie,
                  onTap: () => context.push('/movies/${movie.id}'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
