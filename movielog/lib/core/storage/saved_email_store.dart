import 'package:shared_preferences/shared_preferences.dart';

/// Challenge: 로그인 화면의 "이메일 저장" 값을 보관한다.
///
/// 민감하지 않은 이메일만 SharedPreferences에 저장한다.
/// 비밀번호와 토큰은 절대 이 저장소에 넣지 않는다.
abstract interface class SavedEmailStore {
  Future<String?> readEmail();
  Future<void> saveEmail(String email);
  Future<void> clearEmail();
}

class PreferencesSavedEmailStore implements SavedEmailStore {
  PreferencesSavedEmailStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _emailKey = 'movielog.saved_email';
  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readEmail() => _preferences.getString(_emailKey);

  @override
  Future<void> saveEmail(String email) =>
      _preferences.setString(_emailKey, email.trim());

  @override
  Future<void> clearEmail() => _preferences.remove(_emailKey);
}
