import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/check_result.dart';
import 'package:movielog/widgets/movielog_button.dart';

void main() {
  test('중복 응답은 통신 오류가 아니라 available=false', () {
    expect(CheckResult.fromJson({'available': false}).available, isFalse);
  });

  test('후기 null 응답 파싱', () {
    final rating = RatingDto.fromJson({
      'ratingId': 12, 'movieId': 550, 'score': 5,
      'comment': null, 'createdAt': '2026-09-06T12:14:03Z',
    });
    expect(rating.comment, isNull);
    expect(rating.movieId, 550);
  });

  testWidgets('통신 중 버튼은 비활성이고 로딩만 표시', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MovieLogButton(
        label: '중복 확인', isLoading: true, onPressed: () {},
      )),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('중복 확인'), findsNothing);
    expect(tester.widget<ElevatedButton>(
      find.byType(ElevatedButton)).onPressed, isNull);
  });

  testWidgets('버튼 너비 null·고정·최대 구분', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MovieLogButton(key: const Key('auto'), label: '확인', onPressed: () {}),
          MovieLogButton(key: const Key('fixed'), label: '확인',
            width: 96, onPressed: () {}),
          MovieLogButton(key: const Key('full'), label: '확인',
            width: double.infinity, onPressed: () {}),
        ],
      )),
    ));
    expect(tester.getSize(find.byKey(const Key('fixed'))).width, 96);
    expect(
      tester.getSize(find.byKey(const Key('full'))).width,
      greaterThan(tester.getSize(find.byKey(const Key('auto'))).width),
    );
  });
}
