import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';

/// 가로로 스크롤하며 장르 하나를 고르는 Chip 목록.
///
/// 저장된 장르가 복원되는 등 선택값이 바뀌면 해당 Chip이 보이도록 스크롤한다.
class GenreChipList extends StatefulWidget {
  const GenreChipList({
    super.key,
    required this.selectedGenre,
    required this.onGenreSelected,
  });

  final String selectedGenre;
  final ValueChanged<String> onGenreSelected;

  @override
  State<GenreChipList> createState() => _GenreChipListState();
}

class _GenreChipListState extends State<GenreChipList> {
  /// 선택된 Chip을 찾아 스크롤하기 위한 장르별 Key.
  final Map<String, GlobalKey> _chipKeys = <String, GlobalKey>{
    for (final String genre in movieGenres) genre: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _scrollToSelected();
  }

  @override
  void didUpdateWidget(GenreChipList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGenre != widget.selectedGenre) {
      _scrollToSelected();
    }
  }

  /// 레이아웃이 끝난 뒤 선택된 Chip이 화면 가운데에 오도록 스크롤한다.
  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? chipContext =
          _chipKeys[widget.selectedGenre]?.currentContext;
      if (!mounted || chipContext == null) return;

      Scrollable.ensureVisible(
        chipContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
      );
    });
  }

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
          final bool isSelected = genre == widget.selectedGenre;

          return GestureDetector(
            key: _chipKeys[genre],
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onGenreSelected(genre),
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
