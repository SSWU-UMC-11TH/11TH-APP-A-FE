import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_dto.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/delete_rating_dialog.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/movielog_button.dart';
import '../widgets/rating_card.dart';
import '../widgets/rating_dialog.dart';

/// 마이페이지의 자식 화면 "내가 등록한 평점" (W6-02, W7-01).
///
/// 직접 API를 부르지 않고 [MyRatingsViewModel]의 상태를 그대로 그린다.
/// root Navigator 위에 열리므로 하단 NavigationBar가 없다.
/// 조회 대상은 회원가입 결과를 보관한 학습용 회원(LearningMemberSession)이다.
///
/// 7주차부터 카드별 수정·삭제를, Challenge로 상단 "편집"의 다중 선택 삭제를 지원한다.
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MyRatingsViewModel viewModel = context.watch<MyRatingsViewModel>();
    final bool isSelecting = viewModel.isSelecting;
    final int selectedCount = viewModel.selectedRatingIds.length;
    final bool canEdit =
        viewModel.status == MyRatingsLoadStatus.success &&
        viewModel.ratings.isNotEmpty;

    // 다중 삭제 중에는 뒤로가기·스와이프 백을 막고, 오버레이가 화면 전체를 덮는다.
    return PopScope(
      canPop: !viewModel.isDeletingSelected,
      child: LoadingOverlay(
        isLoading: viewModel.isDeletingSelected,
        child: Scaffold(
          appBar: isSelecting
              ? AppBar(
                  automaticallyImplyLeading: false,
                  centerTitle: false,
                  title: Text(
                    '$selectedCount개 선택',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: viewModel.isDeletingSelected
                          ? null
                          : viewModel.cancelSelecting,
                      child: const Text('취소'),
                    ),
                    const SizedBox(width: 8),
                  ],
                )
              : CommonAppBar(
                  title: '내가 등록한 평점',
                  centerTitle: true,
                  // 마이페이지에서 push로 열렸으면 pop, URL로 직접 들어왔으면 마이페이지로 이동한다.
                  onBack: () =>
                      context.canPop() ? context.pop() : context.go('/my'),
                  actions: <Widget>[
                    if (canEdit)
                      TextButton(
                        onPressed: viewModel.startSelecting,
                        child: const Text('편집'),
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
          body: SafeArea(
            child: switch (viewModel.status) {
              MyRatingsLoadStatus.idle ||
              MyRatingsLoadStatus.loading => const _MyRatingsLoading(),
              MyRatingsLoadStatus.error => _MyRatingsError(
                // 저장은 됐지만 재조회만 실패했으면 그 사실을 먼저 알린다.
                message: viewModel.refreshWarning ?? viewModel.message,
                retryLabel: viewModel.refreshWarning != null
                    ? '조회 다시 시도'
                    : '다시 시도',
                onRetry: viewModel.load,
              ),
              MyRatingsLoadStatus.empty => const _MyRatingsEmpty(),
              MyRatingsLoadStatus.success => _MyRatingsList(
                viewModel: viewModel,
              ),
            },
          ),
          bottomNavigationBar: isSelecting
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    // 선택이 1개 이상일 때만 활성화한다.
                    child: MovieLogButton(
                      label: '선택한 $selectedCount개 삭제',
                      width: double.infinity,
                      onPressed:
                          selectedCount > 0 && !viewModel.isDeletingSelected
                          ? () => onDeleteSelectedPressed(context)
                          : null,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// 수정 버튼: 기존 별점·코멘트를 채운 RatingDialog를 다시 연다.
///
/// Dialog 안에서 값을 바꾸는 동안 실제 [rating] 객체는 건드리지 않으므로
/// 취소하거나 실패해도 따로 복구할 상태가 없다.
Future<void> onEditPressed(BuildContext context, RatingDto rating) async {
  final MyRatingsViewModel viewModel = context.read<MyRatingsViewModel>();
  final bool? saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막는다.
    builder: (_) => RatingDialog(
      title: '평점을 수정해 주세요',
      initialScore: rating.score,
      initialComment: rating.comment, // null이면 TextField가 빈 칸으로 시작한다.
      onSubmit: (int score, String? comment) => viewModel.updateRating(
        ratingId: rating.ratingId,
        score: score,
        comment: comment,
      ),
    ),
  );

  if (!context.mounted || saved != true) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('평점을 수정했습니다.')));
}

/// 삭제 버튼: 확인 Dialog를 열고, 삭제가 끝날 때까지 Dialog를 유지한다.
Future<void> onDeletePressed(BuildContext context, RatingDto rating) async {
  final MyRatingsViewModel viewModel = context.read<MyRatingsViewModel>();
  final bool? deleted = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 삭제 중 바깥 탭으로 닫히는 것도 막는다.
    builder: (_) => DeleteRatingDialog(
      onConfirm: () => viewModel.deleteRating(rating.ratingId),
    ),
  );

  // deleted는 실제로 삭제까지 마쳤을 때만 true다.
  if (!context.mounted || deleted != true) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('평점을 삭제했습니다.')));
}

