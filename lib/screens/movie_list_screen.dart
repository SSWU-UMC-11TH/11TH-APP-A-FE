import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../theme/app_text_styles.dart';

// TODO: 영화 목록 화면 구현 시 MovieCard로 교체하는 임시 화면
class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: movies.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.65,
          ),
          itemBuilder: (context, index) {
            final movie = movies[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      movie.posterAsset,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(movie.title, style: AppTextStyles.bodyLarge),
                Text(
                  '${movie.year} · ${movie.genre}',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
