import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_text_styles.dart';

/// MovieLog의 시작 화면 (W0-01).
///
/// 1주차: 0주차의 기본 Icon을 MovieLog 로고 SVG로 교체하고,
/// 화면 안에 직접 적었던 색상·글자 스타일을 AppColors·AppTextStyles로 옮겼다.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 48),
              Text(
                'FLUTTER 1주차',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 56),
              // 0주차의 Icons.movie_outlined를 실제 MovieLog 로고로 교체했다.
              SvgPicture.asset(
                'assets/logos/movielog_logo.svg',
                width: 72,
                height: 72,
                semanticsLabel: 'MovieLog 로고',
              ),
              const SizedBox(height: 56),
              const Text(
                '영화의 순간을\n기록하세요',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const Spacer(),
              ElevatedButton(
                // 시작 화면으로 되돌아올 필요가 없으므로 push 대신 go를 사용한다.
                onPressed: () => context.go('/register'),
                // 버튼 모양은 AppTheme의 elevatedButtonTheme를 그대로 따른다.
                child: const Text('시작하기'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
