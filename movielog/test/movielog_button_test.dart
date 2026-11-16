import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/movielog_button.dart';

Future<void> pumpInColumn(WidgetTester tester, Widget button) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[button],
          ),
        ),
      ),
    ),
  );
}

ElevatedButton elevatedOf(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byType(ElevatedButton));

Color? disabledColorOf(WidgetTester tester) =>
    elevatedOf(tester).style?.backgroundColor
        ?.resolve(<WidgetState>{WidgetState.disabled});

void main() {
  testWidgets('기본 상태는 label을 보여주고 누를 수 있다', (WidgetTester tester) async {
    var tapped = 0;
    await pumpInColumn(
      tester,
      MovieLogButton(label: '중복 확인', onPressed: () => tapped++),
    );

    await tester.tap(find.text('중복 확인'));
    expect(tapped, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('통신 중에는 회색 비활성이고 인디케이터만 보인다', (WidgetTester tester) async {
    var tapped = 0;
    await pumpInColumn(
      tester,
      MovieLogButton(
        label: '중복 확인',
        isLoading: true,
        onPressed: () => tapped++,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('중복 확인'), findsNothing);
    expect(elevatedOf(tester).enabled, isFalse);
    expect(disabledColorOf(tester), AppColors.loading);
    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    expect(tapped, 0);
  });

  testWidgets('onPressed가 null이면 연보라 비활성이다', (WidgetTester tester) async {
    await pumpInColumn(
      tester,
      const MovieLogButton(label: '가입하기', onPressed: null),
    );

    expect(elevatedOf(tester).enabled, isFalse);
    expect(disabledColorOf(tester), AppColors.primaryDisabled);
  });

  testWidgets('width null은 내용 크기, infinity는 최대 너비, 숫자는 고정 크기', (
    WidgetTester tester,
  ) async {
    await pumpInColumn(tester, MovieLogButton(label: '확인', onPressed: () {}));
    final double intrinsic = tester.getSize(find.byType(MovieLogButton)).width;
    expect(intrinsic, lessThan(400));

    await pumpInColumn(
      tester,
      MovieLogButton(label: '확인', width: double.infinity, onPressed: () {}),
    );
    expect(tester.getSize(find.byType(MovieLogButton)).width, 400);

    await pumpInColumn(
      tester,
      MovieLogButton(label: '확인', width: 96, onPressed: () {}),
    );
    expect(tester.getSize(find.byType(MovieLogButton)).width, 96);
  });
}
