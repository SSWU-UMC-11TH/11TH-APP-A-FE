import 'package:flutter/material.dart';

/// MovieLog의 시작 화면 (W0-01).
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  // 디자인 시안에서 사용한 색상
  static const Color _background = Color(0xFFFBF8F3);
  static const Color _primary = Color(0xFF5B3E8E);
  static const Color _titleColor = Color(0xFF1F1B24);
  static const Color _bodyColor = Color(0xFF6B6572);
  static const Color _labelColor = Color(0xFF8A8491);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 48),
              const Text(
                'FLUTTER 1주차',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: _labelColor,
                ),
              ),
              const SizedBox(height: 56),
              const Icon(
                Icons.movie_outlined,
                size: 56,
                color: _primary,
              ),
              const SizedBox(height: 56),
              const Text(
                '영화의 순간을\n기록하세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  height: 1.35,
                  fontWeight: FontWeight.bold,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: _bodyColor,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // TODO(movielog): 다음 주차에 화면 이동 기능을 연결한다.
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
