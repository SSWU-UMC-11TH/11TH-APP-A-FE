import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final String movieId;

  @override
  Widget build(BuildContext context) {
    final movie = findMovieById(int.tryParse(movieId));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Cinema Archive',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.violet),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: movie == null
          ? const Center(child: Text('영화를 찾을 수 없습니다.'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Image.asset(movie.posterAsset, fit: BoxFit.cover),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MovieDetailInfo(movie: movie),
                        const SizedBox(height: 16),
                        MovieTagList(tags: movie.tags),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: MovieSynopsis(synopsis: movie.synopsis),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: movie == null ? null : const MovieDetailBottomBar(),
    );
  }
}

class MovieDetailInfo extends StatelessWidget {
  const MovieDetailInfo({super.key, required this.movie});

  final Movie movie;

  String _formatCount(int count) {
    return count.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(movie.title, style: AppTextStyles.titleLarge),
        const SizedBox(height: 4),
        Text(
          '${movie.year} • ${movie.genreLabel} • ${movie.runtimeMinutes}분',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            RatingBarIndicator(
              rating: movie.rating,
              itemCount: 5,
              itemSize: 22,
              itemBuilder: (context, index) {
                return const Icon(Icons.star, color: AppColors.violet);
              },
            ),
            const SizedBox(width: 8),
            Text(
              '${movie.rating} (${_formatCount(movie.reviewCount)})',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}

class MovieTagList extends StatelessWidget {
  const MovieTagList({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return Chip(
          label: Text(tag, style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.inputFill,
          side: BorderSide.none,
          shape: const StadiumBorder(),
        );
      }).toList(),
    );
  }
}

class MovieSynopsis extends StatelessWidget {
  const MovieSynopsis({super.key, required this.synopsis});

  final String synopsis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('시놉시스', style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        Text(synopsis, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
      ],
    );
  }
}

class MovieDetailBottomBar extends StatelessWidget {
  const MovieDetailBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.bookmark_border),
                label: const Text('즐겨찾기'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.violet,
                  side: const BorderSide(color: AppColors.violet),
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('평점 남기기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violet,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
