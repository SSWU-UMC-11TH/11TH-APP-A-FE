import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/movie_log_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 로드가 끝나기 전에 값을 읽으면 빈 값이 되므로 runApp 전에 기다린다.
  await dotenv.load(fileName: '.env');
  runApp(const MovieLogApp());
}
