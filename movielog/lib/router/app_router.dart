import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/member_api_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';

import '../screens/edit_profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_loader.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/splash_screen.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/session_ratings_store.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/movielog_button.dart';

/// 인증 상태와 이동하려는 경로만 보고 다른 경로로 보낼지 정한다.
///
/// redirect 안에서는 상태만 읽는다. API 호출 같은 비동기 작업은 하지 않는다.
String? authRedirect(AuthStatus status, String location) {
  const Set<String> publicPaths = {'/login', '/register'};
  final bool atStart = location == '/start';
  final bool atPublic = publicPaths.contains(location);

  return switch (status) {
    // 토큰 확인 중 또는 확인 실패(재시도 버튼): Splash 유지
    AuthStatus.initializing ||
    AuthStatus.retryRequired => atStart ? null : '/start',
    // 로그아웃 또는 로그인 요청 중: 공개 화면만 허용
    AuthStatus.signedOut ||
    AuthStatus.authenticating => atPublic ? null : '/login',
    // 로그인됨: Splash와 로그인·회원가입 화면은 홈으로 보냄
    AuthStatus.signedIn => (atStart || atPublic) ? '/home' : null,
  };
}

/// 앱에서 사용하는 Route를 모아 관리하는 클래스.
class AppRouter {
  AppRouter._();

  /// 앱 전체의 root Navigator. ShellRoute 밖에 띄울 자식 화면이 이 키를 지정한다.
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  /// 인증 상태를 구독하는 Router를 만든다. 앱이 살아 있는 동안 한 번만 만든다.
  ///
  /// [refreshListenable]에 [AuthViewModel]을 연결해 로그인·로그아웃·만료로 상태가 바뀌면
  /// 사용자가 이동하지 않아도 redirect가 다시 실행된다.
  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
      initialLocation: '/start',
      navigatorKey: rootNavigatorKey,
      refreshListenable: authViewModel,
      redirect: (BuildContext context, GoRouterState state) =>
          authRedirect(authViewModel.status, state.uri.path),
      routes: <RouteBase>[
        GoRoute(
          path: '/start', // Splash: 토큰 확인 중 / 확인 실패 시 재시도
          builder: (BuildContext context, GoRouterState state) {
            final AuthViewModel auth = context.watch<AuthViewModel>();
            return SplashScreen(
              message: auth.message,
              onRetry: auth.status == AuthStatus.retryRequired
                  ? auth.restoreSession
                  : null,
            );
          },
        ),
        GoRoute(
          path: '/login',
          builder: (BuildContext context, GoRouterState state) =>
              const LoginScreen(),
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
                  // root Navigator 위에 띄워 NavigationBar를 가린다.
                  parentNavigatorKey: rootNavigatorKey,
                  // 7주차까지 쓰던 memberId 대신 토큰 기반 Service와 세션 Store를 쓴다.
                  builder: (BuildContext context, GoRouterState state) =>
                      ChangeNotifierProvider<MyRatingsViewModel>(
                        create: (BuildContext context) => MyRatingsViewModel(
                          context.read<RatingApiService>(),
                          context.read<TmdbMovieService>(),
                          context.read<SessionRatingsStore>(),
                          context.read<AuthViewModel>(),
                        )..load(),
                        child: const MyRatingsScreen(),
                      ),
                ),
                GoRoute(
                  path: 'profile/edit', // 최종 경로: /my/profile/edit
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (BuildContext context, GoRouterState state) {
                    final AuthViewModel auth = context.watch<AuthViewModel>();
                    if (auth.member == null) {
                      return _ProfileEditPending(auth: auth);
                    }
                    return ChangeNotifierProvider<EditProfileViewModel>(
                      create: (BuildContext context) => EditProfileViewModel(
                        context.read<MemberApiService>(),
                        auth,
                      ),
                      child: const EditProfileScreen(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// 현재 URL에서 NavigationBar의 선택 index를 계산한다.
  static int indexFromLocation(String path) {
    if (path.startsWith('/movies')) return 1;
    if (path.startsWith('/my')) return 2;

    return 0;
  }
}

/// URL로 프로필 수정에 바로 들어와 아직 내 정보가 없을 때의 화면.
class _ProfileEditPending extends StatelessWidget {
  const _ProfileEditPending({required this.auth});

  final AuthViewModel auth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('프로필 수정')),
      body: Center(
        child: auth.memberStatus == MemberLoadStatus.error
            ? MovieLogButton(
                label: '다시 시도',
                width: 140,
                onPressed: () => auth.loadMember(force: true),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
