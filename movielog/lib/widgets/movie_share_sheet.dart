import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 상세 화면에서 공유 방법을 고르는 BottomSheet.
///
/// 고른 항목의 이름을 `Navigator.pop`의 결과로 돌려준다.
class MovieShareSheet extends StatelessWidget {
  const MovieShareSheet({super.key, required this.movieTitle});

  final String movieTitle;

  static const List<_ShareOption> _options = <_ShareOption>[
    _ShareOption(icon: Icons.link, label: '링크 복사'),
    _ShareOption(icon: Icons.chat_bubble_outline, label: '메시지로 보내기'),
    _ShareOption(icon: Icons.bookmark_border, label: '보고 싶은 영화에 담기'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$movieTitle 공유하기',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final _ShareOption option in _options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(option.icon, color: AppColors.primary),
                title: Text(
                  option.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.title,
                  ),
                ),
                // Sheet를 먼저 닫고 결과를 돌려줘야 Snackbar가 가려지지 않는다.
                onTap: () => Navigator.pop(context, option.label),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShareOption {
  const _ShareOption({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
