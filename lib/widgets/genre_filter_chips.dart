import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class GenreFilterChips extends StatelessWidget {
  const GenreFilterChips({
    super.key,
    required this.genres,
    required this.selectedGenre,
    required this.onSelected,
  });

  final List<String> genres;
  final String selectedGenre;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: genres.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = genres[index];
          final isSelected = genre == selectedGenre;

          return ChoiceChip(
            label: Text(genre),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onSelected(genre),
            labelStyle: AppTextStyles.labelLarge.copyWith(
              color: isSelected ? AppColors.white : AppColors.darkGray,
            ),
            labelPadding: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            backgroundColor: AppColors.lavender,
            selectedColor: AppColors.violet,
            side: BorderSide.none,
            shape: const StadiumBorder(),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}
