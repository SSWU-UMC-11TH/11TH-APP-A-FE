class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    required this.posterPath,
  });

  final int id;
  final String title;
  final String? posterPath;

  String? get posterUrl =>
      posterPath == null ? null : 'https://image.tmdb.org/t/p/w342$posterPath';

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '제목 없음',
      posterPath: json['poster_path'] as String?,
    );
  }
}
