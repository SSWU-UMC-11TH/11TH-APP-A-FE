import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_theme.dart';
import '../widgets/genre_chip_list.dart';
import '../widgets/movie_card.dart';

/// 영화 목록 화면. 장르 Chip으로 Mock 목록을 걸러 GridView로 보여준다.
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, this.initialGenre});

  /// Query Parameter로 전달받은 초기 장르.
  final String? initialGenre;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  late String _selectedGenre;

  @override
  void initState() {
    super.initState();
    // Query Parameter가 없거나 모르는 장르면 전체를 보여준다.
    final String? genre = widget.initialGenre;
    _selectedGenre =
        genre != null && movieGenres.contains(genre) ? genre : allGenre;
  }

  void _onGenreSelected(String genre) {
    setState(() {
      _selectedGenre = genre;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Movie> filteredMovies = filterMoviesByGenre(_selectedGenre);

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
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('검색은 다음 주차에 연결할 예정이에요.')),
                    );
                  },
                  icon: const Icon(Icons.search, color: AppColors.title),
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
            child: filteredMovies.isEmpty
                ? const _EmptyMovieList()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    itemCount: filteredMovies.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.58,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final Movie movie = filteredMovies[index];
                      return MovieCard(movie: movie);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// 선택한 장르에 해당하는 영화가 없을 때 보여주는 안내.
class _EmptyMovieList extends StatelessWidget {
  const _EmptyMovieList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.movie_outlined, size: 48, color: AppColors.label),
          const SizedBox(height: 12),
          Text(
            '이 장르의 영화가 아직 없어요',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