/// 선택 삭제 (Challenge): 확인 Dialog는 삭제 여부만 묻고 요청 전에 바로 닫힌다.
///
/// 삭제 중 로딩은 Dialog가 아니라 화면 위 [LoadingOverlay]가 보여준다.
Future<void> onDeleteSelectedPressed(BuildContext context) async {
  final MyRatingsViewModel viewModel = context.read<MyRatingsViewModel>();
  final int count = viewModel.selectedRatingIds.length;
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => ConfirmDeleteDialogFrame(
      title: '선택한 $count개 평점을 삭제할까요?',
      onCancel: () => Navigator.pop(dialogContext, false),
      confirmButton: MovieLogButton(
        label: '삭제',
        width: double.infinity,
        onPressed: () => Navigator.pop(dialogContext, true),
      ),
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final int failed = await viewModel.deleteSelectedRatings();
  if (!context.mounted) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        failed > 0
            ? '$failed개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.'
            : '선택한 $count개 평점을 삭제했습니다.',
      ),
    ),
  );
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
                '학습용 회원(memberId ${viewModel.memberId})의 평점입니다.',
                style: AppTextStyles.bodySmall,
              ),
              if (notice != null) ...<Widget>[
                const SizedBox(height: 8),
                _NoticeBanner(message: notice),
              ],
            ],
          );
        }
        final entry = viewModel.ratings[index - 1];
        final int ratingId = entry.rating.ratingId;
        if (viewModel.isSelecting) {
          return RatingCard(
            entry: entry,
            selected: viewModel.selectedRatingIds.contains(ratingId),
            onSelectedChanged: () => viewModel.toggleSelected(ratingId),
          );
        }
        // 이 목록은 memberId path로 조회한 본인 평점만 담으므로 모두 수정·삭제할 수 있다.
        // 다른 회원의 평점을 함께 보여주게 되면 그 카드에는 콜백을 넘기지 않는다.
        return RatingCard(
          entry: entry,
          onEdit: () => onEditPressed(context, entry.rating),
          onDelete: () => onDeletePressed(context, entry.rating),
        );
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
  const _MyRatingsError({
    this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String? message;
  final String retryLabel;
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
            MovieLogButton(label: retryLabel, width: 140, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

/// 학습용 회원가입 전에 /my/ratings로 들어왔을 때 보여주는 화면.
///
/// 6주차처럼 memberId 1을 대신 쓰면 다른 회원의 path로 요청하게 되므로 막는다.
class MyRatingsSignUpRequired extends StatelessWidget {
  const MyRatingsSignUpRequired({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '내가 등록한 평점',
        centerTitle: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/my'),
      ),
      body: const _SignUpRequiredBody(),
    );
  }
}

class _SignUpRequiredBody extends StatelessWidget {
  const _SignUpRequiredBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.person_outline, size: 48, color: AppColors.label),
            const SizedBox(height: 12),
            const Text('학습용 회원가입이 필요합니다.', style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            const Text(
              '가입한 회원의 memberId로 평점을 조회합니다.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 20),
            MovieLogButton(
              label: '회원가입',
              width: 140,
              onPressed: () => context.go('/register'),
            ),
          ],
        ),
      ),
    );
  }
}
