import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/create_member_request.dart';
import '../theme/app_colors.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/field_label.dart';
import '../widgets/movielog_button.dart';
import '../widgets/sign_up_footer.dart';
import '../widgets/sign_up_header.dart';
import '../widgets/terms_checkbox.dart';

/// 회원가입 화면 (W2-01 입력 전, W2-02 Validation 오류, W2-03 입력 완료).
///
/// 3주차에서 라우트 흐름만 담당하던 RegisterScreen을
/// 2주차 Required Mission에 맞춰 입력값을 검증하는 Form으로 교체했다.
///
/// 6주차부터 닉네임·이메일 옆에 중복 확인 버튼(W6-01)을 두고,
/// 서버 중복 여부는 [SignUpViewModel]의 상태를 errorText로 연결한다.
/// 형식 검사(validator)는 화면이, 중복 여부는 ViewModel이 담당한다.
///
/// 7주차부터 유효한 입력을 v6 회원가입 POST로 전송한다.
/// 성공하면 result.memberId를 [LearningMemberSession]에 저장하고 /movies로 이동한다.
/// 서버가 비밀번호 형식을 거부하면(400) 비밀번호 칸 errorText로,
/// 그 외 400·409(최종 중복)·통신 실패는 Snackbar로 안내한다.
/// 제출 중에는 버튼 중복 탭과 화면 이탈을 막는다.
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

  /// 서버 CreateMemberDto와 같은 규칙: 소문자·대문자·숫자·특수문자(!@#$%^&*) 각 1개 이상, 8자 이상.
  static final RegExp _passwordPattern = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*]).{8,}$',
  );

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
    if (nickname.length > 12) return '닉네임은 12자 이하여야 합니다.';
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
    // 비밀번호는 trim하지 않고 보내므로 앞뒤 공백은 여기서 명확히 막는다.
    if (password != password.trim()) return '비밀번호 앞뒤에는 공백을 넣을 수 없습니다.';
    if (!_passwordPattern.hasMatch(password)) {
      return '소문자·대문자·숫자·특수문자(!@#\$%^&*)를 모두 포함해야 합니다.';
    }
    return null;
  }

  /// 가입 버튼의 빠른 활성화 조건.
  ///
  /// 세 validator가 모두 통과하고, 닉네임·이메일이 서버에서 사용 가능으로 확인되고,
  /// 약관에 동의했을 때만 true가 된다.
  /// 최종 검증은 버튼을 누를 때 Form.validate()로 다시 실행한다.
  bool get canSubmit =>
      validateNickname(nicknameController.text) == null &&
      validateEmail(emailController.text) == null &&
      validatePassword(passwordController.text) == null &&
      context.read<SignUpViewModel>().isAllChecked &&
      !context.read<SignUpViewModel>().isSubmitting &&
      agreedToTerms;

  Future<void> submit() async {
    final bool isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    final SignUpViewModel viewModel = context.read<SignUpViewModel>();
    final String nickname = nicknameController.text.trim();
    await viewModel.submit(
      CreateMemberRequest(
        email: emailController.text,
        password: passwordController.text,
        nickname: nicknameController.text,
      ),
    );
    // 요청을 기다리는 동안 화면이 사라졌으면 결과를 반영하지 않는다.
    if (!mounted) return;

    final int? memberId = viewModel.createdMemberId;
    if (viewModel.submitStatus == SubmitStatus.success && memberId != null) {
      context.read<LearningMemberSession>().setMemberId(memberId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$nickname님, 가입이 완료되었습니다. (memberId $memberId)'),
        ),
      );
      // 가입 이후에는 돌아올 필요가 없으므로 push 대신 go로 이동한다.
      context.go('/movies');
      return;
    }

    final String? message = viewModel.snackbarMessage;
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
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

  /// 중복 확인이 필요한 입력창의 장식.
  ///
  /// 체크 표시는 서버가 사용 가능하다고 응답했을 때만 입력창 안에 보여준다.
  /// [errorText]는 validator가 통과한 뒤에도 남아 있으면 입력창을 에러 상태로 유지한다.
  /// 확인 중·사용 가능 안내는 helperText로 입력창 바로 아래에 보여준다.
  InputDecoration _checkDecoration({
    required String hint,
    required String fieldName,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required CheckStatus status,
    required String? errorText,
  }) {
    final bool locallyInvalid =
        controller.text.isNotEmpty && validator(controller.text) != null;

    final Widget? suffixIcon = switch (status) {
      _ when locallyInvalid => const Icon(
        Icons.error_outline,
        color: AppColors.error,
      ),
      CheckStatus.available => const Icon(
        Icons.check_circle,
        color: AppColors.primary,
      ),
      CheckStatus.duplicated || CheckStatus.error => const Icon(
        Icons.error_outline,
        color: AppColors.error,
      ),
      CheckStatus.idle || CheckStatus.checking => null,
    };

    final (String? helperText, Color helperColor) = switch (status) {
      CheckStatus.checking => ('$fieldName 사용 가능 여부를 확인 중입니다.', AppColors.info),
      CheckStatus.available => ('사용 가능한 $fieldName입니다.', AppColors.success),
      _ => (null, AppColors.label),
    };

    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      errorText: errorText,
      helperText: helperText,
      helperStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: helperColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 중복 확인 상태가 바뀌면 입력창 에러·버튼 상태를 함께 다시 그린다.
    final SignUpViewModel viewModel = context.watch<SignUpViewModel>();
    final bool isSubmitting = viewModel.isSubmitting;

    // 제출 중에는 뒤로가기·스와이프 백을 막고, 끝나면(성공·실패) 다시 나갈 수 있다.
    return PopScope(
      canPop: !isSubmitting,
      child: Scaffold(
        appBar: CommonAppBar(
          title: '회원가입',
          centerTitle: true,
          // 시작 화면에서 go로 넘어와 Navigator 스택이 없으므로 pop 대신 go를 사용한다.
          onBack: () {
            if (!isSubmitting) context.go('/start');
          },
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
                  _CheckFieldRow(
                    field: TextFormField(
                      controller: nicknameController,
                      enabled: !isSubmitting,
                      decoration: _checkDecoration(
                        hint: '닉네임을 입력해주세요',
                        fieldName: '닉네임',
                        controller: nicknameController,
                        validator: validateNickname,
                        status: viewModel.nicknameCheckStatus,
                        errorText: viewModel.nicknameErrorText,
                      ),
                      textInputAction: TextInputAction.next,
                      // 사용자가 한 번이라도 입력한 뒤부터는 입력할 때마다 검증한다.
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: validateNickname,
                      // suffixIcon과 가입 버튼은 setState로, 이전 중복 확인 결과의
                      // 무효화는 ViewModel의 onNicknameChanged로 처리한다.
                      onChanged: (String value) {
                        setState(() {});
                        viewModel.onNicknameChanged(value);
                      },
                      onFieldSubmitted: (_) => emailFocusNode.requestFocus(),
                    ),
                    // 입력창 옆 보조 버튼이므로 width를 주지 않아 내용 기반 크기를 쓴다.
                    button: MovieLogButton(
                      label: '중복 확인',
                      isLoading:
                          viewModel.nicknameCheckStatus == CheckStatus.checking,
                      // 형식이 맞지 않거나, 통신 중이거나, 중복으로 확인된 값이면 비활성이다.
                      onPressed:
                          !isSubmitting &&
                              viewModel.canCheckNickname &&
                              validateNickname(nicknameController.text) == null
                          ? () =>
                                viewModel.checkNickname(nicknameController.text)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const FieldLabel('이메일'),
                  _CheckFieldRow(
                    field: TextFormField(
                      controller: emailController,
                      enabled: !isSubmitting,
                      focusNode: emailFocusNode,
                      decoration: _checkDecoration(
                        hint: '이메일 주소를 입력해주세요',
                        fieldName: '이메일',
                        controller: emailController,
                        validator: validateEmail,
                        status: viewModel.emailCheckStatus,
                        errorText: viewModel.emailErrorText,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: validateEmail,
                      onChanged: (String value) {
                        setState(() {});
                        viewModel.onEmailChanged(value);
                      },
                      onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
                    ),
                    button: MovieLogButton(
                      label: '중복 확인',
                      isLoading:
                          viewModel.emailCheckStatus == CheckStatus.checking,
                      onPressed:
                          !isSubmitting &&
                              viewModel.canCheckEmail &&
                              validateEmail(emailController.text) == null
                          ? () => viewModel.checkEmail(emailController.text)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const FieldLabel('비밀번호'),
                  TextFormField(
                    controller: passwordController,
                    focusNode: passwordFocusNode,
                    enabled: !isSubmitting,
                    // 로컬 validator가 통과해도 서버가 거부한 값이면 errorText로 에러를 유지한다.
                    decoration: _decoration(
                      hint: '비밀번호를 입력해주세요',
                      controller: passwordController,
                      validator: validatePassword,
                    ).copyWith(errorText: viewModel.passwordErrorText),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: validatePassword,
                    onChanged: (_) {
                      setState(() {});
                      viewModel.onPasswordChanged();
                    },
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
                  // Form 하단 제출 버튼은 부모가 허용하는 최대 너비를 쓴다.
                  // onPressed가 null이면 버튼이 비활성화된다.
                  MovieLogButton(
                    label: '가입하기',
                    width: double.infinity,
                    isLoading: isSubmitting,
                    onPressed: canSubmit ? submit : null,
                  ),
                  const SizedBox(height: 24),
                  const SignUpFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 입력창과 중복 확인 버튼을 8px 간격의 형제로 나란히 둔다.
///
/// 입력창 아래에 에러·안내 문구가 생겨도 버튼은 입력창 높이에 맞춰 위쪽에 고정된다.
class _CheckFieldRow extends StatelessWidget {
  const _CheckFieldRow({required this.field, required this.button});

  final Widget field;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Row는 가로 너비를 정해 주지 않으므로 입력창은 Expanded로 남은 공간을 채운다.
        Expanded(child: field),
        const SizedBox(width: 8),
        button,
      ],
    );
  }
}
