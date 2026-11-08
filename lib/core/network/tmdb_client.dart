import 'package:dio/dio.dart';

Dio createTmdbClient(String accessToken) => Dio(
  BaseOptions(
    baseUrl: 'https://api.themoviedb.org/3',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
    },
  ),
);
