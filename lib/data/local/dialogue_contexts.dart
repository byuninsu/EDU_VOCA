import 'package:edu_voca/domain/models/dialogue_context.dart';
import 'package:edu_voca/domain/models/word_item.dart';

// App-authored opening turns and translations (CC BY-SA 4.0).
// These supplement, rather than replace, the credited bilingual examples.
const dialogueContexts = <String, DialogueContext>{
  'love':
      DialogueContext('마음을 전하며', 'You mean so much to me.', '너는 나에게 정말 소중해.'),
  'water':
      DialogueContext('식당에서', 'What would you like to drink?', '무엇을 마시고 싶으세요?'),
  'help':
      DialogueContext('친구에게 부탁하며', 'That box looks heavy.', '그 상자 무거워 보이네.'),
  'ready': DialogueContext('식당에서', 'Everything on the menu looks delicious.',
      '메뉴에 있는 음식이 다 맛있어 보여요.'),
  'hungry':
      DialogueContext('점심시간에', 'Shall we get something to eat?', '우리 뭐 좀 먹을까?'),
  'busy': DialogueContext(
      '일하는 친구에게', 'Do you have a minute to talk?', '잠깐 이야기할 시간 있어?'),
  'meet':
      DialogueContext('약속을 잡으며', 'What time works for you?', '너는 몇 시가 괜찮아?'),
  'need': DialogueContext(
      '마감 시간을 앞두고', 'Can you finish this now?', '이거 지금 끝낼 수 있어?'),
  'bring':
      DialogueContext('식당에서', 'Welcome! Please have a seat.', '어서 오세요! 앉으세요.'),
  'later':
      DialogueContext('통화를 마치며', 'Sorry, I have to go now.', '미안, 나 지금 가야 해.'),
  'check': DialogueContext(
      '식사를 마치고', 'Was everything all right with your meal?', '식사는 괜찮으셨나요?'),
  'sound': DialogueContext(
      '계획을 제안하며', 'How about a picnic this weekend?', '이번 주말에 소풍 가는 건 어때?'),
  'sounds': DialogueContext(
      '계획을 제안하며', 'How about a picnic this weekend?', '이번 주말에 소풍 가는 건 어때?'),
  'available': DialogueContext('식당에서 자리를 찾으며',
      'Welcome! There are two of you, right?', '어서 오세요! 두 분이시죠?'),
  'reservation': DialogueContext('식당에 도착해서',
      'Good evening. What name did you book under?', '안녕하세요. 어떤 이름으로 예약하셨나요?'),
  'recommend': DialogueContext(
      '메뉴를 고르며', 'This is your first visit, right?', '처음 방문하신 거죠?'),
  'refill': DialogueContext(
      '카페에서', 'Your cup is empty. Anything else?', '잔이 비었네요. 더 필요한 것이 있나요?'),
  'overwhelmed': DialogueContext(
      '할 일이 많은 날',
      'You have three deadlines today. How are you doing?',
      '오늘 마감이 세 개나 있네. 괜찮아?'),
  'checkin': DialogueContext(
      '호텔 프런트에서',
      'Welcome to our hotel. How can I help you?',
      '저희 호텔에 오신 것을 환영합니다. 무엇을 도와드릴까요?'),
  'pickup': DialogueContext('아이들 하교를 앞두고',
      'Who is going to get the children today?', '오늘 누가 아이들을 데리러 갈 거야?'),
  'figureout': DialogueContext('어려운 문제 앞에서',
      'I have no idea how to solve this.', '이걸 어떻게 해결해야 할지 모르겠어.'),
  'runinto': DialogueContext(
      '출발하기 전에', 'Why are you leaving so early?', '왜 그렇게 일찍 출발해?'),
  'putoff': DialogueContext(
      '회의 일정을 정하며', 'Should we move it to next week?', '다음 주로 옮길까?'),
  'workout': DialogueContext(
      '걱정하는 친구와', 'What if our plan fails?', '우리 계획이 실패하면 어떡하지?'),
  'takeforgranted': DialogueContext('고마움을 이야기하며',
      'We are lucky to have so much support.', '우리를 도와주는 사람이 많아서 참 다행이야.'),
  'checkout': DialogueContext(
      '호텔에서 떠나는 날', 'Can we stay in the room until noon?', '정오까지 방에 있어도 될까?'),
  'wakeup': DialogueContext('아침 일과를 이야기하며',
      'What time does your day usually start?', '보통 하루를 몇 시에 시작해?'),
  'getup': DialogueContext('내일 일정을 준비하며',
      'Our train leaves at six in the morning.', '우리 기차는 아침 여섯 시에 출발해.'),
  'giveup': DialogueContext(
      '친구를 응원하며', 'Maybe I should stop trying.', '그냥 그만 노력해야 할까 봐.'),
  'findout': DialogueContext('예상치 못한 일을 겪고',
      'Nobody knows why the system stopped.', '왜 시스템이 멈췄는지 아무도 몰라.'),
  'lookfor': DialogueContext('집을 나서기 전에',
      'Why are you checking all your pockets?', '왜 주머니를 전부 뒤지고 있어?'),
  'lookafter': DialogueContext(
      '주말 부탁을 하며', 'I am staying home this weekend.', '이번 주말에는 집에 있을 거야.'),
  'lookforwardto': DialogueContext(
      '다음 만남을 약속하며', 'I will visit you next month.', '다음 달에 너를 보러 갈게.'),
  'turnon': DialogueContext(
      '어두운 방에서', 'It is getting dark in here.', '여기가 점점 어두워지네.'),
  'turnoff': DialogueContext(
      '영화가 시작되기 전에', 'The movie is about to begin.', '영화가 곧 시작돼요.'),
  'turnup':
      DialogueContext('음악을 들으며', 'Can you hear the song clearly?', '노래가 잘 들려?'),
  'turndown': DialogueContext(
      '친구의 취업 소식을 듣고', 'Did she accept the position?', '그녀가 그 자리를 수락했어?'),
  'takeoff': DialogueContext('비행기 안에서', 'Are we leaving soon?', '곧 출발하나요?'),
  'puton': DialogueContext('추운 날 외출하며', 'It is freezing outside.', '밖이 몹시 추워.'),
  'tryon': DialogueContext(
      '옷 가게에서', 'This jacket comes in your size.', '이 재킷은 손님 사이즈도 있어요.'),
  'takeout':
      DialogueContext('집안일을 나누며', 'What can I do to help?', '내가 무엇을 도와주면 될까?'),
  'putaway': DialogueContext('놀이를 마치고', 'I am done playing now.', '이제 다 놀았어요.'),
  'cleanup': DialogueContext(
      '저녁을 먹고', 'There are dishes everywhere.', '여기저기 접시가 널려 있네.'),
  'comein': DialogueContext('문 앞에서', 'Hello! May I enter?', '안녕하세요! 들어가도 될까요?'),
  'goout': DialogueContext(
      '저녁 계획을 세우며', 'I do not feel like cooking today.', '오늘은 요리하고 싶지 않아.'),
  'comeback':
      DialogueContext('외출하는 가족에게', 'I am going for a walk.', '산책하러 다녀올게요.'),
  'goback': DialogueContext(
      '퇴근한 뒤에', 'Did you leave your laptop at work?', '노트북을 회사에 두고 왔어?'),
  'geton': DialogueContext(
      '버스 정류장에서', 'We missed our bus. What now?', '우리 버스를 놓쳤어. 이제 어떡하지?'),
  'getoff':
      DialogueContext('버스 안에서', 'Are we close to the museum?', '박물관에 거의 다 왔어?'),
  'getalongwith': DialogueContext('새 동네에 이사한 뒤',
      'I moved into my new apartment last month.', '지난달에 새 아파트로 이사했어.'),
  'getover':
      DialogueContext('아팠던 친구와', 'How long were you ill?', '얼마나 오래 아팠어?'),
  'runoutof': DialogueContext(
      '냉장고를 확인하며', 'Do we need to go shopping today?', '오늘 장을 봐야 할까?'),
  'dealwith': DialogueContext(
      '업무 문제를 의논하며', 'Can this wait until next week?', '이건 다음 주까지 미뤄도 될까?'),
  'comeupwith': DialogueContext(
      '아이디어 회의에서', 'This plan seems too expensive.', '이 계획은 비용이 너무 많이 들 것 같아.'),
  'carryon': DialogueContext('일하는 중에', 'Should I stop for the announcement?',
      '안내 방송 때문에 하던 일을 멈춰야 하나요?'),
  'carryout': DialogueContext(
      '계획을 확인하며', 'When will the team start?', '그 팀은 언제 시작하나요?'),
  'setoff': DialogueContext('여행을 준비하며',
      'It is a long drive. When should we leave?', '차로 멀리 가야 해. 언제 출발할까?'),
  'setup': DialogueContext(
      '새 기기를 샀을 때', 'Your new computer has arrived.', '새 컴퓨터가 도착했네.'),
  'breakdown': DialogueContext(
      '오래된 차를 보며', 'Do you think this car is reliable?', '이 차를 믿고 타도 될까?'),
  'breakup': DialogueContext(
      '친구들의 근황을 나누며', 'Are those two still together?', '그 두 사람 아직 사귀어?'),
  'calmdown': DialogueContext(
      '긴장한 친구 곁에서', 'I am so nervous about the interview.', '면접 때문에 너무 긴장돼.'),
  'cheerup': DialogueContext(
      '기운 없는 친구에게', 'I have had a really bad day.', '오늘 정말 힘든 하루였어.'),
  'slowdown': DialogueContext(
      '학교 앞을 운전하며', 'There are children crossing the road.', '아이들이 길을 건너고 있어.'),
  'hurryup': DialogueContext(
      '약속 시간이 다가와서', 'We only have five minutes left.', '우리 이제 오 분밖에 안 남았어.'),
  'holdon': DialogueContext('예약을 확인하며', 'Is my room ready?', '제 방이 준비됐나요?'),
  'hangout': DialogueContext('방과 후 일상을 이야기하며',
      'Where do you and your friends spend time?', '너와 친구들은 어디서 시간을 보내?'),
  'showup': DialogueContext(
      '모임을 준비하며', 'The party starts at seven.', '파티는 일곱 시에 시작해.'),
  'fillout': DialogueContext('접수 창구에서',
      'This is my first visit. What should I do?', '처음 왔는데 무엇을 하면 되나요?'),
  'makesure':
      DialogueContext('집을 나서며', 'Are we ready to leave?', '이제 나갈 준비 됐어?'),
  'takecareof': DialogueContext('여행 전 부탁을 하며',
      'I can stop by your house while you are away.', '네가 없는 동안 집에 들를 수 있어.'),
  'onpurpose': DialogueContext('깨진 물건 앞에서', 'Why did you do that?', '왜 그랬어?'),
  'byaccident': DialogueContext(
      '사라진 메시지를 찾으며', 'Where did the message go?', '그 메시지는 어디로 갔어?'),
  'atfirst': DialogueContext(
      '끝낸 일을 돌아보며', 'Was it easy from the beginning?', '처음부터 쉬웠어?'),
  'intheend': DialogueContext(
      '지난 일을 돌아보며', 'How did everything turn out?', '모든 일이 어떻게 됐어?'),
  'rightaway': DialogueContext(
      '급히 연락해야 할 때', 'It is urgent. Please do not wait.', '급한 일이야. 지체하지 말아 줘.'),
  'fromnowon': DialogueContext(
      '실수를 인정하며', 'You made the same mistake again.', '또 같은 실수를 했네.'),
  'pieceofcake':
      DialogueContext('시험이 끝난 뒤', 'Was the test difficult?', '시험이 어려웠어?'),
  'undertheweather': DialogueContext(
      '친구의 안부를 물으며', 'You look tired. Are you all right?', '피곤해 보이네. 괜찮아?'),
  'breaktheice': DialogueContext(
      '첫 모임을 준비하며',
      'Nobody knows each other yet. How can we help?',
      '아직 서로 모르는 사이인데 어떻게 도와주면 좋을까?'),
  'onceinabluemoon': DialogueContext(
      '외식 습관을 이야기하며', 'Do you go to restaurants often?', '식당에 자주 가?'),
  'keepaneyeon': DialogueContext('잠시 자리를 비우며',
      'I will be sitting here for a while.', '나는 여기 잠깐 앉아 있을 거야.'),
  'ontheotherhand': DialogueContext('방을 구하며',
      'What are the good and bad points of this room?', '이 방의 장단점이 뭐야?'),
};

