import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../widgets/movie_share_sheet.dart';
import '../widgets/movie_summary.dart';
import '../widgets/rating_dialog.dart';

/// 영화 상세 화면.
///
/// Path Parameter로 받은 ID로 Mock Movie를 찾아 보여준다.
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final String? movieId;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  /// 이 화면에서만 유지하는 즐겨찾기 상태 (Mock).
  bool _isFavorite = false;

  /// 이 화면에서만 유지하는 내 평점 (Mock).
  double? _myRating;

  Future<void> _openRatingDialog(Movie movie) async {
    final double? rating = await showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return RatingDialog(initialRating: _myRating ?? 0);
      },
    );

    if (rating == null || !mounted) return;

    setState(() {
      _myRating = rating;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${rating.toStringAsFixed(1)}점으로 평점을 남겼어요.')),
    );
  }

  void _toggleFavorite(Movie movie) {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite
              ? '${movie.title}을(를) 즐겨찾기에 추가했어요.'
              : '${movie.title}을(를) 즐겨찾기에서 삭제했어요.',
        ),
      ),
    );
  }

  Future<void> _openShareSheet(Movie movie) async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return MovieShareSheet(movieTitle: movie.title);
      },
    );

    if (selected == null || !mounted) return;

    // BottomSheet가 닫힌 뒤에 Snackbar를 띄워야 가려지지 않는다.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$selected을(를) 실행했어요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Path Parameter는 String이므로 int로 바꿔 Mock Data에서 찾는다.
    final Movie? movie = findMovieById(int.tryParse(widget.movieId ?? ''));

    if (movie == null) {
      return const _MovieNotFound();
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        centerTitle: true,
        leading: IconButton(
          // 상세 화면을 닫고 이전 화면으로 돌아간다.
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Cinema Archive',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => _openShareSheet(movie),
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.asset(movie.posterAsset, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                MovieSummary(movie: movie, myRating: _myRating),
                const SizedBox(height: 28),
                Text('시놉시스', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(
                  movie.synopsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _MovieDetailActionBar(
        isFavorite: _isFavorite,
        onFavoriteTap: () => _toggleFavorite(movie),
        onRatingTap: () => _openRatingDialog(movie),
      ),
    );
  }
}

/// 상세 화면 하단에 고정되는 즐겨찾기, 평점 남기기 버튼.
class _MovieDetailActionBar extends StatelessWidget {
  const _MovieDetailActionBar({
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onRatingTap,
  });

  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onRatingTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onFavoriteTap,
                icon: Icon(
                  isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  size: 20,
                ),
                label: Text(isFavorite ? '즐겨찾기 완료' : '즐겨찾기'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onRatingTap,
                icon: const Icon(Icons.rate_review_outlined, size: 20),
                label: const Text('평점 남기기'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// URL로 직접 접근했는데 해당 ID의 영화가 없을 때 보여주는 화면.
class _MovieNotFound extends StatelessWidget {
  const _MovieNotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/movies'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48, color: AppColors.label),
            const SizedBox(height: 12),
            Text(
              '찾을 수 없는 영화예요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => context.go('/movies'),
                child: const Text('영화 목록으로'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
