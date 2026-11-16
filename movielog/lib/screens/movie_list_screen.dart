import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/fake_movie_service.dart';
import '../services/genre_preference.dart';
import '../theme/app_colors.dart';
import '../widgets/genre_chip_list.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';

/// 영화 목록 화면.
///
/// Service가 돌려주는 `Future<List<Movie>>`를 `FutureBuilder`로 관찰해
/// Loading·Empty·Error·Success 상태를 나누어 보여주고,
/// 장르 Chip 선택값은 로컬에 저장해 다음 실행 때 복원한다.
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({
    super.key,
    this.initialGenre,
    this.movieService = const FakeMovieService(),
    this.initialLoadMode = MovieLoadMode.success,
  });

  /// Query Parameter로 전달받은 초기 장르. 저장된 장르보다 우선한다.
  final String? initialGenre;

  /// 영화 목록을 불러오는 Service.
  final FakeMovieService movieService;

  /// 화면에 처음 진입할 때 사용할 Mock 응답 모드.
  final MovieLoadMode initialLoadMode;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final GenrePreference _genrePreference = GenrePreference();

  /// build가 다시 실행돼도 같은 요청이 반복되지 않도록 Future는 필드에 보관한다.
  late Future<List<Movie>> _moviesFuture;

  String _selectedGenre = allGenre;

  @override
  void initState() {
    super.initState();
    // Future는 build가 아니라 initState처럼 명확한 시점에 한 번만 만든다.
    _moviesFuture = widget.movieService.fetchMovies(
      mode: widget.initialLoadMode,
    );
    _restoreSelectedGenre();
  }

  /// Query Parameter가 있으면 그대로 쓰고, 없으면 마지막으로 저장한 장르를 복원한다.
  Future<void> _restoreSelectedGenre() async {
    final String? genre = widget.initialGenre;
    if (genre != null && movieGenres.contains(genre)) {
      _selectedGenre = genre;
      return;
    }

    final String savedGenre = await _genrePreference.read();

    // 읽는 동안 화면이 닫혔다면 dispose된 State에 setState를 호출하지 않는다.
    if (!mounted) return;

    setState(() {
      _selectedGenre = movieGenres.contains(savedGenre) ? savedGenre : allGenre;
    });
  }

  /// 장르 Chip을 누르면 화면을 갱신하고 선택값을 저장한다.
  ///
  /// 이미 불러온 목록을 걸러내기만 하므로 새 Future를 만들지 않는다.
  Future<void> _onGenreSelected(String genre) async {
    setState(() {
      _selectedGenre = genre;
    });
    await _genrePreference.save(genre);
  }

  /// `다시 시도`를 누르면 새 Future를 만들어 Loading 상태부터 다시 시작한다.
  ///
  /// 실제 서버라면 같은 요청을 다시 보내는 것이므로, Mock에서는
  /// 일시적인 오류가 해소된 상황을 흉내 내기 위해 기본(성공) 모드로 요청한다.
  void _retry() {
    _reload(MovieLoadMode.success);
  }

  void _reload(MovieLoadMode mode) {
    setState(() {
      _moviesFuture = widget.movieService.fetchMovies(mode: mode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  '영화',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Row(
                  children: <Widget>[
                    // 디버그 빌드에서만 Mock 응답 모드를 바꿔 네 가지 상태를 재현한다.
                    if (kDebugMode) _LoadModeMenu(onSelected: _reload),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('검색은 다음 주차에 연결할 예정이에요.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.search, color: AppColors.title),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GenreChipList(
            selectedGenre: _selectedGenre,
            onGenreSelected: _onGenreSelected,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: _moviesFuture,
              builder:
                  (BuildContext context, AsyncSnapshot<List<Movie>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const MovieListLoading();
                    }

                    // done이어도 오류로 완료됐을 수 있으므로 data보다 먼저 확인한다.
                    if (snapshot.hasError) {
                      return MovieListError(onRetry: _retry);
                    }

                    final List<Movie> loadedMovies =
                        snapshot.data ?? const <Movie>[];
                    final List<Movie> filteredMovies = filterMoviesByGenre(
                      _selectedGenre,
                      source: loadedMovies,
                    );

                    if (filteredMovies.isEmpty) {
                      return const MovieListEmpty();
                    }

                    return MovieGrid(movies: filteredMovies);
                  },
            ),
          ),
        ],
      ),
    );
  }
}

/// 개발용 Mock 응답 모드 선택 메뉴. 고른 모드로 영화 목록을 다시 요청한다.
class _LoadModeMenu extends StatelessWidget {
  const _LoadModeMenu({required this.onSelected});

  final ValueChanged<MovieLoadMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MovieLoadMode>(
      tooltip: '불러오기 모드 (개발용)',
      icon: const Icon(Icons.bug_report_outlined, color: AppColors.label),
      onSelected: onSelected,
      itemBuilder: (BuildContext context) =>
          const <PopupMenuEntry<MovieLoadMode>>[
            PopupMenuItem<MovieLoadMode>(
              value: MovieLoadMode.success,
              child: Text('성공으로 다시 불러오기'),
            ),
            PopupMenuItem<MovieLoadMode>(
              value: MovieLoadMode.empty,
              child: Text('빈 목록으로 다시 불러오기'),
            ),
            PopupMenuItem<MovieLoadMode>(
              value: MovieLoadMode.failure,
              child: Text('실패로 다시 불러오기'),
            ),
          ],
    );
  }
}