/// Uses explicit scenes where available. Other existing examples receive a
/// topic opening, with conversational fallbacks for questions and statements.
/// No network request, answer change or narrowing of the vocabulary pool.
DialogueContext dialogueContextFor(WordItem word) {
  final authored = dialogueContexts[word.id];
  if (authored != null) return authored;
  final sentence = word.complete.toLowerCase();
  for (final (pattern, context) in _topics) {
    if (RegExp('\\b(?:$pattern)\\b').hasMatch(sentence)) return context;
  }
  if (sentence.endsWith('?')) {
    return const DialogueContext('친구와 이야기를 나누며',
        'You look like you want to ask me something.', '나에게 뭔가 물어보고 싶은 표정이네.');
  }
  if (sentence.startsWith('please ') ||
      sentence.startsWith('do not ') ||
      sentence.startsWith("don't ") ||
      sentence.startsWith("let's ")) {
    return const DialogueContext(
        '다음 행동을 의논하며', 'What should we do now?', '우리 이제 어떻게 해야 할까?');
  }
  if (RegExp(r'\b(yesterday|ago|was|were|had|did)\b').hasMatch(sentence)) {
    return const DialogueContext(
        '지난 일을 이야기하며', 'Tell me what happened.', '무슨 일이 있었는지 말해 줘.');
  }
  if (RegExp(r"\b(tomorrow|will|going to)\b|\bi'll\b").hasMatch(sentence)) {
    return const DialogueContext('앞으로의 일을 이야기하며',
        'What do you think will happen next?', '앞으로 어떻게 될 것 같아?');
  }
  return const DialogueContext(
      '친구와 이야기를 나누며', 'What is on your mind?', '무슨 생각을 하고 있어?');
}

