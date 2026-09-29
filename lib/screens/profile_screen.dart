import 'package:flutter/material.dart';

import '../widgets/common_app_bar.dart';
import '../widgets/edit_profile_button.dart';
import '../widgets/favorite_genres.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHeader(),
          SizedBox(height: 24),
          Center(child: EditProfileButton()),
          SizedBox(height: 32),
          ProfileStats(),
          FavoriteGenres(),
        ],
      ),
    );
  }
}
