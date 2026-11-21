import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/services/member_api_service.dart';
import 'auth_view_model.dart';

enum EditProfileStatus { idle, saving, success, failure }

/// 프로필 수정 화면(닉네임 PATCH me)의 저장 상태.
///
/// 입력칸 문제(길이·중복)는 [nicknameError]로 필드 아래에,
/// 입력과 무관한 문제(네트워크 등)는 [message]로 Snackbar에 보여준다.
/// 네트워크 실패로는 로그아웃하지 않고, AUTH401_2/3/4만 세션을 정리한다.
class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this._memberApi, this._auth);

  final MemberApiService _memberApi;
  final AuthViewModel _auth;

  EditProfileStatus status = EditProfileStatus.idle;
  String? nicknameError;
  String? message;
  bool _disposed = false;

  bool get isSaving => status == EditProfileStatus.saving;

  /// 서버 MemberUpdateRequestDto와 같은 2~12자 규칙을 요청 전에 검사한다.
  static String? validateNickname(String value) {
    final nickname = value.trim();
    if (nickname.isEmpty) return '닉네임을 입력해 주세요.';
    if (nickname.length < 2 || nickname.length > 12) {
      return '닉네임은 2~12자로 입력해 주세요.';
    }
    return null;
  }

  /// 입력을 고치면 이전 필드 오류를 지운다. 입력값 자체는 화면의 Controller가 유지한다.
  void onNicknameChanged() {
    if (nicknameError == null) return;
    nicknameError = null;
    _notify();
  }

  /// 성공하면 true. 실패·세션 만료·화면 이탈 뒤 도착한 응답은 false다.
  Future<bool> save(String input) async {
    if (isSaving) return false; // 중복 탭 방지

    final version = _auth.sessionVersion;
    final current = _auth.member;
    if (_disposed || _auth.status != AuthStatus.signedIn || current == null) {
      return false;
    }
    final nickname = input.trim();
    nicknameError = validateNickname(nickname);
    message = null;
    if (nicknameError != null) {
      status = EditProfileStatus.failure;
      _notify();
      return false;
    }

    // 자기 자신의 현재 닉네임은 409가 아니지만 보낼 이유도 없으므로 요청 없이 완료한다.
    if (nickname == current.nickname) {
      status = EditProfileStatus.success;
      _notify();
      return true;
    }

    status = EditProfileStatus.saving;
    _notify();

    bool isStale() =>
        _disposed ||
        version != _auth.sessionVersion ||
        _auth.status != AuthStatus.signedIn;

    try {
      final updated = await _memberApi.updateNickname(nickname);
      if (isStale()) return false;
      _auth.updateMember(updated); // 마이페이지가 바로 새 닉네임을 보여준다.
      status = EditProfileStatus.success;
      _notify();
      return true;
    } on DioException catch (error) {
      if (isStale()) return false;
      status = EditProfileStatus.failure;
      final code = apiErrorCode(error);
      switch (code) {
        case 'AUTH401_2' || 'AUTH401_3' || 'AUTH401_4':
          // 안내와 이동은 로그인 화면과 Router가 처리한다.
          await _auth.expireSession(version: version);
        case 'MEMBER409_1':
          nicknameError = '이미 사용 중인 닉네임이에요.'; // 입력값은 유지
        case 'COMMON400':
          nicknameError = apiErrorMessage(error) ?? '닉네임 형식을 확인해 주세요.';
        case 'MEMBER404_1':
          message = '회원 정보를 찾을 수 없어요.';
        default:
          message = '네트워크 상태를 확인하고 다시 시도해 주세요.'; // 로그아웃하지 않음
      }
    } catch (_) {
      if (isStale()) return false;
      status = EditProfileStatus.failure;
      message = '알 수 없는 오류가 발생했어요.';
    }
    _notify();
    return false;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
