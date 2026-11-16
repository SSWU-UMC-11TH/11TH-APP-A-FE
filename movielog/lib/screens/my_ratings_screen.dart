import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';
import '../widgets/rating_card.dart';

/// 마이페이지의 자식 화면 "내가 등록한 평점" (W6-02).
///
/// 직접 API를 부르지 않고 [MyRatingsViewModel]의 상태를 그대로 그린다.
/// root Navigator 위에 열리므로 하단 NavigationBar가 없다.
/// 조회 대상은 로그인한 본인이 아니라 학습용 memberId 1이다.
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '내가 등록한 평점',
        centerTitle: true,
        // 마이페이지에서 push로 열렸으면 pop, URL로 직접 들어왔으면 마이페이지로 이동한다.
        onBack: () => context.canPop() ? context.pop() : context.go('/my'),
      ),
      body: SafeArea(
        child: Consumer<MyRatingsViewModel>(
          builder: (context, viewModel, child) {
            return switch (viewModel.status) {
              MyRatingsLoadStatus.idle ||
              MyRatingsLoadStatus.loading => const _MyRatingsLoading(),
              MyRatingsLoadStatus.error => _MyRatingsError(
                message: viewModel.message,
                onRetry: () => context.read<MyRatingsViewModel>().load(),
              ),
              MyRatingsLoadStatus.empty => const _MyRatingsEmpty(),
              MyRatingsLoadStatus.success => _MyRatingsList(
                viewModel: viewModel,
              ),
            };
          },
        ),
      ),
    );
  }
}

class _MyRatingsList extends StatelessWidget {
  const _MyRatingsList({required this.viewModel});

  final MyRatingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final String? notice = viewModel.message;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      // 0번은 안내 영역, 1번부터 평점 카드다.
      itemCount: viewModel.ratings.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '학습용 회원(memberId ${viewModel.memberId})의 공개 평점입니다.',
                style: AppTextStyles.bodySmall,
              ),
              if (notice != null) ...<Widget>[
                const SizedBox(height: 8),
                _NoticeBanner(message: notice),
              ],
            ],
          );
        }
        return RatingCard(entry: viewModel.ratings[index - 1]);
      },
    );
  }
}

/// 일부 영화 정보를 가져오지 못했을 때 목록 위에 보여주는 안내.
class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.title),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyRatingsLoading extends StatelessWidget {
  const _MyRatingsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('평점을 불러오는 중이에요', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _MyRatingsEmpty extends StatelessWidget {
  const _MyRatingsEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.star_outline, size: 48, color: AppColors.label),
          SizedBox(height: 12),
          Text('아직 등록한 평점이 없어요', style: AppTextStyles.titleMedium),
          SizedBox(height: 4),
          Text('영화 상세에서 평점을 남겨 보세요', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _MyRatingsError extends StatelessWidget {
  const _MyRatingsError({this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message ?? '평점을 불러오지 못했습니다.',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 20),
            // 아이콘처럼 정해진 크기가 필요한 자리라 고정 너비를 쓴다.
            MovieLogButton(label: '다시 시도', width: 120, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
