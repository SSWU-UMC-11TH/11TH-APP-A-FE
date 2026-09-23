import 'package:flutter/material.dart';

import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';
import 'common_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '프로필', centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const ProfileHeader(),
              const SizedBox(height: 24),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StatItem(label: '본 영화', value: '24'),
                  StatItem(label: '평균 평점', value: '4.5'),
                  StatItem(label: '즐겨찾기', value: '8'),
                ],
              ),
              const SizedBox(height: 24),
              const FavoriteGenres(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    debugPrint('프로필 수정 버튼을 눌렀습니다.');
                  },
                  child: const Text('프로필 수정'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 프로필 이미지 자리 - ZIP 받으면 Image.asset으로 교체 예정
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.person, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 12),
        const Text('무비러버', style: AppTextStyles.titleLarge),
        const SizedBox(height: 4),
        const Text('좋아하는 영화를 기록하고 있어요', style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

class StatItem extends StatelessWidget {
  const StatItem({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class FavoriteGenres extends StatelessWidget {
  const FavoriteGenres({super.key});

  static const List<Map<String, dynamic>> genres = [
    {'label': '드라마', 'icon': Icons.theater_comedy_outlined},
    {'label': 'SF', 'icon': Icons.rocket_launch_outlined},
    {'label': '애니메이션', 'icon': Icons.animation_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genres.map((genre) {
        return Chip(
          avatar: Icon(
            genre['icon'] as IconData,
            size: 18,
            color: colors.primary,
          ),
          label: Text(genre['label'] as String, style: AppTextStyles.bodySmall),
          backgroundColor: colors.surface,
          side: BorderSide(color: colors.primary),
        );
      }).toList(),
    );
  }
}
