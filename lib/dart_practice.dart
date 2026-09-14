class Movie {
  const Movie({required this.id, required this.title});

  final int id;
  final String title;
}

void main() {
  final movies = <Movie>[
    const Movie(id: 1, title: '인터스텔라'),
    const Movie(id: 2, title: '기생충'),
    const Movie(id: 3, title: '라라랜드'),
  ];

  for (final movie in movies) {
    print(movie.title);
  }

  movies.map((movie) => movie.title).forEach(print);

  final String? nickname = null;
  final safeName = displayName(nickname);
  print(safeName);
}

String displayName(String? nickname) {
  return nickname?.trim().isNotEmpty == true ? nickname! : '이름 없음';
}
