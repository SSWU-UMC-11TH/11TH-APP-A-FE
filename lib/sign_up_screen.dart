import 'package:flutter/material.dart';

import 'common_app_bar.dart';
import 'theme/app_text_styles.dart';

final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
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

  bool get _canSubmit =>
      _nicknameController.text.trim().length >= 2 &&
      _emailRegExp.hasMatch(_emailController.text.trim()) &&
      _passwordController.text.length >= 8 &&
      _agreedToTerms;

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('가입이 완료되었습니다.')));
  }

  String? _validateNickname(String? value) {
    final nickname = value?.trim() ?? '';
    if (nickname.isEmpty) return '닉네임을 입력해주세요.';
    if (nickname.length < 2) return '닉네임은 2자 이상이어야 합니다.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return '이메일을 입력해주세요.';
    if (!_emailRegExp.hasMatch(email)) return '올바른 이메일 형식이 아닙니다.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return '비밀번호를 입력해주세요.';
    if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '회원가입', centerTitle: true, onBack: () {}),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SignUpHeader(),
                const SizedBox(height: 40),
                _LabeledTextField(
                  label: '닉네임',
                  hintText: '닉네임을 입력해주세요',
                  controller: _nicknameController,
                  textInputAction: TextInputAction.next,
                  validator: _validateNickname,
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                ),
                const SizedBox(height: 16),
                _LabeledTextField(
                  label: '이메일',
                  hintText: '이메일 주소를 입력해주세요',
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                ),
                const SizedBox(height: 16),
                _LabeledTextField(
                  label: '비밀번호',
                  hintText: '비밀번호를 입력해주세요',
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: _validatePassword,
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                ),
                const SizedBox(height: 32),
                _TermsCheckbox(
                  value: _agreedToTerms,
                  onChanged: (value) => setState(() => _agreedToTerms = value),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text('가입하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
      textAlign: TextAlign.center,
      style: AppTextStyles.bodySmall,
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.validator,
    required this.onChanged,
    required this.onFieldSubmitted,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onFieldSubmitted;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(hintText: hintText),
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
        ),
      ],
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (checked) => onChanged(checked ?? false),
        ),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: const Text('필수 약관에 동의합니다', style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }
}
