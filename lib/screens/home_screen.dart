import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final movie = movies.first;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MovieLog',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.violet,
                ),
              ),
              const SizedBox(height: 24),
              const Text('오늘은 어떤\n영화를 볼까요?', style: AppTextStyles.titleLarge),
              const SizedBox(height: 24),
              SizedBox(width: 160, child: MovieCard(movie: movie)),
            ],
          ),
        ),
      ),
    );
  }
}
