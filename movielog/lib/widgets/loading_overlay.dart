import 'package:flutter/material.dart';

/// [child] 위에 어두운 ModalBarrier와 중앙 흰색 인디케이터만 올린다 (W7-05).
///
/// 흰색 카드나 로딩 문구는 띄우지 않는다. 화면 이탈 방지는 바깥의 PopScope가 맡는다.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        child,
        if (isLoading)
          const ModalBarrier(dismissible: false, color: Colors.black45),
        if (isLoading)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      ],
    );
  }
}
