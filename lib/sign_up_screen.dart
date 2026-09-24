import 'package:flutter/material.dart';

import 'common_app_bar.dart';
import 'theme/app_text_styles.dart';

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
                const Text(
                  '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 40),
                const Text('닉네임', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(hintText: '닉네임을 입력해주세요'),
                  textInputAction: TextInputAction.next,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    final nickname = value?.trim() ?? '';
                    if (nickname.isEmpty) return '닉네임을 입력해주세요.';
                    if (nickname.length < 2) return '닉네임은 2자 이상이어야 합니다.';
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