// Broad openings deliberately avoid asserting facts that the reply may deny.
const _topics = <(String, DialogueContext)>[
  (
    'restaurant|menu|waiter|waitress|order food',
    DialogueContext(
        '식사 이야기를 나누며', "Let's talk about eating out.", '외식에 대해 이야기하자.')
  ),
  (
    'breakfast|lunch|dinner|meal|food|eat|ate|cooking|cook',
    DialogueContext(
        '음식 이야기를 나누며', 'I was thinking about food.', '음식 생각을 하고 있었어.')
  ),
  (
    'coffee|tea|juice|drink|drinking|milk|water',
    DialogueContext(
        '마실 것을 이야기하며', "Let's talk about drinks.", '마실 것에 대해 이야기하자.')
  ),
  (
    'hotel|booking|reservation',
    DialogueContext(
        '숙박 이야기를 나누며', "Let's talk about where to stay.", '어디서 묵을지 이야기하자.')
  ),
  (
    'airport|flight|plane|passport',
    DialogueContext('비행기 여행을 이야기하며', 'I was thinking about air travel.',
        '비행기 여행에 대해 생각하고 있었어.')
  ),
  (
    'train|bus|station|subway|ticket',
    DialogueContext('이동 수단을 이야기하며', "Let's talk about getting around.",
        '이동하는 방법에 대해 이야기하자.')
  ),
  (
    'car|drive|driving|traffic|road',
    DialogueContext('교통 이야기를 나누며', 'I was thinking about life on the road.',
        '길 위에서 겪는 일들에 대해 생각하고 있었어.')
  ),
  (
    'trip|travel|vacation|abroad|tourist',
    DialogueContext('여행 이야기를 나누며', "Let's talk about travel.", '여행에 대해 이야기하자.')
  ),
  (
    'school|student|teacher|classroom|exam|homework|lesson|university',
    DialogueContext(
        '학교생활을 이야기하며', "Let's talk about studying.", '공부에 대해 이야기하자.')
  ),
  (
    'job|office|boss|colleague|salary|career',
    DialogueContext(
        '직장생활을 이야기하며', 'I was thinking about work.', '직장 생활에 대해 생각하고 있었어.')
  ),
  (
    'meeting|project|deadline|plan',
    DialogueContext(
        '계획을 의논하며', "Let's talk about our plans.", '우리 계획에 대해 이야기하자.')
  ),
  (
    'doctor|hospital|medicine|ill|sick|health|pain|flu',
    DialogueContext('건강 이야기를 나누며', "Let's talk about health.", '건강에 대해 이야기하자.')
  ),
  (
    'rain|snow|weather|sunny|storm|wind',
    DialogueContext(
        '날씨 이야기를 나누며', 'I was thinking about the weather.', '날씨에 대해 생각하고 있었어.')
  ),
  (
    'family|mother|father|parent|parents|sister|brother|daughter|son',
    DialogueContext('가족 이야기를 나누며', "Let's talk about family.", '가족에 대해 이야기하자.')
  ),
  (
    'friend|friends|neighbor|neighbour',
    DialogueContext('주변 사람들을 이야기하며', "Let's talk about the people around us.",
        '우리 주변 사람들에 대해 이야기하자.')
  ),
  (
    'dog|cat|pet|animal|bird',
    DialogueContext('동물 이야기를 나누며', "Let's talk about animals.", '동물에 대해 이야기하자.')
  ),
  (
    'computer|phone|internet|email|software|website|screen',
    DialogueContext(
        '기술 이야기를 나누며', 'Technology is on my mind today.', '오늘은 기술에 대해 생각하고 있어.')
  ),
  (
    'money|price|cost|pay|paid|bank|expensive|cheap',
    DialogueContext('돈과 생활을 이야기하며', "Let's talk about money.", '돈에 대해 이야기하자.')
  ),
  (
    'shop|shopping|store|bought|buy|sell',
    DialogueContext(
        '쇼핑 이야기를 나누며', 'I was thinking about shopping.', '쇼핑에 대해 생각하고 있었어.')
  ),
  (
    'coat|jacket|shirt|dress|shoes|clothes|wear',
    DialogueContext('옷차림을 이야기하며', "Let's talk about clothes.", '옷에 대해 이야기하자.')
  ),
  (
    'music|song|sing|concert|piano|guitar',
    DialogueContext('음악 이야기를 나누며', "Let's talk about music.", '음악에 대해 이야기하자.')
  ),
  (
    'movie|film|cinema|actor|actress',
    DialogueContext('영화 이야기를 나누며', "Let's talk about movies.", '영화에 대해 이야기하자.')
  ),
  (
    'book|novel|library|read|reading|story',
    DialogueContext('책과 이야기를 나누며', 'I was thinking about books and stories.',
        '책과 이야기에 대해 생각하고 있었어.')
  ),
  (
    'football|soccer|tennis|baseball|sport|sports|game|team',
    DialogueContext('운동과 경기를 이야기하며', "Let's talk about sports and games.",
        '운동과 경기에 대해 이야기하자.')
  ),
  (
    'house|home|apartment|room|kitchen|door|window',
    DialogueContext('집에서의 생활을 이야기하며', "Let's talk about everyday life at home.",
        '집에서의 일상에 대해 이야기하자.')
  ),
  (
    'sleep|bed|tired|rest',
    DialogueContext(
        '하루 일과를 이야기하며',
        'I was thinking about rest and daily routines.',
        '휴식과 하루 일과에 대해 생각하고 있었어.')
  ),
  (
    'party|birthday|celebrate|wedding|gift',
    DialogueContext('특별한 날을 이야기하며', "Let's talk about special occasions.",
        '특별한 날에 대해 이야기하자.')
  ),
  (
    'city|town|village|country|world',
    DialogueContext('여러 장소를 이야기하며', "Let's talk about the places around us.",
        '우리 주변의 여러 장소에 대해 이야기하자.')
  ),
  (
    'tree|flower|garden|forest|river|sea|ocean|mountain|nature',
    DialogueContext('자연 이야기를 나누며', "Let's talk about nature.", '자연에 대해 이야기하자.')
  ),
];
