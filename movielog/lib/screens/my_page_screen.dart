import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../widgets/profile_stat_card.dart';

/// 마이페이지. 프로필과 Mock 통계, 선호 장르를 보여준다.
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  static const List<String> _favoriteGenres = <String>['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: <Widget>[
          const Text(
            '내 프로필',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer,
              ),
              child: const CircleAvatar(
                radius: 52,
                backgroundImage:
                    AssetImage('assets/images/profile/profile_movielog.jpg'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '무비러버',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            '매주 주말엔 영화관으로 출근하는 프로 관람객.\n좋은 영화를 보고 기록하는 것을 좋아합니다.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 160,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('프로필 수정은 다음 주차에 연결할 예정이에요.')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('프로필 수정'),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Row(
            children: <Widget>[
              Expanded(child: ProfileStatCard(label: '본 영화', value: '342')),
              SizedBox(width: 12),
              Expanded(child: ProfileStatCard(label: '평점', value: '4.2')),
              SizedBox(width: 12),
              Expanded(child: ProfileStatCard(label: '즐겨찾기', value: '58')),
            ],
          ),
          const SizedBox(height: 28),
          Text('선호하는 장르', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (final String genre in _favoriteGenres)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // Query Parameter로 장르를 전달하며 목록 화면으로 이동한다.
                  onTap: () => context.go('/movies?genre=$genre'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      genre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
