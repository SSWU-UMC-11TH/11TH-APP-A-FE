import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/common_app_bar.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/signup_header.dart';
import '../widgets/signup_submit_button.dart';
import '../widgets/terms_checkbox.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _validateNickname(String? value) {
    final nickname = value?.trim() ?? '';

    if (nickname.isEmpty) {
      return '닉네임을 입력해주세요.';
    }

    if (nickname.length < 2) {
      return '닉네임은 2자 이상이어야 합니다.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return '이메일을 입력해주세요.';
    }

    if (!_emailPattern.hasMatch(email)) {
      return '올바른 이메일 형식이 아닙니다.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }

    if (password.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다.';
    }

    return null;
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    FocusScope.of(context).unfocus();
    // 가입 후에는 회원가입 화면으로 돌아오지 않도록 go로 이동
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        _nicknameController.text.trim().length >= 2 &&
        _emailPattern.hasMatch(_emailController.text.trim()) &&
        _passwordController.text.length >= 8 &&
        _agreedToTerms;

    // 회원가입 화면에서는 뒤로 가기를 막는다.
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: CommonAppBar(
          title: '회원가입',
          onBack: () => Navigator.maybePop(context),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
                            const SignUpHeader(),
                            const SizedBox(height: 32),
                            LabeledTextField(
                              label: '닉네임',
                              hintText: '닉네임을 입력해주세요',
                              controller: _nicknameController,
                              validator: _validateNickname,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => setState(() {}),
                              onFieldSubmitted: (_) =>
                                  _emailFocusNode.requestFocus(),
                            ),
                            const SizedBox(height: 16),
                            LabeledTextField(
                              label: '이메일',
                              hintText: '이메일 주소를 입력해주세요',
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => setState(() {}),
                              onFieldSubmitted: (_) =>
                                  _passwordFocusNode.requestFocus(),
                            ),
                            const SizedBox(height: 16),
                            LabeledTextField(
                              label: '비밀번호',
                              hintText: '비밀번호를 입력해주세요',
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              validator: _validatePassword,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => setState(() {}),
                              onFieldSubmitted: (_) =>
                                  _passwordFocusNode.unfocus(),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
                            TermsCheckbox(
                              value: _agreedToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreedToTerms = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            SignUpSubmitButton(
                              onPressed: canSubmit ? _submit : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
