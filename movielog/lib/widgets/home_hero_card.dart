import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import 'tmdb_poster_image.dart';

/// 홈 상단에서 인기 영화 1위를 크게 보여주는 카드.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key, required this.movie});

  final TmdbMovieDto movie;

  /// `2025 · TMDB 평점 7.8` 형태. 개봉일이 없으면 연도를 빼고 보여준다.
  String get _subtitle {
    final String? year = movie.releaseYear;
    final String rating = 'TMDB 평점 ${movie.voteAverage.toStringAsFixed(1)}';
    return year == null ? rating : '$year · $rating';
  }

  void _openDetail(BuildContext context) {
    context.push('/movies/${movie.id}', extra: movie);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openDetail(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              TmdbPosterImage(posterPath: movie.posterPath),
              // 아래쪽 텍스트가 잘 보이도록 어두운 Gradient를 덮는다.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Colors.transparent, Color(0xCC14101C)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '오늘의 인기 1위',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFE6E1EC),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _openDetail(context),
                      icon: const Icon(Icons.info_outline, size: 20),
                      label: const Text('상세보기'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
