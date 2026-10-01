class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genres,
    required this.tags,
    required this.year,
    required this.runtimeMinutes,
    required this.rating,
    required this.reviewCount,
    required this.posterAsset,
    required this.synopsis,
  });

  final int id;
  final String title;
  final List<String> genres;
  final List<String> tags;
  final int year;
  final int runtimeMinutes;
  final double rating;
  final int reviewCount;
  final String posterAsset;
  final String synopsis;

  String get genreLabel => genres.join('/');
}
