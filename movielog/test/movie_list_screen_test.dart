import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/services/fake_movie_service.dart';
import 'package:movielog/services/genre_preference.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/genre_chip_list.dart';
import 'package:movielog/widgets/movie_card.dart';
import 'package:movielog/widgets/movie_grid.dart';
import 'package:movielog/widgets/movie_list_empty.dart';
import 'package:movielog/widgets/movie_list_error.dart';
import 'package:movielog/widgets/movie_list_loading.dart';

/// FakeMovieService의 지연 시간. Loading 확인 뒤 이만큼 시간을 흘려 완료시킨다.
const Duration fetchDelay = Duration(seconds: 1);

Future<void> pumpMovieList(
  WidgetTester tester, {
  MovieLoadMode initialLoadMode = MovieLoadMode.success,
  String? initialGenre,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: MovieListScreen(
          initialGenre: initialGenre,
          initialLoadMode: initialLoadMode,
        ),
      ),
    ),
  );
  // 저장된 장르 읽기처럼 즉시 끝나는 비동기 작업을 반영한다.
  await tester.pump();
}

String selectedGenreOf(WidgetTester tester) =>
    tester.widget<GenreChipList>(find.byType(GenreChipList)).selectedGenre;

/// GridView는 화면에 보이는 카드만 만들므로 Grid에 전달된 영화 수로 확인한다.
int gridMovieCountOf(WidgetTester tester) =>
    tester.widget<MovieGrid>(find.byType(MovieGrid)).movies.length;

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Loading 화면이 먼저 보이고 완료되면 영화 Grid가 표시된다', (
    WidgetTester tester,
  ) async {
    await pumpMovieList(tester);

    expect(find.byType(MovieListLoading), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('영화를 불러오는 중이에요'), findsOneWidget);
    expect(find.byType(MovieGrid), findsNothing);

    await tester.pump(fetchDelay);

    expect(find.byType(MovieListLoading), findsNothing);
    expect(find.byType(MovieGrid), findsOneWidget);
    expect(gridMovieCountOf(tester), 6);
    expect(find.text('별빛 아래 우리'), findsOneWidget);
  });

  testWidgets('빈 목록으로 완료되면 Empty 화면이 표시된다', (WidgetTester tester) async {
    await pumpMovieList(tester, initialLoadMode: MovieLoadMode.empty);
    await tester.pump(fetchDelay);

    expect(find.byType(MovieListEmpty), findsOneWidget);
    expect(find.text('조건에 맞는 영화가 없어요'), findsOneWidget);
    expect(find.byType(MovieCard), findsNothing);
  });

  testWidgets('오류로 완료되면 Error 화면이 표시되고 다시 시도하면 성공한다', (
    WidgetTester tester,
  ) async {
    await pumpMovieList(tester, initialLoadMode: MovieLoadMode.failure);
    await tester.pump(fetchDelay);

    expect(find.byType(MovieListError), findsOneWidget);
    expect(find.text('영화를 불러오지 못했어요'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '다시 시도'), findsOneWidget);
    // 내부 Exception 메시지는 화면에 그대로 노출하지 않는다.
    expect(find.textContaining('MovieLoadException'), findsNothing);
    expect(find.text('영화를 불러오지 못했습니다.'), findsNothing);
    // 오류를 Empty 화면으로 잘못 보여주지 않는다.
    expect(find.byType(MovieListEmpty), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '다시 시도'));
    await tester.pump();
    // 재시도하면 새 Future가 만들어져 Loading부터 다시 시작한다.
    expect(find.byType(MovieListLoading), findsOneWidget);
    expect(find.byType(MovieListError), findsNothing);

    await tester.pump(fetchDelay);
    expect(find.byType(MovieGrid), findsOneWidget);
    expect(gridMovieCountOf(tester), 6);
  });

  testWidgets('장르 Chip을 누르면 목록이 걸러지고 선택한 장르가 저장된다', (
    WidgetTester tester,
  ) async {
    await pumpMovieList(tester);
    await tester.pump(fetchDelay);

    await tester.tap(find.text('SF'));
    await tester.pump();

    expect(selectedGenreOf(tester), 'SF');
    expect(find.text('우주의 끝에서'), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsNothing);
    expect(await GenrePreference().read(), 'SF');
  });

  testWidgets('저장된 장르가 있으면 화면 진입 시 복원된다', (WidgetTester tester) async {
    await GenrePreference().save('액션');

    await pumpMovieList(tester);
    expect(selectedGenreOf(tester), '액션');

    await tester.pump(fetchDelay);
    expect(find.byType(MovieCard), findsOneWidget);
    expect(find.text('미션 임프로버블'), findsOneWidget);
  });

  testWidgets('Query Parameter 장르는 저장된 장르보다 우선한다', (WidgetTester tester) async {
    await GenrePreference().save('액션');

    await pumpMovieList(tester, initialGenre: '로맨스');
    await tester.pump(fetchDelay);

    expect(selectedGenreOf(tester), '로맨스');
    expect(find.text('네 번째 오후'), findsOneWidget);
  });

  testWidgets('개발용 메뉴에서 고른 모드로 목록을 다시 불러온다', (WidgetTester tester) async {
    await pumpMovieList(tester);
    await tester.pump(fetchDelay);
    expect(find.byType(MovieGrid), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('빈 목록으로 다시 불러오기'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(MovieListLoading), findsOneWidget);
    await tester.pump(fetchDelay);
    expect(find.byType(MovieListEmpty), findsOneWidget);
  });
}
