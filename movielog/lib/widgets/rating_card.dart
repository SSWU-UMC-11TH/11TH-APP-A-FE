import 'package:flutter/material.dart';

import '../data/models/rating_with_movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'tmdb_poster_image.dart';

/// 평점 기록 하나를 포스터·제목·점수·후기·등록일과 함께 보여주는 카드 (W6-02).
///
/// TMDB에서 영화를 찾지 못했으면([RatingWithMovie.movie]가 null)
/// 제목은 `영화 #movieId`, 포스터는 placeholder로 대신하고 평점 기록은 그대로 보여준다.
///
/// 7주차(W7-01): 본인 평점 카드 오른쪽에 수정·삭제 버튼을 둔다.
/// [onEdit]·[onDelete]가 null이면(본인 평점이 아니면) 버튼을 그리지 않는다.
/// [selected]가 null이 아니면 다중 선택 모드로, 버튼 대신 CheckBox를 보여준다.
class RatingCard extends StatelessWidget {
  const RatingCard({
    super.key,
    required this.entry,
    this.onEdit,
    this.onDelete,
    this.selected,
    this.onSelectedChanged,
  });

  final RatingWithMovie entry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// 다중 선택 모드에서 이 카드의 선택 여부. 기본 모드면 null.
  final bool? selected;
  final VoidCallback? onSelectedChanged;

  bool get _isSelecting => selected != null;

  /// 등록일을 기기 시간대 기준 `yyyy.MM.dd`로 표시한다.
  static String formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}.$month.$day';
  }

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;
    final comment = rating.comment;

    final BorderRadius radius = BorderRadius.circular(14);
    final bool isSelected = selected ?? false;

    final Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surfaceTint : AppColors.surface,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.primaryContainer,
          width: 1.5,
        ),
        borderRadius: radius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TmdbPosterImage(
              posterPath: movie?.posterPath,
              width: 86,
              height: 128,
              size: 'w185',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 4),
                Text(
                  movie?.title ?? '영화 #${rating.movieId}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '별점 ${rating.score} / 5',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if (movie == null) ...<Widget>[
                  const SizedBox(height: 8),
                  const Text('포스터 정보 없음', style: AppTextStyles.bodySmall),
                ],
                // 후기가 없는(null) 기록은 후기 줄을 그리지 않는다.
                if (comment != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    comment,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${formatDate(rating.createdAt)} 등록',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_isSelecting)
            Checkbox(
              value: isSelected,
              onChanged: onSelectedChanged == null
                  ? null
                  : (_) => onSelectedChanged!(),
            )
          else if (onEdit != null || onDelete != null)
            _CardActions(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );

    if (!_isSelecting) return card;
    // 선택 모드에서는 카드 어디를 눌러도 선택이 바뀐다.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onSelectedChanged,
        child: card,
      ),
    );
  }
}

/// 카드 오른쪽의 개별 수정·삭제 버튼.
class _CardActions extends StatelessWidget {
  const _CardActions({this.onEdit, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            tooltip: '수정',
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
          ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            tooltip: '삭제',
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
      ],
    );
  }
}
