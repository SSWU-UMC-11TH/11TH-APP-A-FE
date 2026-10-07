import '../models/movie.dart';

// 홈, 목록, 상세 화면이 함께 사용하는 Mock 데이터
const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2023,
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    rating: 4.5,
    ratingCount: 1245,
    runtimeMinutes: 124,
    tags: ['로맨스', '드라마', '감동적인'],
    synopsis:
        '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 작은 천문대에서 만나게 됩니다. 매일 밤 별을 관측하며 서로의 상처를 치유하고, 잊고 있던 꿈과 사랑을 다시금 깨닫게 되는 따뜻한 이야기입니다.\n\n'
        '과거의 아픔으로 인해 사람에게 마음을 열지 못하던 여주인공은, 별자리처럼 변함없는 모습으로 자신을 기다려주는 남주인공을 통해 서서히 마음의 문을 열게 됩니다. 하지만 두 사람 앞에 놓인 현실적인 장벽들은 그들의 관계를 시험하게 되는데...\n\n'
        '별이 쏟아지는 밤하늘 아래, 그들이 나눈 조용한 약속들은 과연 영원할 수 있을까요? 눈부신 영상미와 감성적인 OST가 어우러져 깊은 여운을 남기는 올 겨울 최고의 로맨스 영화.',
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    rating: 4.2,
    ratingCount: 987,
    runtimeMinutes: 138,
    tags: ['SF', '모험', '서사적인'],
    synopsis:
        '인류의 마지막 탐사선이 닿은 낯선 행성에서, 한 우주비행사가 오래전 사라진 문명의 흔적을 발견합니다. 고요한 사막 위에 남겨진 기묘한 신호는 그가 알고 있던 우주의 법칙을 뒤흔들기 시작합니다.\n\n'
        '지구와의 교신이 끊긴 채 홀로 남은 그는 신호의 정체를 쫓아 행성의 가장 깊은 곳으로 향합니다.',
  ),
  Movie(
    id: 3,
    title: '기억의 숲',
    genre: '애니메이션',
    year: 2022,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
    rating: 4.9,
    ratingCount: 2310,
    runtimeMinutes: 96,
    tags: ['애니메이션', '판타지', '따뜻한'],
    synopsis: '깊은 숲속에서 작은 정령과 마주친 소녀는 잊고 있던 기억의 조각들을 하나씩 찾아가는 여정을 시작합니다. 숲이 속삭이는 이야기를 따라가다 보면 마법과 우정이 가득한 비밀의 장소에 도착하게 됩니다.',
  ),
  Movie(
    id: 4,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
    rating: 3.8,
    ratingCount: 654,
    runtimeMinutes: 112,
    tags: ['스릴러', '미스터리', '긴장감'],
    synopsis: '비가 내리는 도시의 좁은 골목, 한 형사가 목격한 의문의 사건은 오래전 덮어둔 사건과 이어져 있었습니다. 어둠 속에서 그를 따라오는 그림자의 정체가 서서히 드러납니다.',
  ),
  Movie(
    id: 5,
    title: '봄날의 커피',
    genre: '로맨스',
    year: 2021,
    posterAsset: 'assets/images/posters/poster_fourth_afternoon.jpg',
    rating: 4.5,
    ratingCount: 1102,
    runtimeMinutes: 105,
    tags: ['로맨스', '일상', '설레는'],
    synopsis: '작은 카페에서 우연히 마주 앉은 두 사람은 커피 한 잔의 시간 동안 서로의 이야기를 나누며 조금씩 가까워집니다. 평범했던 오후가 특별한 기억으로 바뀌는 순간을 담은 따뜻한 로맨스입니다.',
  ),
];

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}
