import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 프로필 이미지, 닉네임, 한 줄 소개를 보여주는 프로필 헤더.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // Column의 교차축(가로) 가운데 정렬로 이미지와 글자를 중앙에 모은다.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // 연보라 테두리 안에 비트맵 프로필 이미지를 원형으로 잘라 넣는다.
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryContainer,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/profile/profile_movielog.jpg',
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/movie.svg',
              width: 24,
              height: 24,
              semanticsLabel: '영화 아이콘',
            ),
            const SizedBox(width: 8),
            Text(
              '무비러버',
              style: AppTextStyles.titleLarge.copyWith(fontSize: 24),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋은 영화를 보고 기록하는 것을 좋아합니다.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            color: AppColors.title,
          ),
        ),
      ],
    );
  }
}
