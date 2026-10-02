import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/register_screen.dart';
import '../screens/start_screen.dart';

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
            const RegisterScreen(),
      ),
      // 상세 화면은 NavigationBar 없이 전체 화면으로 보여주므로 ShellRoute 밖에 둔다.
      GoRoute(
        path: '/movies/:movieId',
        builder: (BuildContext context, GoRouterState state) =>
            MovieDetailScreen(movieId: state.pathParameters['movieId']),
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
            builder: (BuildContext context, GoRouterState state) =>
                const HomeScreen(),
          ),
          GoRoute(
            path: '/movies',
            builder: (BuildContext context, GoRouterState state) =>
                MovieListScreen(
              // Query Parameter로 전달된 장르를 초기 선택 장르로 사용한다.
              initialGenre: state.uri.queryParameters['genre'],
            ),
          ),
          GoRoute(
            path: '/my',
            builder: (BuildContext context, GoRouterState state) =>
                const MyPageScreen(),
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
