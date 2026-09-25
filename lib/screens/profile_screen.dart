import 'package:flutter/material.dart';

import '../widgets/profile_header.dart';
import '../widgets/stat_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
      ),
      body: const SafeArea(
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
        StatItem(label: '본 영화', value: '24'),
      ],
    );
  }
}
