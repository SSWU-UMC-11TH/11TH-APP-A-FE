import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ShareSheet extends StatelessWidget {
  const ShareSheet({super.key, required this.movieTitle});

  final String movieTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$movieTitle 공유하기', style: AppTextStyles.titleMedium),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.link, color: AppColors.violet),
            title: const Text('링크 복사'),
            onTap: () => Navigator.pop(context, '링크를 복사했습니다.'),
          ),
          ListTile(
            leading: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.violet,
            ),
            title: const Text('카카오톡으로 공유'),
            onTap: () => Navigator.pop(context, '카카오톡으로 공유했습니다.'),
          ),
          ListTile(
            leading: const Icon(Icons.more_horiz, color: AppColors.violet),
            title: const Text('더보기'),
            onTap: () => Navigator.pop(context, '다른 앱으로 공유했습니다.'),
          ),
        ],
      ),
    );
  }
}
