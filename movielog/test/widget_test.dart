import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/main.dart';

void main() {
  testWidgets('시작 화면의 아이콘, 문구, 버튼이 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(const MovieLogApp());

    expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    expect(find.text('영화의 순간을\n기록하세요'), findsOneWidget);
    expect(find.text('보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '시작하기'), findsOneWidget);
  });
}
