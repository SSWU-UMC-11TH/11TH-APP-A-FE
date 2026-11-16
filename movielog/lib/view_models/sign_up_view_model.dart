import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/member_check_service.dart';

/// 중복 확인 한 칸의 상태. 버튼 활성화와 Form 에러가 모두 이 값에서 파생된다.
///
/// - idle: 아직 확인하지 않았거나, 입력이 바뀌어 이전 결과가 무효화됨
/// - checking: 요청 진행 중
/// - available: 서버가 사용 가능하다고 응답함
/// - duplicated: 서버가 이미 사용 중이라고 응답함(`available: false`)
/// - error: 통신 자체가 실패함(DioException)
enum CheckStatus { idle, checking, available, duplicated, error }

/// 회원가입 화면의 닉네임·이메일 중복 확인 상태.
///
/// 형식 검사는 화면의 validator가, 서버 중복 여부는 이 ViewModel이 담당한다.
/// 두 입력란의 결과가 서로 영향을 주지 않도록 필드마다 상태를 따로 둔다.
class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);

  final MemberCheckService _service;

  final _DuplicateCheck _nickname = _DuplicateCheck('이미 사용 중인 닉네임입니다.');
  final _DuplicateCheck _email = _DuplicateCheck('이미 사용 중인 이메일입니다.');
  bool _disposed = false;

  static const String networkErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';

  CheckStatus get nicknameCheckStatus => _nickname.status;
  String? get nicknameErrorText => _nickname.errorText;
  bool get canCheckNickname => _nickname.canCheck;

  CheckStatus get emailCheckStatus => _email.status;
  String? get emailErrorText => _email.errorText;
  bool get canCheckEmail => _email.canCheck;

  /// 가입 버튼은 두 값 모두 서버에서 사용 가능으로 확인된 뒤에만 활성화한다.
  bool get isAllChecked =>
      _nickname.status == CheckStatus.available &&
      _email.status == CheckStatus.available;

  void onNicknameChanged(String value) => _onChanged(_nickname, value);
  void onEmailChanged(String value) => _onChanged(_email, value);

  Future<void> checkNickname(String value) =>
      _check(_nickname, value, _service.checkNickname);

  Future<void> checkEmail(String value) =>
      _check(_email, value, _service.checkEmail);

  /// 입력이 바뀌면 이전 결과를 무효화한다.
  ///
  /// 마지막으로 "중복"이었던 값과 정확히 같으면 서버에 다시 묻지 않고
  /// 곧바로 duplicated로 되돌린다. 그 밖의 값은 idle로 돌아가 다시 확인할 수 있다.
  void _onChanged(_DuplicateCheck field, String value) {
    final trimmed = value.trim();
    field.current = trimmed;
    // 기다리던 이전 요청의 응답이 나중에 도착해도 무시되도록 버전을 올린다.
    field.version++;
    if (field.duplicatedValue != null && trimmed == field.duplicatedValue) {
      field.status = CheckStatus.duplicated;
      field.errorText = field.duplicatedMessage;
    } else {
      field.status = CheckStatus.idle;
      field.errorText = null;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> _check(
    _DuplicateCheck field,
    String value,
    Future<bool> Function(String) request,
  ) async {
    final requested = value.trim();
    if (requested.isEmpty || requested != field.current || !field.canCheck) {
      return;
    }

    final version = ++field.version;
    field.status = CheckStatus.checking;
    field.errorText = null;
    notifyListeners();

    // 응답을 기다리는 동안 입력이 바뀌었거나 화면을 떠났으면 결과를 버린다.
    bool isStale() =>
        _disposed || version != field.version || field.current != requested;

    try {
      final available = await request(requested);
      if (isStale()) return;
      if (available) {
        field.status = CheckStatus.available;
        field.errorText = null;
      } else {
        field.status = CheckStatus.duplicated;
        field.errorText = field.duplicatedMessage;
        // 같은 문자열을 다시 입력했을 때 재요청 없이 에러를 복원하려고 기억한다.
        field.duplicatedValue = requested;
      }
    } on DioException {
      if (isStale()) return;
      // 정상 응답의 available: false(중복)와 다른 문구로 구분한다.
      field.status = CheckStatus.error;
      field.errorText = networkErrorText;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nickname.version++;
    _email.version++;
    super.dispose();
  }
}

/// 입력란 하나의 중복 확인 상태를 묶어 둔다.
class _DuplicateCheck {
  _DuplicateCheck(this.duplicatedMessage);

  final String duplicatedMessage;

  CheckStatus status = CheckStatus.idle;
  String? errorText;

  /// 서버가 마지막으로 "중복"이라고 응답한 값. 마지막으로 확인한 값과는 별개로 기억한다.
  String? duplicatedValue;

  /// 현재 입력창에 들어 있는 값(trim 후).
  String current = '';

  /// 늦게 도착한 이전 요청의 결과를 무시하기 위한 요청 번호.
  int version = 0;

  /// 통신 중이거나 중복으로 확인된 값이면 값을 바꾸기 전까지 다시 누를 수 없다.
  bool get canCheck =>
      status != CheckStatus.checking && status != CheckStatus.duplicated;
}
