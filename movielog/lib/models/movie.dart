/// 홈, 영화 목록, 영화 상세에서 공통으로 사용하는 영화 모델.
class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.posterAsset,
    required this.runningMinutes,
    required this.rating,
    required this.ratingCount,
    required this.tags,
    required this.synopsis,
  });

  /// 영화를 식별하는 ID. 상세 Route의 Path Parameter로 사용한다.
  final int id;

  /// 영화 제목
  final String title;

  /// 필터에 사용하는 대표 장르
  final String genre;

  /// 개봉 연도
  final int year;

  /// 포스터 이미지 Asset 경로
  final String posterAsset;

  /// 상영 시간 (분)
  final int runningMinutes;

  /// 평균 평점 (읽기 전용으로만 표시한다)
  final double rating;

  /// 평점을 남긴 사람 수
  final int ratingCount;

  /// 상세 화면에 표시하는 태그 목록
  final List<String> tags;

  /// 상세 화면의 시놉시스
  final String synopsis;

  /// `2024 · 로맨스/드라마 · 124분` 형태의 부제목.
  String get subtitle => '$year · ${tags.take(2).join('/')} · $runningMinutes분';

  /// `2024 · 드라마` 형태의 목록용 설명.
  String get listLabel => '$year · $genre';
}

/// 앱 전체에서 사용하는 Mock 영화 목록.
const List<Movie> movies = <Movie>[
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2024,
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    runningMinutes: 124,
    rating: 4.5,
    ratingCount: 1245,
    tags: <String>['로맨스', '드라마', '감동적인'],
    synopsis: '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 작은 천문대에서 만나게 됩니다. '
        '매일 밤 별을 관측하며 서로의 상처를 치유하고, 잊고 있던 꿈과 사랑을 다시금 깨닫게 되는 따뜻한 이야기입니다.\n\n'
        '과거의 아픔으로 인해 사람에게 마음을 열지 못하던 여주인공은 별자리처럼 변함없는 모습으로 자신을 기다려주는 '
        '남주인공을 통해 서서히 마음의 문을 열게 됩니다. 하지만 두 사람 앞에 놓인 현실적인 장벽들은 '
        '그들의 관계를 시험하게 되는데...\n\n'
        '별이 쏟아지는 밤하늘 아래, 그들이 나눈 조용한 약속들은 과연 영원할 수 있을까요? '
        '눈부신 영상미와 감성적인 OST가 어우러져 깊은 여운을 남기는 올 겨울 최고의 로맨스 영화.',
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    runningMinutes: 138,
    rating: 4.2,
    ratingCount: 982,
    tags: <String>['SF', '미스터리', '우주'],
    synopsis: '관측 불가능한 신호를 쫓아 태양계 밖으로 향한 탐사대가 이름 없는 행성에 도착합니다. '
        '그곳에서 발견한 거대한 구조물은 인류가 알고 있던 물리 법칙을 모두 뒤집어 놓습니다.\n\n'
        '교신이 끊긴 채 홀로 남겨진 탐사대원은 반복되는 환영 속에서 자신이 보고 있는 것이 '
        '기억인지 미래인지 구분하지 못하게 됩니다. 공허 너머에서 들려오는 메아리의 정체를 쫓는 '
        '사변적인 SF 스릴러.',
  ),
  Movie(
    id: 3,
    title: '기억의 숲',
    genre: '애니메이션',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
    runningMinutes: 106,
    rating: 4.9,
    ratingCount: 2310,
    tags: <String>['애니메이션', '판타지', '가족'],
    synopsis: '할머니의 낡은 지도를 들고 숲으로 들어간 소녀는 나무들이 속삭이는 소리를 듣게 됩니다. '
        '숲의 정령들은 잊혀진 기억을 먹고 자라며, 소녀가 찾는 기억도 그 안에 숨어 있습니다.\n\n'
        '정성스럽게 그려낸 수채화풍 배경과 따뜻한 음악이 어우러진 작품으로, '
        '소중한 것을 잃어본 모든 사람에게 건네는 다정한 위로를 담았습니다.',
  ),
  Movie(
    id: 4,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
    runningMinutes: 118,
    rating: 3.8,
    ratingCount: 764,
    tags: <String>['스릴러', '범죄', '느와르'],
    synopsis: '비 내리는 골목, 간판 불빛만 남은 도시에서 연쇄 실종 사건이 벌어집니다. '
        '퇴직을 앞둔 형사는 마지막 사건으로 이 수사를 자원합니다.\n\n'
        '단서를 쫓을수록 드러나는 것은 범인의 얼굴이 아니라 도시가 숨겨온 오래된 거래였습니다. '
        '숨 막히는 추격과 반전이 이어지는 느와르 스릴러.',
  ),
  Movie(
    id: 5,
    title: '미션 임프로버블',
    genre: '액션',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_abyss_walker.jpg',
    runningMinutes: 131,
    rating: 4.0,
    ratingCount: 1532,
    tags: <String>['액션', '코미디', '첩보'],
    synopsis: '세계 최고의 요원이지만 어딘가 허술한 맥스 스틸러가 다시 돌아왔습니다. '
        '이번 임무는 폭발하는 도시 한복판에서 사라진 기밀 장치를 되찾는 것.\n\n'
        '예측 불가능한 작전과 끊이지 않는 농담이 뒤섞인 첩보 액션 코미디입니다.',
  ),
  Movie(
    id: 6,
    title: '네 번째 오후',
    genre: '로맨스',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_fourth_afternoon.jpg',
    runningMinutes: 112,
    rating: 4.4,
    ratingCount: 1120,
    tags: <String>['로맨스', '드라마', '잔잔한'],
    synopsis: '같은 카페, 같은 자리에서 매주 목요일 오후에만 마주치는 두 사람이 있습니다. '
        '네 번째 오후에 처음으로 건넨 인사가 긴 이야기의 시작이 됩니다.\n\n'
        '계절이 바뀌는 동안 쌓여가는 대화와 침묵을 섬세하게 담아낸 잔잔한 멜로드라마.',
  ),
];

/// 영화 목록 필터에 사용하는 장르 목록. 첫 번째 항목은 필터를 적용하지 않는 `전체`다.
const String allGenre = '전체';

const List<String> movieGenres = <String>[
  allGenre,
  '드라마',
  'SF',
  '애니메이션',
  '스릴러',
  '로맨스',
  '액션',
];

/// ID로 Mock 영화를 찾는다. 해당하는 영화가 없으면 null을 돌려준다.
Movie? findMovieById(int? id) {
  for (final Movie movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}

/// 선택한 장르에 해당하는 영화만 걸러낸다. `전체`는 필터를 적용하지 않는다.
List<Movie> filterMoviesByGenre(String genre) {
  if (genre == allGenre) return movies;
  return movies.where((Movie movie) => movie.genre == genre).toList();
}
