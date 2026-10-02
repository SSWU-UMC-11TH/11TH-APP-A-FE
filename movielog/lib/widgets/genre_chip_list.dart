import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_theme.dart';

/// 가로로 스크롤하며 장르 하나를 고르는 Chip 목록.
class GenreChipList extends StatelessWidget {
  const GenreChipList({
    super.key,
    required this.selectedGenre,
    required this.onGenreSelected,
  });

  final String selectedGenre;
  final ValueChanged<String> onGenreSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: movieGenres.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final String genre = movieGenres[index];
          final bool isSelected = genre == selectedGenre;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onGenreSelected(genre),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                genre,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
