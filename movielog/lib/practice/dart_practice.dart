import 'package:flutter/foundation.dart';

import 'practice_movie.dart';

/// 0주차 Dart 문법 연습용 영화 목록.
const List<PracticeMovie> myMovies = <PracticeMovie>[
  PracticeMovie(
    title: '인터스텔라',
    director: '크리스토퍼 놀란',
    releaseYear: 2014,
    myRating: 4.5,
  ),
  PracticeMovie(
    title: '라라랜드',
    director: '데이미언 셔젤',
    releaseYear: 2016,
    myRating: 4.0,
  ),
  PracticeMovie(
    title: '소울',
    director: '피트 닥터',
    releaseYear: 2020,
  ),
];

/// nullable 닉네임을 안전한 기본값으로 변환한다.
String resolveNickname(String? nickname) {
  // ?? 연산자로 null일 때의 기본값을 지정하고,
  // 공백만 입력된 경우도 기본값으로 처리한다.
  final String name = nickname ?? '';
  return name.trim().isEmpty ? '게스트' : name.trim();
}

/// for 문과 map()을 사용해 영화 정보를 출력한다.
void runDartPractice() {
  debugPrint('--- for 문으로 제목 출력 ---');
  for (final PracticeMovie movie in myMovies) {
    debugPrint(movie.title);
  }

  debugPrint('--- map()으로 제목 출력 ---');
  final List<String> titles =
      myMovies.map((PracticeMovie movie) => movie.title).toList();
  debugPrint(titles.join(', '));

  debugPrint('--- 평점 확인 (nullable 처리) ---');
  for (final PracticeMovie movie in myMovies) {
    debugPrint(movie.toString());
  }

  debugPrint('--- 닉네임 기본값 변환 ---');
  const String? emptyNickname = null;
  debugPrint('null -> ${resolveNickname(emptyNickname)}');
  debugPrint('"  " -> ${resolveNickname('  ')}');
  debugPrint('"몽모" -> ${resolveNickname('몽모')}');
}
