import 'package:flutter/material.dart';

import 'practice/dart_practice.dart';
import 'screens/start_screen.dart';

void main() {
  // 0주차 Dart 문법 연습 결과를 콘솔에서 확인한다.
  runDartPractice();
  runApp(const MovieLogApp());
}

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MovieLog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B3E8E)),
        useMaterial3: true,
      ),
      home: const StartScreen(),
    );
  }
}
