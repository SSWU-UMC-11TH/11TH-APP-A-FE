import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// TMDB `poster_path`로 이미지 URL을 만들어 보여준다.
///
/// `poster_path`는 파일 경로만 오므로 base URL과 size를 붙인다.
/// 값이 없거나 이미지 로드에 실패하면 같은 placeholder를 보여준다.
class TmdbPosterImage extends StatelessWidget {
  const TmdbPosterImage({
    super.key,
    required this.posterPath,
    this.width = double.infinity,
    this.height = double.infinity,
    this.fit = BoxFit.cover,
    this.size = 'w500',
  });

  final String? posterPath;
  final double width;
  final double height;
  final BoxFit fit;

  /// TMDB 이미지 크기. poster·backdrop 모두 지원하는 크기는 `w780`이다.
  final String size;

  static const _baseUrl = 'https://image.tmdb.org/t/p';

  String? get _imageUrl {
    final path = posterPath;
    if (path == null || path.isEmpty) return null;
    return '$_baseUrl/$size$path';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl;

    if (imageUrl == null) return _placeholder();

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.primaryContainer,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 36,
        color: AppColors.label,
      ),
    );
  }
}
