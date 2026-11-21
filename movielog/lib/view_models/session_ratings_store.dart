import 'package:flutter/foundation.dart';

import '../data/models/rating_dto.dart';
import 'auth_view_model.dart';

/// 현재 로그인 세션에서 등록한 평점(등록 response의 Rating 객체)을 보관한다.
///
/// v7에는 토큰 기반 "내 평점 목록 GET"이 없고, 로그인·내 정보 응답에도 memberId가 없다.
/// 그래서 앱을 재시작하거나 다시 로그인하면 기존 내 평점 전체를 복원할 수 없다.
/// 이 저장소는 그 한계 안에서 "이번 세션에 만든 평점"만 수정·삭제할 수 있게 한다.
///
/// [AuthViewModel.sessionVersion]이 바뀌면(로그인·로그아웃·만료·회원 전환) 목록을 비우고,
/// 이전 세션 버전으로 들어온 쓰기 결과는 무시한다.
class SessionRatingsStore extends ChangeNotifier {
  SessionRatingsStore(this._auth) : _version = _auth.sessionVersion {
    _auth.addListener(_onAuthChanged);
  }

  final AuthViewModel _auth;
  int _version;

  /// ratingId 기준으로 한 건씩 보관한다. 최근 등록한 평점이 위에 오도록 역순으로 꺼낸다.
  final Map<int, RatingDto> _ratings = {};

  List<RatingDto> get ratings => _ratings.values.toList().reversed.toList();

  void _onAuthChanged() {
    if (_auth.sessionVersion == _version) return;
    _version = _auth.sessionVersion;
    if (_ratings.isEmpty) return;
    _ratings.clear();
    notifyListeners();
  }

  /// 등록·수정 response의 Rating으로 카드를 갱신한다.
  void upsert(int version, RatingDto rating) {
    if (version != _version) return;
    _ratings[rating.ratingId] = rating;
    notifyListeners();
  }

  void remove(int version, int ratingId) {
    if (version != _version) return;
    if (_ratings.remove(ratingId) != null) notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
