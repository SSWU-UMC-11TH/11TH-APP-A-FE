import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/share_sheet.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final String movieId;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;
  double? myRating;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
    _showSnackBar(isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.');
  }

  Future<void> _openRatingDialog(Movie movie) async {
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) =>
          RatingDialog(movieTitle: movie.title, initialRating: myRating ?? 0),
    );

    if (!mounted || result == null) return;

    setState(() {
      myRating = result;
    });
    _showSnackBar('${result.toStringAsFixed(1)}점을 남겼습니다.');
  }

  Future<void> _openShareSheet(Movie movie) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => ShareSheet(movieTitle: movie.title),
    );

    if (!mounted || message == null) return;

    _showSnackBar(message);
  }

  @override
  Widget build(BuildContext context) {
    final movie = findMovieById(int.tryParse(widget.movieId));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Cinema Archive',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.violet),
        ),
        actions: [
          if (movie != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _openShareSheet(movie),
            ),
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
      bottomNavigationBar: movie == null
          ? null
          : MovieDetailBottomBar(
              isFavorite: isFavorite,
              myRating: myRating,
              onFavoriteTap: _toggleFavorite,
              onRatingTap: () => _openRatingDialog(movie),
            ),
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
  const MovieDetailBottomBar({
    super.key,
    required this.isFavorite,
    required this.myRating,
    required this.onFavoriteTap,
    required this.onRatingTap,
  });

  final bool isFavorite;
  final double? myRating;
  final VoidCallback onFavoriteTap;
  final VoidCallback onRatingTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onFavoriteTap,
                icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
                label: Text(isFavorite ? '즐겨찾기 해제' : '즐겨찾기'),
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
                onPressed: onRatingTap,
                icon: Icon(
                  myRating == null ? Icons.rate_review_outlined : Icons.star,
                ),
                label: Text(
                  myRating == null
                      ? '평점 남기기'
                      : '내 평점 ${myRating!.toStringAsFixed(1)}',
                ),
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
