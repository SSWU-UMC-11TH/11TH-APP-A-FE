import 'common_response.dart';

/// `GET·PATCH /v7/members/me` 응답 result (MemberInfoResponseDto).
///
/// v7 내 정보에는 email·nickname·createdAt만 있고 memberId·password는 없다.
class MemberInfo {
  const MemberInfo({
    required this.email,
    required this.nickname,
    required this.createdAt,
  });

  final String email;
  final String nickname;
  final DateTime createdAt;

  factory MemberInfo.fromJson(Map<String, dynamic> json) {
    return MemberInfo(
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Challenge: 가입일을 기기 시간대 기준 `2026.10.10 가입` 형식으로 표시한다.
  String get joinedLabel {
    final local = createdAt.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}.$month.$day 가입';
  }
}

/// 공통 응답을 한 번 파싱하고 result의 [MemberInfo]만 꺼낸다.
MemberInfo parseMemberInfo(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw StateError('내 정보 응답 형식이 올바르지 않습니다.');
  }
  final common = CommonResponse<MemberInfo>.fromJson(
    data,
    (value) => MemberInfo.fromJson(value as Map<String, dynamic>),
  );
  final member = common.result;
  if (member == null) throw StateError('내 정보 result가 없습니다.');
  return member;
}
