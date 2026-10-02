import 'package:flutter/material.dart';

import '../widgets/common_app_bar.dart';
import '../widgets/edit_profile_button.dart';
import '../widgets/favorite_genres.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats.dart';

/// 내 프로필 화면 (W1-01).
///
/// 3주차 마이페이지를 1주차 미션의 구조(공용 AppBar + 의미 단위 Widget)로 재구성했다.
/// NavigationBar의 마이 탭(/my)에서 보여준다.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CommonAppBar(title: '내 프로필'),
      body: SafeArea(child: ProfileBody()),
    );
  }
}

/// 프로필 화면의 본문. 헤더, 수정 버튼, 통계, 선호 장르를 세로로 배치한다.
class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      // 화면 가장자리와 내용 사이의 안쪽 여백
      padding: EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        // Column의 교차축(가로)을 stretch로 두어 통계 Row가 화면 너비를 채운다.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ProfileHeader(),
          SizedBox(height: 24),
          Center(child: EditProfileButton()),
          SizedBox(height: 28),
          ProfileStats(),
          SizedBox(height: 28),
          FavoriteGenres(),
        ],
      ),
    );
  }
}
