import 'package:flutter/material.dart';

// TODO: 영화 상세 구현 전까지 사용하는 임시 화면
class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final String? movieId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('영화 상세: $movieId')));
  }
}
