import 'package:shared_preferences/shared_preferences.dart';

import '../models/movie.dart';

/// 마지막으로 선택한 장르를 로컬에 저장하고 읽는다.
///
/// 장르처럼 단순하고 중요하지 않은 설정값만 다룬다.
/// JWT, 비밀번호 같은 민감한 값은 shared_preferences가 아니라
/// flutter_secure_storage에 저장해야 한다.
class GenrePreference {
  GenrePreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  /// 읽기와 쓰기에서 같은 Key를 써야 재실행 후에도 값이 복원된다.
  static const String selectedGenreKey = 'selected_genre';

  final SharedPreferencesAsync _preferences;

  /// 저장된 장르를 돌려준다. 저장한 적이 없으면 `전체`다.
  Future<String> read() async {
    return await _preferences.getString(selectedGenreKey) ?? allGenre;
  }

  /// 선택한 장르를 저장한다.
  Future<void> save(String genre) async {
    await _preferences.setString(selectedGenreKey, genre);
  }

  /// 저장된 장르를 지운다.
  Future<void> clear() async {
    await _preferences.remove(selectedGenreKey);
  }
}
