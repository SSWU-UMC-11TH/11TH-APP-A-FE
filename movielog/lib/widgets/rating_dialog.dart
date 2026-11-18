import 'package:flutter/material.dart';

import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';
import '../theme/app_colors.dart';
import 'movie_rating_input.dart';
import 'movielog_button.dart';

/// 별점과 코멘트를 입력해 저장하는 커스텀 Dialog (등록·수정 공용).
///
/// 저장 로직은 [onSubmit] 콜백으로 받아 Dialog 안에서 실행하고,
/// 저장 중 상태를 Dialog가 관리해 중복 탭과 이탈을 막는다.
///
/// - [onSubmit]이 예외 없이 끝나면 `true`를 돌려주며 닫힌다.
/// - 취소하면 [onSubmit]을 호출하지 않고 `false`를 돌려준다(API 요청 없음).
/// - [onSubmit]이 예외를 던지면 닫히지 않고, 입력을 유지한 채 오류 문구를 보여준다.
///
/// 저장 중 바깥 탭까지 막으려면 호출부의 showDialog에 `barrierDismissible: false`를 함께 준다.
class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.initialScore = 0,
    this.initialComment,
    this.title = '영화는 어떠셨나요?',
    required this.onSubmit,
  });

  /// 수정할 때 기존 별점. 0이면 아직 선택하지 않은 상태다.
  final int initialScore;

  /// 수정할 때 기존 코멘트. null이면 TextField가 빈 칸으로 시작한다.
  final String? initialComment;

  final String title;

  /// 빈 코멘트는 null로 바꿔 전달한다.
  final Future<void> Function(int score, String? comment) onSubmit;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _score = widget.initialScore;

  // build 안에서 만들면 setState마다 다시 만들어져 입력하던 코멘트가 사라진다.
  late final TextEditingController _commentController = TextEditingController(
    text: widget.initialComment ?? '',
  );
  bool _isSubmitting = false;
  String? _errorText;

  static const String _fallbackErrorText = '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    final String trimmed = _commentController.text.trim();
    if (trimmed.length > maxCommentLength) {
      setState(() => _errorText = '코멘트는 $maxCommentLength자 이하로 입력해 주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await widget.onSubmit(_score, trimmed.isEmpty ? null : trimmed);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      // 실패해도 _isSubmitting을 되돌려야 다시 시도할 수 있다. 입력값은 그대로 둔다.
      setState(() {
        _isSubmitting = false;
        _errorText = error is RatingWriteException
            ? error.message
            : _fallbackErrorText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 시스템 뒤로가기·스와이프로 닫히는 것을 저장 중에는 막는다.
    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.title,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _score == 0 ? '별을 눌러 평점을 남겨주세요' : '$_score점',
                style: const TextStyle(fontSize: 14, color: AppColors.body),
              ),
              const SizedBox(height: 20),
              MovieRatingInput(
                rating: _score.toDouble(),
                enabled: !_isSubmitting,
                onChanged: (double value) {
                  setState(() => _score = validateServerScore(value));
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                minLines: 3,
                maxLines: 3,
                maxLength: maxCommentLength,
                enabled: !_isSubmitting,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(hintText: '코멘트를 남겨보세요 (선택)'),
              ),
              if (_errorText != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    // 별점을 고르기 전에는 코멘트를 입력했더라도 누를 수 없다.
                    // 저장 중에는 회색 배경과 인디케이터로 바뀌고 다시 눌리지 않는다.
                    child: MovieLogButton(
                      label: '확인',
                      width: double.infinity,
                      isLoading: _isSubmitting,
                      onPressed: _score > 0 && !_isSubmitting
                          ? _onConfirm
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
