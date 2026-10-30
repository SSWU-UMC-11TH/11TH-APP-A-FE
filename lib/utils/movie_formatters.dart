// DTO는 값만 담고, 화면에 보여줄 형태로 바꾸는 규칙은 여기서 관리한다.

// release_date가 없거나 형식이 짧으면 연도를 표시하지 않는다.
String? releaseYear(String? releaseDate) {
  if (releaseDate == null || releaseDate.length < 4) return null;
  return releaseDate.substring(0, 4);
}

// TMDB 평점은 10점 만점이라 앱의 5점 별점에 맞춰 반으로 나눈다.
double toFiveStarRating(double voteAverage) => voteAverage / 2;
