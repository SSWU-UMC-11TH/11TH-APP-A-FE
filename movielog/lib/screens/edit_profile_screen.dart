import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../widgets/field_label.dart';
import '../widgets/movielog_button.dart';

/// 프로필 수정 화면 (/my/profile/edit).
///
/// 이메일은 읽기 전용, 닉네임만 PATCH me로 수정한다.
/// - 성공: AuthViewModel.member 교체 → Snackbar → 마이페이지로 pop
/// - 입력·중복 오류: 화면에 남아 필드 아래 오류 표시(입력값 유지)
/// - 401: 세션 정리 → Router가 /login으로 이동
/// - 네트워크 오류: Snackbar 안내, 로그아웃하지 않음
/// - Challenge: 변경 내용이 있는데 뒤로가면 확인 Dialog를 띄운다.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _controller;

  /// 저장 성공·나가기 확인 뒤에는 PopScope가 이동을 막지 않도록 연다.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    final String nickname =
        context.read<AuthViewModel>().member?.nickname ?? '';
    _controller = TextEditingController(text: nickname);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isDirty(String? currentNickname) =>
      _controller.text.trim() != (currentNickname ?? '');

  Future<void> _submit() async {
    final EditProfileViewModel viewModel = context.read<EditProfileViewModel>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final GoRouter router = GoRouter.of(context);
    FocusScope.of(context).unfocus();

    final bool success = await viewModel.save(_controller.text);
    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(const SnackBar(content: Text('프로필을 수정했어요.')));
      // 마이페이지로 돌아가면 새 닉네임이 이미 반영되어 있다.
      await _leave(router);
    } else if (viewModel.message != null) {
      messenger.showSnackBar(SnackBar(content: Text(viewModel.message!)));
    }
  }

  /// Challenge: 변경 내용이 있을 때 뒤로가기 확인. 나가기를 고르면 true.
  Future<bool> _confirmDiscard() async {
    final bool? leave = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('수정을 그만둘까요?'),
        content: const Text('변경한 내용이 저장되지 않아요.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('계속 수정'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _onBackPressed() async {
    final String? nickname = context.read<AuthViewModel>().member?.nickname;
    if (context.read<EditProfileViewModel>().isSaving) return;
    final GoRouter router = GoRouter.of(context);
    if (_isDirty(nickname) && !await _confirmDiscard()) return;
    if (!mounted) return;
    await _leave(router);
  }

  /// PopScope를 연 상태로 한 frame 다시 그린 뒤 마이페이지로 돌아간다.
  Future<void> _leave(GoRouter router) async {
    setState(() => _leaving = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    router.canPop() ? router.pop() : router.go('/my');
  }

  @override
  Widget build(BuildContext context) {
    final String? email = context.select<AuthViewModel, String?>(
      (AuthViewModel auth) => auth.member?.email,
    );
    final String? nickname = context.select<AuthViewModel, String?>(
      (AuthViewModel auth) => auth.member?.nickname,
    );

    return Consumer<EditProfileViewModel>(
      builder: (BuildContext context, EditProfileViewModel viewModel, _) {
        final bool saving = viewModel.isSaving;
        // 저장 중이거나 변경 내용이 있으면 시스템 뒤로가기를 가로채 확인한다.
        return PopScope(
          canPop: _leaving || (!saving && !_isDirty(nickname)),
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (didPop || saving) return;
            _onBackPressed();
          },
          child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Text(
                '프로필 수정',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: saving ? null : _onBackPressed,
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const FieldLabel('이메일'),
                    TextFormField(
                      // 이메일은 읽기 전용이다.
                      key: ValueKey<String?>(email),
                      initialValue: email,
                      enabled: false,
                    ),
                    const SizedBox(height: 20),
                    const FieldLabel('닉네임'),
                    TextField(
                      controller: _controller,
                      enabled: !saving,
                      maxLength: 12,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: '닉네임을 입력해주세요',
                        errorText: viewModel.nicknameError,
                      ),
                      onChanged: (_) {
                        setState(() {}); // 변경 여부(dirty)를 다시 계산한다.
                        viewModel.onNicknameChanged();
                      },
                      onSubmitted: (_) {
                        if (!saving) _submit();
                      },
                    ),
                    const Spacer(),
                    MovieLogButton(
                      label: '저장',
                      width: double.infinity,
                      isLoading: saving,
                      onPressed: saving ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
