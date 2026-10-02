import 'package:flutter/material.dart';

import 'practice/dart_practice.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  // 0주차 Dart 문법 연습 결과를 콘솔에서 확인한다.
  runDartPractice();
  runApp(const MovieLogApp());
}

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 첫 화면과 화면 이동은 MaterialApp이 아니라 AppRouter의 GoRouter가 결정한다.
    return MaterialApp.router(
      title: 'MovieLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
