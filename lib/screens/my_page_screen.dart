import 'package:flutter/material.dart';

import '../widgets/common_app_bar.dart';
import 'profile_screen.dart';

// 1주차에 만든 프로필 화면의 본문(ProfileBody)을 마이페이지 탭에서 재사용한다.
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CommonAppBar(title: '내 프로필'),
      body: SafeArea(
        minimum: EdgeInsets.symmetric(horizontal: 16),
        child: ProfileBody(),
      ),
    );
  }
}
