import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/network/movie_log_client.dart';
import '../core/network/tmdb_client.dart';
import '../core/storage/saved_email_store.dart';
import '../core/storage/token_storage.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/session_ratings_store.dart';

/// 워크북 백엔드용 Dio 두 개를 묶는다.
///
/// - [public]: Interceptor 없음. 로그인·회원가입·중복 확인·공개 평점 조회
/// - [auth]: AuthInterceptor 등록. 내 정보·평점 등록/수정/삭제
/// TMDB Client와는 baseUrl·Header가 다르므로 여기에 합치지 않는다.
class MovieLogClients {
  MovieLogClients(TokenStorage storage)
    : public = createMovieLogClient(),
      auth = createAuthMovieLogClient(storage);

  final Dio public;
  final Dio auth;
}

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({
    super.key,
    this.movieService,
    this.signUpService,
    this.ratingApiService,
    this.authApiService,
    this.memberApiService,
    this.tokenStorage,
    this.savedEmailStore,
  });

  /// 테스트에서 fixture를 돌려주는 Service·저장소로 바꿔 끼울 때 사용한다.
  final TmdbMovieService? movieService;
  final SignUpService? signUpService;
  final RatingApiService? ratingApiService;
  final AuthApiService? authApiService;
  final MemberApiService? memberApiService;
  final TokenStorage? tokenStorage;
  final SavedEmailStore? savedEmailStore;

  @override
  Widget build(BuildContext context) {
    // 여러 Route가 함께 쓰는 Service는 MaterialApp.router 위에 한 번만 등록한다.
    // Provider의 create는 처음 읽힐 때 한 번만 실행되므로 Client도 한 번만 만들어진다.
    return MultiProvider(
      providers: [
        Provider<TokenStorage>(
          create: (_) =>
              tokenStorage ?? SecureTokenStorage(const FlutterSecureStorage()),
        ),
        Provider<SavedEmailStore>(
          create: (_) => savedEmailStore ?? PreferencesSavedEmailStore(),
        ),
        Provider<MovieLogClients>(
          create: (BuildContext context) =>
              MovieLogClients(context.read<TokenStorage>()),
        ),
        // TMDB Client에는 AuthInterceptor를 붙이지 않는다. MovieLog JWT가 TMDB로 가면 안 된다.
        Provider<TmdbMovieService>(
          create: (_) => movieService ?? TmdbMovieService(createTmdbClient()),
        ),
        // 공개 Client
        Provider<AuthApiService>(
          create: (BuildContext context) =>
              authApiService ??
              AuthApiService(context.read<MovieLogClients>().public),
        ),
        Provider<SignUpService>(
          create: (BuildContext context) =>
              signUpService ??
              SignUpService(context.read<MovieLogClients>().public),
        ),
        // 보호 Client
        Provider<MemberApiService>(
          create: (BuildContext context) =>
              memberApiService ??
              MemberApiService(context.read<MovieLogClients>().auth),
        ),
        // 공개 조회는 public, 등록·수정·삭제는 auth Client로 보낸다.
        Provider<RatingApiService>(
          create: (BuildContext context) {
            if (ratingApiService != null) return ratingApiService!;
            final MovieLogClients clients = context.read<MovieLogClients>();
            return RatingApiService(clients.public, clients.auth);
          },
        ),
        // Service를 주입받는 인증 ViewModel
        ChangeNotifierProvider<AuthViewModel>(
          create: (BuildContext context) => AuthViewModel(
            context.read<AuthApiService>(),
            context.read<MemberApiService>(),
            context.read<TokenStorage>(),
          ),
        ),
        // 이번 로그인 세션에서 등록한 평점. 세션이 바뀌면 스스로 비운다.
        ChangeNotifierProvider<SessionRatingsStore>(
          create: (BuildContext context) =>
              SessionRatingsStore(context.read<AuthViewModel>()),
        ),
      ],
      child: const _MovieLogRouterApp(),
    );
  }
}

/// GoRouter를 앱이 살아 있는 동안 한 번만 만들기 위한 호스트.
///
/// build에서 만들면 다시 그려질 때마다 Router가 새로 생겨 현재 위치가 초기화된다.
class _MovieLogRouterApp extends StatefulWidget {
  const _MovieLogRouterApp();

  @override
  State<_MovieLogRouterApp> createState() => _MovieLogRouterAppState();
}

class _MovieLogRouterAppState extends State<_MovieLogRouterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final AuthViewModel authViewModel = context.read<AuthViewModel>();
    _router = AppRouter.createRouter(authViewModel);
    // 첫 build 이후 세션 복원을 시작한다. 그 전까지는 initializing이라 Splash가 보인다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) authViewModel.restoreSession();
    });
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MovieLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
