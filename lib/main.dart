import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'screens/profile_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());

  final List<Movie> movieList = const [
    Movie(id: 1, title: '아바타'),
    Movie(id: 2, title: '스파이더맨'),
    Movie(id: 3, title: '인턴'),
  ];

  //  영화 제목 출력
  for (var movie in movieList) {
    debugPrint(movie.title);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      // 시작 화면을 확인하려면 StartScreen()으로 변경
      home: const ProfileScreen(),
    );
  }
}

class Movie {
  const Movie({required this.id, required this.title});

  final int id;
  final String title;

}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                'FLUTTER 0주차',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall,
              ),
              const SizedBox(height: 56),
              SvgPicture.asset(
                'assets/logos/movielog_logo.svg',
                width: 72,
                height: 72,
                semanticsLabel: 'MovieLog 로고',
              ),
              const SizedBox(height: 64),
              const Text(
                '영화의 순간을\n기록하세요',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const Spacer(),
              ElevatedButton(
                // 화면 이동은 아직 구현하지 않음
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepViolet,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: AppTextStyles.labelLarge,
                ),
                child: const Text('시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}