import 'package:flutter/material.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class GenreFilterChips extends StatelessWidget {
  const GenreFilterChips({
    super.key,
    required this.genres,
    required this.selectedGenreId,
    required this.onSelected,
    this.enabled = true,
  });

  static const _allLabel = '전체';

  final List<TmdbGenreDto> genres;
  // null이면 전체가 선택된 상태다.
  final int? selectedGenreId;
  final ValueChanged<int?> onSelected;
  // 요청 중에는 false로 받아 장르를 바꾸지 못하게 한다.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        // 맨 앞에 전체 Chip을 하나 더 둔다.
        itemCount: genres.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genreId = index == 0 ? null : genres[index - 1].id;
          final label = index == 0 ? _allLabel : genres[index - 1].name;
          final isSelected = genreId == selectedGenreId;

          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            showCheckmark: false,
            onSelected: enabled ? (_) => onSelected(genreId) : null,
            labelStyle: AppTextStyles.labelLarge.copyWith(
              color: isSelected ? AppColors.white : AppColors.darkGray,
            ),
            labelPadding: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            // 비활성 상태에서도 선택된 장르가 보이도록 색을 직접 정한다.
            color: WidgetStateProperty.resolveWith((states) {
              final color = states.contains(WidgetState.selected)
                  ? AppColors.violet
                  : AppColors.lavender;
              return states.contains(WidgetState.disabled)
                  ? color.withValues(alpha: 0.5)
                  : color;
            }),
            side: BorderSide.none,
            shape: const StadiumBorder(),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}
