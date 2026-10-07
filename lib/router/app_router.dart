import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/start_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/movies',
        builder: (context, state) => const MovieListScreen(),
        routes: [
          GoRoute(
            path: ':movieId',
            builder: (context, state) =>
                MovieDetailScreen(movieId: state.pathParameters['movieId']),
          ),
        ],
      ),
      GoRoute(path: '/my', builder: (context, state) => const MyPageScreen()),
    ],
  );
}
