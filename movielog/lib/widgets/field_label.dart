import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// 입력창 위에 표시하는 굵은 라벨.
///
/// 시안은 InputDecoration의 labelText 대신 입력창 바깥에 라벨을 두므로
/// 세 입력창이 같은 모양을 쓰도록 작은 Widget으로 분리했다.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.titleMedium),
    );
  }
}
