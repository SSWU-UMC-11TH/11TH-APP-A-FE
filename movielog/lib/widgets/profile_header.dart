import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/models/member_info.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 프로필 이미지, 닉네임, 가입일, 이메일을 보여주는 프로필 헤더.
///
/// 8주차부터 닉네임·이메일·가입일은 GET me 응답([MemberInfo])을 쓴다.
/// 프로필 사진은 v7 응답에 없으므로 기존 디자인 예시 이미지를 유지한다.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.member});

  final MemberInfo member;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
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
            Flexible(
              child: Text(
                member.nickname,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleLarge.copyWith(fontSize: 24),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Challenge: 닉네임 아래 가입일을 "2026.10.10 가입" 형식으로 표시한다.
        Text(
          member.joinedLabel,
          style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          member.email,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.title),
        ),
      ],
    );
  }
}
