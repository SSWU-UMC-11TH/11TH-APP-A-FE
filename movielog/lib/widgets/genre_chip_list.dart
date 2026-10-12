import 'package:flutter/material.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../theme/app_colors.dart';

/// 가로로 스크롤하며 장르 하나를 고르는 Chip 목록.
///
/// 첫 Chip은 장르 조건이 없는 `전체`(null)이고, 나머지는 Genre API의 `id/name`이다.
/// [enabled]가 false이면 Chip을 눌러도 선택이 바뀌지 않는다.
class GenreChipList extends StatefulWidget {
  const GenreChipList({
    super.key,
    required this.genres,
    required this.selectedGenreId,
    required this.onGenreSelected,
    this.enabled = true,
  });

  static const String allLabel = '전체';

  final List<TmdbGenreDto> genres;
  final int? selectedGenreId;
  final ValueChanged<int?> onGenreSelected;
  final bool enabled;

  @override
  State<GenreChipList> createState() => _GenreChipListState();
}

class _GenreChipListState extends State<GenreChipList> {
  /// 선택된 Chip을 찾아 스크롤하기 위한 장르 ID별 Key. `전체`는 null을 key로 쓴다.
  final Map<int?, GlobalKey> _chipKeys = <int?, GlobalKey>{};

  @override
  void didUpdateWidget(GenreChipList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGenreId != widget.selectedGenreId) {
      _scrollToSelected();
    }
  }

  /// 레이아웃이 끝난 뒤 선택된 Chip이 화면 가운데에 오도록 스크롤한다.
  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? chipContext =
          _chipKeys[widget.selectedGenreId]?.currentContext;
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
    final List<(int?, String)> items = <(int?, String)>[
      (null, GenreChipList.allLabel),
      for (final TmdbGenreDto genre in widget.genres) (genre.id, genre.name),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final (int? genreId, String name) = items[index];
          final bool isSelected = genreId == widget.selectedGenreId;

          return Opacity(
            opacity: widget.enabled || isSelected ? 1 : 0.5,
            child: GestureDetector(
              key: _chipKeys.putIfAbsent(genreId, GlobalKey.new),
              behavior: HitTestBehavior.opaque,
              onTap: widget.enabled
                  ? () => widget.onGenreSelected(genreId)
                  : null,
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
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
