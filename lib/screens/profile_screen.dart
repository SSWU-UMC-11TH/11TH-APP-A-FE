import 'package:flutter/material.dart';

import '../widgets/common_app_bar.dart';
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
    return const Column(
      children: [
        SizedBox(height: 24),
        ProfileHeader(),
        SizedBox(height: 24),
        ProfileStats(),
      ],
    );
  }
}
