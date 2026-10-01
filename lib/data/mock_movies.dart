import '../models/movie.dart';

const movieGenres = ['드라마', 'SF', '애니메이션', '스릴러', '로맨스'];

const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genres: ['로맨스', '드라마'],
    tags: ['로맨스', '드라마', '감동적인'],
    year: 2024,
    runtimeMinutes: 124,
    rating: 4.5,
    reviewCount: 1245,
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    synopsis:
        '바쁜 일상 속에서 서로를 잊고 살던 두 사람이 작은 천문대에서 '
        '우연히 다시 만나, 매일 밤 별을 관측하며 잊고 있던 꿈과 사랑을 '
        '되찾아 가는 이야기입니다.',
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genres: ['SF'],
    tags: ['SF', '미스터리', '몰입감'],
    year: 2024,
    runtimeMinutes: 132,
    rating: 4.2,
    reviewCount: 892,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    synopsis:
        '홀로 낯선 행성에 불시착한 우주비행사가 사막 한가운데서 '
        '정체를 알 수 없는 신호를 발견하고, 그 근원을 쫓아가는 이야기입니다.',
  ),
  Movie(
    id: 3,
    title: '기억의 숲',
    genres: ['애니메이션'],
    tags: ['애니메이션', '판타지', '따뜻한'],
    year: 2023,
    runtimeMinutes: 105,
    rating: 4.9,
    reviewCount: 2310,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
    synopsis:
        '속삭이는 숲에 들어선 아이가 작은 숲의 정령을 만나 '
        '잃어버린 기억을 찾아 떠나는 따뜻한 모험 이야기입니다.',
  ),
  Movie(
    id: 4,
    title: '밤의 그림자',
    genres: ['스릴러'],
    tags: ['스릴러', '범죄', '긴장감'],
    year: 2024,
    runtimeMinutes: 118,
    rating: 3.8,
    reviewCount: 654,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
    synopsis:
        '비 내리는 밤, 네온사인이 가득한 골목에서 벌어진 사건을 '
        '쫓는 형사가 점점 거대한 진실에 다가가는 이야기입니다.',
  ),
  Movie(
    id: 5,
    title: '심연을 걷는 자',
    genres: ['SF', '스릴러'],
    tags: ['SF', '스릴러', '긴장감'],
    year: 2023,
    runtimeMinutes: 128,
    rating: 4.0,
    reviewCount: 431,
    posterAsset: 'assets/images/posters/poster_abyss_walker.jpg',
    synopsis:
        '심해 연구 기지에서 연락이 끊긴 동료들을 찾아 내려간 탐사대가 '
        '어둠 속에 숨겨진 존재와 마주하는 이야기입니다.',
  ),
  Movie(
    id: 6,
    title: '네 번째 오후',
    genres: ['드라마'],
    tags: ['드라마', '일상', '잔잔한'],
    year: 2022,
    runtimeMinutes: 110,
    rating: 4.3,
    reviewCount: 778,
    posterAsset: 'assets/images/posters/poster_fourth_afternoon.jpg',
    synopsis:
        '매주 같은 카페에서 오후를 보내던 세 사람이 네 번째 오후에 '
        '각자의 비밀을 털어놓으며 관계가 달라지는 이야기입니다.',
  ),
];

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}
