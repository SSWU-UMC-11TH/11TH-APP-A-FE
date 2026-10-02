import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/field_label.dart';
import '../widgets/sign_up_footer.dart';
import '../widgets/sign_up_header.dart';
import '../widgets/terms_checkbox.dart';

/// 회원가입 화면 (W2-01 입력 전, W2-02 Validation 오류, W2-03 입력 완료).
///
/// 3주차에서 라우트 흐름만 담당하던 RegisterScreen을
/// 2주차 Required Mission에 맞춰 입력값을 검증하는 Form으로 교체했다.
/// 실제 API는 연결하지 않고 화면 내부 상태만 사용한다.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  /// Form 전체의 validate()를 호출하기 위한 Key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Controller와 FocusNode는 build가 아닌 State 필드로 두어야
  // 화면이 다시 그려져도 입력값과 Focus가 유지된다.
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  bool agreedToTerms = false;

  /// `아이디@도메인.최상위도메인` 형태만 허용한다.
  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  @override
  void dispose() {
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  // validator는 통과하면 null, 실패하면 보여줄 오류 메시지를 반환한다.

  String? validateNickname(String? value) {
    final String nickname = value?.trim() ?? '';
    if (nickname.isEmpty) return '닉네임을 입력해주세요.';
    if (nickname.length < 2) return '닉네임은 2자 이상이어야 합니다.';
    return null;
  }

  String? validateEmail(String? value) {
    final String email = value?.trim() ?? '';
    if (email.isEmpty) return '이메일을 입력해주세요.';
    if (!_emailPattern.hasMatch(email)) return '올바른 이메일 형식이 아닙니다.';
    return null;
  }

  String? validatePassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) return '비밀번호를 입력해주세요.';
    if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    return null;
  }

  /// 가입 버튼의 빠른 활성화 조건.
  ///
  /// 세 validator가 모두 통과하고 약관에 동의했을 때만 true가 된다.
  /// 최종 검증은 버튼을 누를 때 Form.validate()로 다시 실행한다.
  bool get canSubmit =>
      validateNickname(nicknameController.text) == null &&
      validateEmail(emailController.text) == null &&
      validatePassword(passwordController.text) == null &&
      agreedToTerms;

  void submit() {
    final bool isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${nicknameController.text.trim()}님, 가입이 완료되었습니다.'),
      ),
    );
    // 가입 이후에는 돌아올 필요가 없으므로 push 대신 go로 홈으로 이동한다.
    context.go('/home');
  }

  /// 입력값 상태에 따라 입력창 오른쪽 아이콘을 정한다.
  ///
  /// 비어 있으면 아이콘 없음, validator 통과면 보라색 체크, 실패면 빨간 느낌표.
  Widget? _suffixIcon(String text, String? Function(String?) validator) {
    if (text.isEmpty) return null;
    if (validator(text) == null) {
      return const Icon(Icons.check_circle, color: AppColors.primary);
    }
    return const Icon(Icons.error_outline, color: AppColors.error);
  }

  /// 입력창 모양은 AppTheme.inputDecorationTheme가 담당하므로
  /// 화면마다 달라지는 hint와 suffixIcon만 지정한다.
  InputDecoration _decoration({
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: _suffixIcon(controller.text, validator),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '회원가입',
        centerTitle: true,
        // 시작 화면에서 go로 넘어와 Navigator 스택이 없으므로 pop 대신 go를 사용한다.
        onBack: () => context.go('/start'),
      ),
      body: SafeArea(
        // Column 전체를 스크롤 가능하게 만들어 키보드가 열려도 Overflow가 나지 않는다.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          // 드래그로 스크롤하면 키보드를 닫는다.
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SignUpHeader(),
                const SizedBox(height: 40),
                const FieldLabel('닉네임'),
                TextFormField(
                  controller: nicknameController,
                  decoration: _decoration(
                    hint: '닉네임을 입력해주세요',
                    controller: nicknameController,
                    validator: validateNickname,
                  ),
                  textInputAction: TextInputAction.next,
                  // 사용자가 한 번이라도 입력한 뒤부터는 입력할 때마다 검증한다.
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: validateNickname,
                  // Controller와 입력창은 자동 동기화되지만
                  // 버튼 상태와 suffixIcon을 다시 그리려면 setState가 필요하다.
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => emailFocusNode.requestFocus(),
                ),
                const SizedBox(height: 20),
                const FieldLabel('이메일'),
                TextFormField(
                  controller: emailController,
                  focusNode: emailFocusNode,
                  decoration: _decoration(
                    hint: '이메일 주소를 입력해주세요',
                    controller: emailController,
                    validator: validateEmail,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: validateEmail,
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
                ),
                const SizedBox(height: 20),
                const FieldLabel('비밀번호'),
                TextFormField(
                  controller: passwordController,
                  focusNode: passwordFocusNode,
                  decoration: _decoration(
                    hint: '비밀번호를 입력해주세요',
                    controller: passwordController,
                    validator: validatePassword,
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: validatePassword,
                  onChanged: (_) => setState(() {}),
                  // 키보드의 완료 버튼은 조건을 충족했을 때만 가입 버튼과 같게 동작한다.
                  onFieldSubmitted: (_) {
                    if (canSubmit) submit();
                  },
                ),
                const SizedBox(height: 48),
                TermsCheckbox(
                  value: agreedToTerms,
                  onChanged: (bool value) {
                    setState(() {
                      agreedToTerms = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  // onPressed가 null이면 버튼이 비활성화된다.
                  onPressed: canSubmit ? submit : null,
                  child: const Text('가입하기'),
                ),
                const SizedBox(height: 24),
                const SignUpFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
