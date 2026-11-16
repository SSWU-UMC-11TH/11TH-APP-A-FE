import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/movie_log_app.dart';
import 'practice/dart_practice.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Token을 읽기 전에 .env 로드가 끝나야 하므로 runApp 전에 기다린다.
  await dotenv.load(fileName: '.env');
  // 0주차 Dart 문법 연습 결과를 콘솔에서 확인한다.
  runDartPractice();
  runApp(const MovieLogApp());
}
