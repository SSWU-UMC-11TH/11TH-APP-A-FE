import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/member_check_service.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

class _CheckField {
  String value = '';
  String? duplicatedValue;
  String? error;
  int version = 0;
  CheckStatus status = CheckStatus.idle;
}

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);

  final MemberCheckService _service;
  final _nickname = _CheckField();
  final _email = _CheckField();
  bool _disposed = false;

  CheckStatus get nicknameCheckStatus => _nickname.status;
  CheckStatus get emailCheckStatus => _email.status;
  String? get nicknameErrorText => _nickname.error;
  String? get emailErrorText => _email.error;

  bool get canCheckNickname =>
      _nickname.value.length >= 2 &&
      _nickname.value.length <= 12 &&
      _canCheck(_nickname);

  bool get canCheckEmail =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.value) &&
      _canCheck(_email);

  bool get bothAvailable =>
      _nickname.status == CheckStatus.available &&
      _email.status == CheckStatus.available;

  bool _canCheck(_CheckField field) =>
      field.status != CheckStatus.checking &&
      field.status != CheckStatus.duplicated;

  void onNicknameChanged(String value) => _change(_nickname, value, '닉네임');

  void onEmailChanged(String value) => _change(_email, value, '이메일');

  void _change(_CheckField field, String value, String label) {
    if (_disposed) return;
    field.value = value.trim();
    field.version++;
    final duplicated =
        field.duplicatedValue != null && field.value == field.duplicatedValue;

    field.status = duplicated ? CheckStatus.duplicated : CheckStatus.idle;
    field.error = duplicated ? '이미 사용 중인 $label입니다.' : null;
    notifyListeners();
  }

  Future<void> checkNickname(String value) async {
    if (!canCheckNickname) return;
    await _check(_nickname, value, '닉네임', _service.checkNickname);
  }

  Future<void> checkEmail(String value) async {
    if (!canCheckEmail) return;
    await _check(_email, value, '이메일', _service.checkEmail);
  }

  Future<void> _check(
    _CheckField field,
    String value,
    String label,
    Future<bool> Function(String) request,
  ) async {
    final requested = value.trim();
    if (_disposed || requested != field.value) return;

    final version = ++field.version;
    field.status = CheckStatus.checking;
    field.error = null;
    notifyListeners();

    bool isCurrent() =>
        !_disposed && version == field.version && requested == field.value;

    try {
      final available = await request(requested);
      if (!isCurrent()) return;

      field.status = available ? CheckStatus.available : CheckStatus.duplicated;
      field.error = available ? null : '이미 사용 중인 $label입니다.';
      if (!available) field.duplicatedValue = requested;
    } on DioException {
      if (!isCurrent()) return;
      field.status = CheckStatus.error;
      field.error = '통신에 실패했습니다. 다시 시도해 주세요.';
    } catch (_) {
      if (!isCurrent()) return;
      field.status = CheckStatus.error;
      field.error = '응답을 확인하지 못했습니다. 다시 시도해 주세요.';
    }

    if (isCurrent()) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nickname.version++;
    _email.version++;
    super.dispose();
  }
}
