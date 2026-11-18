import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';

import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_loader.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/start_screen.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/sign_up_view_model.dart';

/// 앱에서 사용하는 Route를 모아 관리하는 클래스.
class AppRouter {
  AppRouter._();

  /// 앱 전체의 root Navigator. ShellRoute 밖에 띄울 자식 화면이 이 키를 지정한다.
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/start',
    navigatorKey: rootNavigatorKey,
    routes: <RouteBase>[
      GoRoute(
        path: '/start',
        builder: (BuildContext context, GoRouterState state) =>
            const StartScreen(),
      ),
      GoRoute(
        path: '/register',
        // 회원가입 화면 전용 ViewModel. 화면을 떠나면 중복 확인 상태도 함께 사라진다.
        builder: (BuildContext context, GoRouterState state) =>
            ChangeNotifierProvider<SignUpViewModel>(
              create: (BuildContext context) =>
                  SignUpViewModel(context.read<SignUpService>()),
              child: const SignUpScreen(),
            ),
      ),
      // 상세 화면은 NavigationBar 없이 전체 화면으로 보여주므로 ShellRoute 밖에 둔다.
      // movieId는 URL 식별자이고, 화면에 넘길 TmdbMovieDto는 state.extra에서 꺼낸다.
      // extra가 없거나(직접 접근·Deep Link) id가 다르면 Loader가 TMDB로 다시 조회한다.
      GoRoute(
        path: '/movies/:movieId',
        builder: (BuildContext context, GoRouterState state) {
          final int? id = int.tryParse(state.pathParameters['movieId'] ?? '');
          if (id == null || id < 1) {
            return const MovieDetailFailure(message: '영화 ID가 올바르지 않습니다.');
          }
          final Object? extra = state.extra;
          return MovieDetailLoader(
            // 같은 Route 안에서 movieId만 바뀌어도 이전 영화의 State·ViewModel을 재사용하지 않는다.
            key: ValueKey<int>(id),
            movieId: id,
            initialMovie: extra is TmdbMovieDto && extra.id == id
                ? extra
                : null,
          );
        },
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
            routes: <RouteBase>[
              GoRoute(
                path: 'ratings', // 최종 경로: /my/ratings
                // 지정하지 않으면 ShellRoute의 Navigator에 쌓여 NavigationBar가 남으므로
                // root Navigator 위에 띄워 NavigationBar를 가린다.
                parentNavigatorKey: rootNavigatorKey,
                builder: (BuildContext context, GoRouterState state) {
                  // 6주차 고정 memberId 1 대신 회원가입 결과로 받은 학습용 회원 ID를 쓴다.
                  final int? id = context
                      .read<LearningMemberSession>()
                      .memberId;
                  if (id == null) return const MyRatingsSignUpRequired();
                  return ChangeNotifierProvider<MyRatingsViewModel>(
                    create: (BuildContext context) => MyRatingsViewModel(
                      context.read<RatingApiService>(),
                      context.read<TmdbMovieService>(),
                      id,
                    )..load(),
                    child: const MyRatingsScreen(),
                  );
                },
              ),
            ],
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
