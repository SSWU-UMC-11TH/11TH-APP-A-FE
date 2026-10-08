import 'package:shared_preferences/shared_preferences.dart';

// 마지막 선택 장르처럼 단순하고 중요하지 않은 값만 저장한다.
// JWT, 비밀번호, 개인정보는 여기에 저장하지 않는다.
class GenrePreference {
  GenrePreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _selectedGenreKey = 'selected_genre';
  static const defaultGenre = '전체';

  final SharedPreferencesAsync _preferences;

  Future<String> read() async {
    return await _preferences.getString(_selectedGenreKey) ?? defaultGenre;
  }

  Future<void> save(String genre) async {
    await _preferences.setString(_selectedGenreKey, genre);
  }

  Future<void> clear() async {
    await _preferences.remove(_selectedGenreKey);
  }
}
