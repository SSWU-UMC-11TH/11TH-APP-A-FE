import 'package:dio/dio.dart';

import '../models/check_result.dart';

class MemberCheckService {
  MemberCheckService(this._dio);
  final Dio _dio;

  Future<bool> checkNickname(String nickname) async {
    final value = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get<dynamic>('/v5/members/nickname/$value');
    return CheckResult.fromJson(Map<String, dynamic>.from(response.data as Map))
        .available;
  }

  Future<bool> checkEmail(String email) async {
    final value = Uri.encodeComponent(email.trim());
    final response = await _dio.get<dynamic>('/v5/members/email/$value');
    return CheckResult.fromJson(Map<String, dynamic>.from(response.data as Map))
        .available;
  }
}
