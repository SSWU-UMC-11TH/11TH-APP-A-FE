import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/movielog_button.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyRatingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('내가 등록한 평점'),
        centerTitle: true,
        foregroundColor: AppColors.violet,
      ),
      body: switch (vm.status) {
        MyRatingsStatus.idle || MyRatingsStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        MyRatingsStatus.empty => const Center(child: Text('등록한 평점이 없습니다.')),
        MyRatingsStatus.error => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vm.errorMessage ?? '평점을 불러오지 못했습니다.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                MovieLogButton(label: '다시 시도', onPressed: () => vm.load()),
              ],
            ),
          ),
        ),
        MyRatingsStatus.success => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (vm.movieWarning != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(vm.movieWarning!),
              ),
            ...vm.ratings.map((rating) {
              final movie = vm.moviesById[rating.movieId];
              final poster = movie?.posterUrl;
              final comment = rating.comment;
              final date = rating.createdAt
                  .toLocal()
                  .toIso8601String()
                  .split('T')
                  .first;
              final placeholder = Container(
                width: 76,
                height: 114,
                color: AppColors.violet.withValues(alpha: 0.12),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.movie_outlined,
                  color: AppColors.violet,
                ),
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.violet.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: poster == null
                          ? placeholder
                          : Image.network(
                              poster,
                              width: 76,
                              height: 114,
                              fit: BoxFit.cover,
                              errorBuilder: (_, error, stackTrace) =>
                                  placeholder,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie?.title ?? '영화 #${rating.movieId}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '별점 ${rating.score} / 5',
                            style: const TextStyle(
                              color: AppColors.violet,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            comment == null || comment.trim().isEmpty
                                ? '작성한 후기가 없습니다.'
                                : comment,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            date,
                            style: const TextStyle(
                              color: AppColors.gray,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      },
    );
  }
}
