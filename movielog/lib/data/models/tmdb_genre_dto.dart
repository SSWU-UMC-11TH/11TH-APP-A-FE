/// TMDB 공식 장르. 장르 이름을 임의로 쓰지 않고 Genre API의 `id/name`을 그대로 사용한다.
class TmdbGenreDto {
  const TmdbGenreDto({required this.id, required this.name});

  final int id;
  final String name;

  factory TmdbGenreDto.fromJson(Map<String, dynamic> json) {
    return TmdbGenreDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );
  }
}
