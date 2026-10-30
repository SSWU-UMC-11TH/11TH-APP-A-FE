import 'package:shared_preferences/shared_preferences.dart';

// 마지막 선택 장르처럼 단순하고 중요하지 않은 값만 저장한다.
// JWT, 비밀번호, 개인정보는 여기에 저장하지 않는다.
class GenrePreference {
  GenrePreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  // 장르 이름 대신 TMDB 장르 id를 저장한다. 4주차 문자열 값과 섞이지 않게 key를 바꿨다.
  static const _selectedGenreIdKey = 'selected_genre_id';

  final SharedPreferencesAsync _preferences;

  // null이면 전체를 뜻한다.
  Future<int?> read() async {
    return _preferences.getInt(_selectedGenreIdKey);
  }

  Future<void> save(int? genreId) async {
    if (genreId == null) {
      await clear();
      return;
    }
    await _preferences.setInt(_selectedGenreIdKey, genreId);
  }

  Future<void> clear() async {
    await _preferences.remove(_selectedGenreIdKey);
  }
}
