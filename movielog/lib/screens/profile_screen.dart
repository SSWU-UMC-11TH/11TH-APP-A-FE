import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/member_info.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/edit_profile_button.dart';
import '../widgets/favorite_genres.dart';
import '../widgets/movielog_button.dart';
import '../widgets/my_ratings_entry.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats.dart';

/// 마이페이지 (/my).
///
/// 8주차: MainScreen이 불러온 GET me 결과(AuthViewModel.member)를 구독해
/// 닉네임·이메일·가입일을 보여주고, 앱바 오른쪽에 로그아웃을 둔다.
/// Challenge: 내 정보를 불러오는 동안 화면 전체 인디케이터, 실패하면 다시 시도 버튼을 보여준다.
///
/// 통계·선호 장르는 기존 디자인 예시(Mock)다. v7 GET me 응답에는 없다.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthViewModel auth = context.watch<AuthViewModel>();
    final MemberInfo? member = auth.member;

    final Widget body;
    if (member != null) {
      body = ProfileBody(member: member);
    } else if (auth.memberStatus == MemberLoadStatus.error) {
      body = _MemberLoadError(onRetry: () => auth.loadMember(force: true));
    } else {
      body = const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Scaffold(
      appBar: CommonAppBar(
        title: '내 프로필',
        actions: <Widget>[
          TextButton(
            // 로그아웃하면 signedOut이 되고 Router가 /login으로 보낸다.
            onPressed: auth.storageCleanupInProgress ? null : auth.logout,
            child: const Text('로그아웃'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}

/// 프로필 화면의 본문. 헤더, 수정 버튼, 통계, 평점 진입 행, 선호 장르를 세로로 배치한다.
class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key, required this.member});

  final MemberInfo member;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ProfileHeader(member: member),
          const SizedBox(height: 24),
          const Center(child: EditProfileButton()),
          const SizedBox(height: 28),
          const ProfileStats(),
          const SizedBox(height: 24),
          const MyRatingsEntry(),
          const SizedBox(height: 28),
          const FavoriteGenres(),
        ],
      ),
    );
  }
}

class _MemberLoadError extends StatelessWidget {
  const _MemberLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text('내 정보를 불러오지 못했어요.', style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            const Text(
              '네트워크 상태를 확인하고 다시 시도해 주세요.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 20),
            MovieLogButton(label: '다시 시도', width: 140, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
