import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/movie_log_client.dart';
import 'data/services/member_check_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() => runApp(const MovieLogApp());

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<MemberCheckService>(
      create: (_) => MemberCheckService(createMovieLogClient()),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
