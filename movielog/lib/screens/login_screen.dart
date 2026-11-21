import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/storage/saved_email_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/field_label.dart';
import '../widgets/movielog_button.dart';

/// 로그인 화면 (/login).
///
/// 버튼은 [AuthViewModel.login]만 호출하고 직접 `/home`으로 이동하지 않는다.
/// 성공해서 signedIn이 되면 Router의 redirect가 홈으로 보낸다.
///
/// - 로그인 실패(AUTH401_1)·저장 실패는 Form 아래 오류 문구로 보여준다.
/// - 세션 만료(AUTH401_2/3/4)로 이 화면에 왔을 때만 Snackbar로 한 번 안내한다.
/// - Challenge: "이메일 저장"을 켜면 이메일만 SharedPreferences에 저장한다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  late final AuthViewModel _auth;
  late final SavedEmailStore _emailStore;
  bool _rememberEmail = false;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    _emailStore = context.read<SavedEmailStore>();
    _auth.addListener(_showSessionExpired);
    // 이미 만료된 상태로 화면이 처음 열리는 경우도 첫 frame 뒤에 확인한다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSessionExpired());
    _restoreSavedEmail();
  }

  Future<void> _restoreSavedEmail() async {
    try {
      final String? saved = await _emailStore.readEmail();
      if (!mounted || saved == null || saved.isEmpty) return;
      // 사용자가 그 사이 직접 입력했다면 덮어쓰지 않는다.
      if (_email.text.isNotEmpty) return;
      setState(() {
        _email.text = saved;
        _rememberEmail = true;
      });
    } catch (_) {
      // 이메일 저장은 편의 기능이므로 읽기 실패는 조용히 무시한다.
    }
  }

  void _showSessionExpired() {
    if (!mounted || !_auth.sessionExpired) return;
    // 같은 Snackbar가 반복되지 않도록 먼저 끈다.
    _auth.consumeSessionExpired();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')));
  }

  @override
  void dispose() {
    _auth.removeListener(_showSessionExpired);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _persistEmailChoice(String email) async {
    try {
      if (_rememberEmail) {
        await _emailStore.saveEmail(email);
      } else {
        await _emailStore.clearEmail();
      }
    } catch (_) {
      // 이메일 저장 실패가 로그인 자체를 막지 않게 한다.
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final String email = _email.text.trim();
    // 비밀번호는 저장하지 않는다. 이메일 저장 여부만 반영한다.
    _persistEmailChoice(email);
    _auth.login(email, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final AuthViewModel auth = context.watch<AuthViewModel>();
    final bool loading = auth.status == AuthStatus.authenticating;
    final bool enabled = !loading && !auth.storageCleanupInProgress;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          '로그인',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 24),
                SvgPicture.asset(
                  'assets/logos/movielog_logo.svg',
                  width: 72,
                  height: 72,
                  semanticsLabel: 'MovieLog 로고',
                ),
                const SizedBox(height: 20),
                const Text(
                  'MovieLog에 로그인',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 40),
                const FieldLabel('이메일'),
                TextFormField(
                  controller: _email,
                  enabled: enabled,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: '이메일 주소를 입력해주세요'),
                  validator: (String? value) =>
                      (value?.trim().isEmpty ?? true) ? '이메일을 입력해 주세요.' : null,
                  onChanged: (_) => auth.clearMessage(),
                ),
                const SizedBox(height: 20),
                const FieldLabel('비밀번호'),
                TextFormField(
                  controller: _password,
                  enabled: enabled,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(hintText: '비밀번호를 입력해주세요'),
                  validator: (String? value) =>
                      (value?.isEmpty ?? true) ? '비밀번호를 입력해 주세요.' : null,
                  onChanged: (_) => auth.clearMessage(),
                  onFieldSubmitted: (_) {
                    if (enabled) _submit();
                  },
                ),
                if (auth.message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      auth.message!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                // Challenge: 이메일만 저장한다. 비밀번호·토큰은 저장하지 않는다.
                Row(
                  children: <Widget>[
                    Checkbox(
                      value: _rememberEmail,
                      onChanged: enabled
                          ? (bool? value) =>
                                setState(() => _rememberEmail = value ?? false)
                          : null,
                    ),
                    GestureDetector(
                      onTap: enabled
                          ? () =>
                                setState(() => _rememberEmail = !_rememberEmail)
                          : null,
                      child: const Text(
                        '이메일 저장',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                MovieLogButton(
                  label: '로그인',
                  width: double.infinity,
                  isLoading: loading,
                  onPressed: enabled ? _submit : null,
                ),
                const SizedBox(height: 16),
                TextButton(
                  // 회원가입에서 뒤로가면 로그인 화면으로 돌아오도록 push를 쓴다.
                  onPressed: enabled ? () => context.push('/register') : null,
                  child: const Text('아직 회원이 아니신가요? 회원가입'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
