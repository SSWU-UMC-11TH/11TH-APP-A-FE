import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/start_screen.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';

/// 앱에서 사용하는 Route를 모아 관리하는 클래스.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/start',
    routes: <RouteBase>[
      GoRoute(
        path: '/start',
        builder: (BuildContext context, GoRouterState state) =>
            const StartScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (BuildContext context, GoRouterState state) =>
            const SignUpScreen(),
      ),
      // 상세 화면은 NavigationBar 없이 전체 화면으로 보여주므로 ShellRoute 밖에 둔다.
      GoRoute(
        path: '/movies/:movieId',
        builder: (BuildContext context, GoRouterState state) =>
            MovieDetailScreen(
              movieId: state.pathParameters['movieId'],
              movie: state.extra as TmdbMovieDto?,
            ),
      ),
      // 홈, 영화, 마이는 NavigationBar를 공유하므로 MainScreen을 공통 부모로 사용한다.
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return MainScreen(
            currentIndex: indexFromLocation(state.uri.path),
            child: child,
          );
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/home',
            // 화면마다 ViewModel을 만들고, 생성 직후 한 번만 첫 요청을 보낸다.
            builder: (BuildContext context, GoRouterState state) =>
                ChangeNotifierProvider<MovieHomeViewModel>(
                  create: (BuildContext context) =>
                      MovieHomeViewModel(context.read<TmdbMovieService>())
                        ..loadPopular(),
                  child: const HomeScreen(),
                ),
          ),
          GoRoute(
            path: '/movies',
            builder: (BuildContext context, GoRouterState state) =>
                ChangeNotifierProvider<MovieListViewModel>(
                  create: (BuildContext context) =>
                      MovieListViewModel(context.read<TmdbMovieService>())
                        ..loadInitial(),
                  child: const MovieListScreen(),
                ),
          ),
          GoRoute(
            path: '/my',
            builder: (BuildContext context, GoRouterState state) =>
                const ProfileScreen(),
          ),
        ],
      ),
    ],
  );

  /// 현재 URL에서 NavigationBar의 선택 index를 계산한다.
  static int indexFromLocation(String path) {
    if (path.startsWith('/movies')) return 1;
    if (path.startsWith('/my')) return 2;

    return 0;
  }
}
