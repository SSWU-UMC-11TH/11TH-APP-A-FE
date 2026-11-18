/// 쓰기 요청(회원가입·평점 등록) 한 번의 진행 상태.
///
/// - idle: 아직 보내지 않았거나, 입력이 바뀌어 이전 결과가 무효화됨
/// - submitting: 요청 진행 중. 버튼 중복 탭과 화면 이탈을 막는다.
/// - success: 서버가 저장을 완료함
/// - error: 서버가 거부했거나 통신이 실패함
enum SubmitStatus { idle, submitting, success, error }
