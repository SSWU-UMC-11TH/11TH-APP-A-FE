import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// 회원가입 화면.
///
/// 입력 Form 검증은 1주차 미션에서 따로 구현하고,
/// 3주차에서는 시작 화면과 홈 화면을 잇는 Route 흐름만 담당한다.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 64),
              Text(
                '회원가입',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'MovieLog 계정을 만들고\n나만의 영화 기록을 시작하세요',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              const Icon(
                Icons.person_add_alt,
                size: 56,
                color: AppColors.primary,
              ),
              const Spacer(),
              ElevatedButton(
                // 가입 이후에는 돌아올 필요가 없으므로 push 대신 go로 홈으로 이동한다.
                onPressed: () => context.go('/home'),
                child: const Text('회원가입'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
