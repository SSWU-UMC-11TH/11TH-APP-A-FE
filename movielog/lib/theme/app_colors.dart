import 'package:flutter/material.dart';

/// MovieLog의 모든 화면이 공유하는 색상 값.
///
/// 화면 Widget 안에 색상값을 직접 쓰지 않고 이 클래스를 통해 사용한다.
/// 디자인이 바뀌면 이 파일만 수정한다.
abstract final class AppColors {
  /// 기본 보라색. 버튼, 선택된 Chip, 강조 텍스트에 사용한다.
  static const Color primary = Color(0xFF5B3E8E);

  /// 선택되지 않은 Chip, 카드 테두리처럼 옅은 강조가 필요할 때 사용한다.
  static const Color primaryContainer = Color(0xFFEDE4F8);

  /// 앱 공통 크림색 배경
  static const Color background = Color(0xFFFBF8F3);

  /// 카드, 상세 화면처럼 배경 위에 올라가는 면
  static const Color surface = Color(0xFFFFFFFF);

  /// 통계 카드처럼 배경보다 살짝 보라빛이 도는 면
  static const Color surfaceTint = Color(0xFFF6F1FB);

  /// 제목 텍스트
  static const Color title = Color(0xFF1F1B24);

  /// 본문 텍스트
  static const Color body = Color(0xFF6B6572);

  /// 보조 라벨 텍스트
  static const Color label = Color(0xFF8A8491);

  /// 별점 아이콘
  static const Color star = Color(0xFFFFB400);

  /// 포스터 위 평점 Badge 배경
  static const Color badge = Color(0xCC2C2735);

  /// 오류 메시지, 오류 상태 입력창 테두리
  static const Color error = Color(0xFFD64545);

  /// 오류 상태 입력창 채움
  static const Color errorContainer = Color(0xFFFBE9E9);

  /// 입력창 기본 채움
  static const Color fieldFill = Color(0xFFF2EFEA);

  /// 입력창 기본 테두리
  static const Color fieldBorder = Color(0xFFD8D3DC);

  /// 조건을 아직 충족하지 못한 비활성 버튼 배경
  static const Color primaryDisabled = Color(0xFFC3BAE0);
}
