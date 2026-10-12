import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

Future<void> pumpPoster(WidgetTester tester, String? posterPath) {
  return tester.pumpWidget(
    MaterialApp(
      home: TmdbPosterImage(posterPath: posterPath, width: 100, height: 150),
    ),
  );
}

void main() {
  testWidgets('poster_path가 없으면 placeholder를 보여준다', (tester) async {
    await pumpPoster(tester, null);

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('poster_path에 base URL과 size를 붙여 이미지를 요청한다', (tester) async {
    await pumpPoster(tester, '/abc.jpg');

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as NetworkImage).url,
      'https://image.tmdb.org/t/p/w500/abc.jpg',
    );
  });

  testWidgets('이미지 로드에 실패하면 placeholder를 보여준다', (tester) async {
    // 테스트 환경의 HTTP 요청은 항상 실패하므로 errorBuilder가 호출된다.
    await pumpPoster(tester, '/abc.jpg');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });
}
