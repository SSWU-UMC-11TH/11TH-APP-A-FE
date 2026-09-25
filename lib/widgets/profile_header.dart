import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipOval(
          child: Image.asset(
            'assets/images/profile/profile_movielog.jpg',
            width: 88,
            height: 88,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/movie.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary,
                BlendMode.srcIn,
              ),
              semanticsLabel: '영화 아이콘',
            ),
            const SizedBox(width: 8),
            const Text(
              '무비러버',
              style: AppTextStyles.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '좋아하는 영화를 기록하고 있어요',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.darkGray,
          ),
        ),
      ],
    );
  }
}
