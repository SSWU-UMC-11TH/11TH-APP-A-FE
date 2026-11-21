import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/movielog_button.dart';

/// 앱 시작 시 세션을 확인하는 동안 보여주는 Splash 화면 (/start).
///
/// 1주차 StartScreen의 로고·제목·설명 레이아웃을 그대로 재사용하고,
/// 하단 '시작하기' 버튼 자리를 상태 표시로 바꿨다.
/// - [onRetry]가 null: 토큰 확인 중(initializing) → 인디케이터
/// - [onRetry]가 있음: 확인 실패(retryRequired) → 안내 문구와 다시 시도 버튼
///
/// 화면 이동은 하지 않는다. 확인이 끝나면 Router의 redirect가 /login 또는 /home으로 보낸다.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

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
                'FLUTTER 8주차',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 56),
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
              // 1주차 '시작하기' ElevatedButton 자리를 로딩/재시도 상태로 대체한다.
              if (onRetry == null)
                const Center(
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else ...<Widget>[
                Text(
                  message ?? '로그인 상태를 확인하지 못했어요.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                MovieLogButton(
                  label: '다시 시도',
                  width: double.infinity,
                  onPressed: onRetry,
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
