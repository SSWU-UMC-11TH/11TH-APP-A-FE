import 'package:flutter/material.dart';

import '../data/services/rating_api_service.dart';
import '../theme/app_colors.dart';
import 'movielog_button.dart';

/// 평점 하나를 삭제하기 전에 확인하는 Dialog (W7-04).
///
/// 삭제는 되돌릴 수 없으므로 확인 없이 바로 실행하지 않는다.
/// - 취소: [onConfirm]을 호출하지 않고 `false`로 닫힌다(삭제 요청 없음).
/// - 삭제: 요청이 끝날 때까지 Dialog를 유지하고, 성공하면 `true`로 닫힌다.
/// - 실패: Dialog를 유지한 채 Snackbar로 서버 message를 안내해 다시 시도할 수 있게 둔다.
class DeleteRatingDialog extends StatefulWidget {
  const DeleteRatingDialog({super.key, required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  State<DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<DeleteRatingDialog> {
  bool _isDeleting = false;

  Future<void> _onConfirm() async {
    setState(() => _isDeleting = true);
    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is RatingWriteException
                ? error.message
                : '삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: ConfirmDeleteDialogFrame(
        title: '평점을 삭제할까요?',
        onCancel: _isDeleting ? null : () => Navigator.pop(context, false),
        confirmButton: MovieLogButton(
          label: '삭제',
          width: double.infinity,
          isLoading: _isDeleting,
          onPressed: _isDeleting ? null : _onConfirm,
        ),
      ),
    );
  }
}

/// 단일·다중 삭제 확인 Dialog가 함께 쓰는 모양.
class ConfirmDeleteDialogFrame extends StatelessWidget {
  const ConfirmDeleteDialogFrame({
    super.key,
    required this.title,
    required this.onCancel,
    required this.confirmButton,
  });

  final String title;
  final VoidCallback? onCancel;
  final Widget confirmButton;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.delete_outline, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '삭제한 평점은 복구할 수 없습니다.',
              style: TextStyle(fontSize: 14, color: AppColors.body),
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: onCancel,
                      child: const Text('취소'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: confirmButton),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
