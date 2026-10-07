import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common_app_bar.dart';

// TODO: 영화 상세 화면 구현 전까지 Route의 영화 ID로 기본 정보만 보여주는 임시 화면
class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final String? movieId;

  @override
  Widget build(BuildContext context) {
    final movie = findMovieById(int.tryParse(movieId ?? ''));

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Cinema Archive',
        centerTitle: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      body: movie == null
          ? const Center(child: Text('영화를 찾을 수 없습니다.'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Image.asset(movie.posterAsset, fit: BoxFit.cover),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(movie.title, style: AppTextStyles.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          '${movie.year} · ${movie.genre}',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
