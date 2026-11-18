import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/create_member_request.dart';
import '../data/services/sign_up_service.dart';
import 'submit_status.dart';

export 'submit_status.dart';

/// 중복 확인 한 칸의 상태. 버튼 활성화와 Form 에러가 모두 이 값에서 파생된다.
///
/// - idle: 아직 확인하지 않았거나, 입력이 바뀌어 이전 결과가 무효화됨
/// - checking: 요청 진행 중
/// - available: 서버가 사용 가능하다고 응답함
/// - duplicated: 서버가 이미 사용 중이라고 응답함(`available: false`)
/// - error: 통신 자체가 실패함(DioException)
enum CheckStatus { idle, checking, available, duplicated, error }

/// 회원가입 화면의 닉네임·이메일 중복 확인 상태와 가입 제출 상태.
///
/// 형식 검사는 화면의 validator가, 서버 중복 여부와 가입 결과는 이 ViewModel이 담당한다.
/// 두 입력란의 결과가 서로 영향을 주지 않도록 필드마다 상태를 따로 둔다.
class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);

  final SignUpService _service;

  final _DuplicateCheck _nickname = _DuplicateCheck('이미 사용 중인 닉네임입니다.');
  final _DuplicateCheck _email = _DuplicateCheck('이미 사용 중인 이메일입니다.');
  bool _disposed = false;

  static const String networkErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
  static const String contractErrorText =
      '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';

  /// 가입 요청 한 번의 진행 상태.
  SubmitStatus submitStatus = SubmitStatus.idle;

  /// 가입 성공 응답에서 읽은 실제 memberId. 성공 전에는 null.
  int? createdMemberId;

  /// 서버가 비밀번호 형식을 거부한 400. 비밀번호 입력칸 errorText에 붙인다.
  String? passwordErrorText;

  /// 어느 입력칸에도 붙일 수 없는 실패(409 중복, 그 밖의 400, 통신 실패).
  /// 화면이 submit 직후 한 번만 꺼내 Snackbar로 보여준다.
  String? snackbarMessage;

  bool get isSubmitting => submitStatus == SubmitStatus.submitting;

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

  /// 비밀번호를 고치면 서버가 거부했던 이전 결과를 지운다.
  void onPasswordChanged() {
    if (passwordErrorText == null && submitStatus != SubmitStatus.error) return;
    passwordErrorText = null;
    _clearSubmitError();
    if (!_disposed) notifyListeners();
  }

  /// 회원가입 POST. 중복 탭은 무시한다.
  ///
  /// 400 중 비밀번호 형식 오류만 [passwordErrorText]로, 그 외 400·409·통신 실패는
  /// [snackbarMessage]로 나눠 담는다. 409는 중복된 칸의 확인 결과도 되돌린다.
  Future<void> submit(CreateMemberRequest request) async {
    if (submitStatus == SubmitStatus.submitting) return;
    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();

    try {
      final response = await _service.signUp(request);
      if (_disposed) return;
      final id = response.result?.memberId;
      // memberId가 없으면 가입 완료로 표시하지 않고 계약 오류로 처리한다.
      if (id == null) throw StateError('회원가입 결과에 memberId가 없습니다.');
      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      final message = writeSignUpErrorMessage(error);
      final status = error.response?.statusCode;
      if (status == 400 && message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
        if (status == 409) _applyFinalDuplicate(message, request);
      }
    } on StateError {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      snackbarMessage = contractErrorText;
    } on TypeError {
      // 201인데 body가 공통 형식이 아닌 경우도 계약 오류다.
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      snackbarMessage = contractErrorText;
    }
    if (!_disposed) notifyListeners();
  }

  /// 중복 확인 직후 다른 사용자가 같은 값을 등록하면 POST가 409로 끝난다.
  ///
  /// 서버는 이메일을 먼저 검사하므로 message에 담긴 칸 하나만 duplicated로 되돌린다.
  /// 그러면 가입 버튼이 다시 잠기고, 값을 바꾸면 기존 무효화 규칙이 그대로 적용된다.
  void _applyFinalDuplicate(String message, CreateMemberRequest request) {
    if (message.contains('이메일')) {
      _email.markDuplicated(request.email.trim(), message);
    } else if (message.contains('닉네임')) {
      _nickname.markDuplicated(request.nickname.trim(), message);
    }
  }

  void _clearSubmitError() {
    if (submitStatus == SubmitStatus.error) submitStatus = SubmitStatus.idle;
    snackbarMessage = null;
  }

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
    // 값이 바뀌면 이전 가입 시도의 서버 오류도 함께 무효화한다.
    _clearSubmitError();
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

  /// 서버가 최종 가입 단계(409)에서 중복이라고 알린 값을 기억한다.
  void markDuplicated(String value, String message) {
    if (value != current) return;
    version++;
    status = CheckStatus.duplicated;
    errorText = message;
    duplicatedValue = value;
  }

  /// 통신 중이거나 중복으로 확인된 값이면 값을 바꾸기 전까지 다시 누를 수 없다.
  bool get canCheck =>
      status != CheckStatus.checking && status != CheckStatus.duplicated;
}
