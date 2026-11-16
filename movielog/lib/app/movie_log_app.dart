import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/tmdb_client.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key, this.movieService});

  /// 테스트에서 fixture를 돌려주는 Service로 바꿔 끼울 때 사용한다.
  final TmdbMovieService? movieService;

  @override
  Widget build(BuildContext context) {
    // 여러 Route가 함께 쓰는 Service는 MaterialApp.router 위에 한 번만 등록한다.
    return MultiProvider(
      providers: [
        Provider<TmdbMovieService>(
          create: (_) => movieService ?? TmdbMovieService(createTmdbClient()),
        ),
      ],
      // 첫 화면과 화면 이동은 MaterialApp이 아니라 AppRouter의 GoRouter가 결정한다.
      child: MaterialApp.router(
        title: 'MovieLog',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
