import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/tmdb_config.dart';
import 'core/network/tmdb_client.dart';
import 'data/services/tmdb_movie_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 로드가 끝나기 전에 값을 읽으면 빈 값이 되므로 runApp 전에 기다린다.
  await dotenv.load(fileName: '.env');

  // Guided Step 1 확인용 첫 호출: Step 3에서 ViewModel로 옮긴다.
  if (kDebugMode) {
    debugPrint('[TMDB] Token 로드 여부: ${TmdbConfig.hasAccessToken}');
    TmdbMovieService(createTmdbClient()).fetchPopular().ignore();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
