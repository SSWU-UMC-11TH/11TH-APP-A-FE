import 'package:flutter/foundation.dart';

/// 7주차 학습용 "현재 회원" 상태.
///
/// 회원가입 성공 응답의 memberId를 앱 상단에 보관하고,
/// 영화 상세·마이페이지 Route가 같은 값을 읽어 v6 평점 path에 넣는다.
///
/// memberId만 알고 있다는 사실은 인증이 아니다.
/// 메모리에만 있으므로 앱을 재시작하면 사라지고, JWT 주차에는
/// 보호 요청에서 memberId path를 제거하고 서버가 토큰으로 회원을 식별한다.
class LearningMemberSession extends ChangeNotifier {
  LearningMemberSession({this.memberId});

  int? memberId;

  void setMemberId(int id) {
    memberId = id;
    notifyListeners();
  }

  void clear() {
    memberId = null;
    notifyListeners();
  }
}
