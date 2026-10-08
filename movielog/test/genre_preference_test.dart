import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:movielog/models/movie.dart';
import 'package:movielog/services/genre_preference.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('저장된 장르가 없으면 전체를 돌려준다', () async {
    expect(await GenrePreference().read(), allGenre);
  });

  test('저장한 장르를 다시 읽을 수 있다', () async {
    final GenrePreference preference = GenrePreference();
    await preference.save('SF');

    // 앱을 다시 실행한 것처럼 새 인스턴스로 읽어도 같은 값이 나온다.
    expect(await GenrePreference().read(), 'SF');
  });

  test('clear하면 다시 전체를 돌려준다', () async {
    final GenrePreference preference = GenrePreference();
    await preference.save('액션');
    await preference.clear();

    expect(await preference.read(), allGenre);
  });
}
