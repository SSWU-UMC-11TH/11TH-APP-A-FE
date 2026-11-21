import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../theme/app_colors.dart';
import '../view_models/movie_detail_view_model.dart';
import '../widgets/movie_share_sheet.dart';
import '../widgets/movie_summary.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

/// 영화 상세 화면.
///
/// 보여줄 영화와 평점 등록 상태는 [MovieDetailViewModel]이 갖는다.
/// 영화는 [MovieDetailLoader]가 extra 또는 TMDB 재조회로 준비해 둔다.
///
/// 8주차부터 평점 Dialog의 별점·코멘트를 MovieLog v7 POST(토큰 기반)로 저장한다.
/// 이 화면은 등록만 하고, 수정·삭제는 마이페이지 "내가 등록한 평점"에서 한다.
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  /// 이 화면에서만 유지하는 즐겨찾기 상태 (Mock).
  bool _isFavorite = false;

  Future<void> _openRatingDialog() async {
    final MovieDetailViewModel viewModel = context.read<MovieDetailViewModel>();
    final bool? saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막는다.
      builder: (_) => RatingDialog(
        // movieId는 ViewModel이 가진 TMDB 영화 id이므로 콜백 밖으로 따로 넘기지 않는다.
        onSubmit: (int score, String? comment) async {
          await viewModel.createRating(score: score, comment: comment);
          if (viewModel.submitStatus != SubmitStatus.success) {
            // Dialog가 닫히지 않고 서버 message(400/404/409)를 보여주도록 실패로 던진다.
            throw RatingWriteException(
              viewModel.submitMessage ?? '저장에 실패했습니다.',
              code: viewModel.submitCode,
            );
          }
        },
      ),
    );

    // 저장 요청과 Snackbar 표시는 다른 비동기 경계이므로 mounted를 다시 확인한다.
    if (!mounted) return;
    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.'),
        ),
      );
      return;
    }
    // 저장에 실패한 뒤 취소로 닫았다면 실패 이유를 한 번 더 알린다.
    if (viewModel.submitStatus == SubmitStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '평점을 등록하지 못했습니다. ${viewModel.submitMessage ?? ''}'.trim(),
          ),
        ),
      );
    }
  }

  void _toggleFavorite(TmdbMovieDto movie) {
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

  Future<void> _openShareSheet(TmdbMovieDto movie) async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return MovieShareSheet(movieTitle: movie.title);
      },
    );

    if (selected == null || !mounted) return;

    // BottomSheet가 닫힌 뒤에 Snackbar를 띄워야 가려지지 않는다.
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$selected을(를) 실행했어요.')));
  }

  @override
  Widget build(BuildContext context) {
    final MovieDetailViewModel viewModel = context
        .watch<MovieDetailViewModel>();
    final TmdbMovieDto movie = viewModel.movie;
    final int? myScore = viewModel.myScore;

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
            // 가로 이미지(backdrop)가 없으면 포스터를, 둘 다 없으면 placeholder를 보여준다.
            child: TmdbPosterImage(
              posterPath: movie.backdropPath ?? movie.posterPath,
              size: 'w780',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                MovieSummary(movie: movie, myRating: myScore?.toDouble()),
                const SizedBox(height: 28),
                Text('시놉시스', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (movie.overview.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        '줄거리 정보가 없어요.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  Text(
                    movie.overview,
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
        // 보호 Route라 이 화면에 왔다면 이미 로그인 상태다.
        onRatingTap: _openRatingDialog,
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
