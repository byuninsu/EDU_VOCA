import 'package:edu_voca/domain/models/scenario.dart';

// App-authored role-play conversations and Korean prompts (CC BY-SA 4.0).
// Each situation continues for five exchanges.
const scenarios = [
  Scenario('hotel', '🏨', '호텔 체크인', '여행 · 예약 확인부터 방 안내까지', [
    DialogueTurn(
        'Hello! Welcome to the hotel. How can I help you?',
        '예약했어요. 이름은 다니엘이에요.',
        'I have a reservation under Daniel.',
        'a reservation처럼 관사를 붙여요. under + 이름은 예약자 이름을 말할 때 쓰는 표현이에요.',
        alternatives: [
          'I have a reservation under the name Daniel.',
          'I made a reservation. My name is Daniel.',
          'I booked a room under Daniel.'
        ]),
    DialogueTurn(
        "Thank you, Daniel. I see you're staying for three nights. Is that right?",
        '네, 맞아요. 금요일에 체크아웃할 거예요.',
        "Yes, that's right. I'll check out on Friday.",
        'check out on + 요일: ~요일에 체크아웃하다. I\'m checking out ...처럼 정해진 계획을 말할 수도 있어요.',
        alternatives: [
          "Yes, that's correct. I'm checking out on Friday.",
          "Yes. I'll be leaving on Friday.",
          "That's right. I'll check out Friday."
        ]),
    DialogueTurn(
        'Could I see your passport and a credit card, please?',
        '여기 있어요. 카드로 결제해도 되나요?',
        'Here you are. Can I pay by card?',
        'Here you are / Here you go는 물건을 건넬 때 써요. pay by card = 카드로 결제하다.',
        alternatives: [
          'Here they are. Can I pay with my card?',
          'Here you go. Is it okay to pay by card?',
          'Sure, here you are. Can I pay by credit card?'
        ]),
    DialogueTurn(
        'Of course. Breakfast is served from seven to ten on the second floor.',
        '와이파이 비밀번호도 알려주실 수 있나요?',
        'Could you also tell me the Wi-Fi password?',
        'Could you also ...?는 추가로 정중하게 부탁할 때 써요.',
        alternatives: [
          'Can you tell me the Wi-Fi password too?',
          "What's the Wi-Fi password?",
          'Could I also get the Wi-Fi password?'
        ]),
    DialogueTurn(
        "It's on your key card holder. Here's your key. Your room is 1205.",
        '고마워요. 짐을 방까지 옮기는 걸 도와주실 수 있나요?',
        'Thank you. Could someone help me with my luggage?',
        'luggage는 셀 수 없는 명사라 a luggage가 아니라 my luggage, my bags처럼 말해요.',
        alternatives: [
          'Thanks. Could you help me take my bags to the room?',
          'Thank you. Can someone bring my luggage to my room?',
          'Thanks. Could you send my bags up to my room?'
        ]),
  ]),
  Scenario('restaurant', '🍽️', '음식점에서', '일상 · 자리 안내부터 계산까지', [
    DialogueTurn(
        'Hi there! How many people are in your party?',
        '두 명이 앉을 자리가 있을까요?',
        'Could we get a table for two?',
        'a table for two는 두 명이 앉을 테이블을 뜻해요. Can we have a table for two?도 가능해요.',
        alternatives: [
          'Can we have a table for two?',
          'Do you have a table for two?',
          'Could we get a table for two, please?'
        ]),
    DialogueTurn(
        'Sure. Would you like to sit inside or on the patio?',
        '안쪽 창가 자리로 주세요.',
        'Inside by the window, please.',
        'by the window = 창가에. 장소 + please만 짧게 말해도 충분해요.',
        alternatives: [
          "We'd like a table inside by the window.",
          'Inside, near the window, please.',
          'Could we sit inside by the window?'
        ]),
    DialogueTurn(
        'Here are your menus. Can I get you something to drink?',
        '물 두 잔이랑 콜라 하나 주세요.',
        'Two glasses of water and a Coke, please.',
        '물은 two glasses of water처럼 세요. 식당에서는 two waters도 흔히 써요.',
        alternatives: [
          'Can we have two waters and a Coke?',
          "We'll have two glasses of water and one Coke.",
          'Could we get two waters and a Coke, please?'
        ]),
    DialogueTurn(
        'Are you ready to order?',
        '저는 스테이크로 할게요. 미디엄으로 익혀 주세요.',
        "I'll have the steak, medium, please.",
        "I'll have ...는 주문할 때 가장 자연스러운 표현이에요. 굽기는 rare, medium, well-done이에요.",
        alternatives: [
          "I'd like the steak, cooked medium.",
          'Can I get the steak medium, please?',
          "I'll have the steak. Medium, please."
        ]),
    DialogueTurn(
        'How was everything? Can I get you anything else?',
        '정말 맛있었어요. 계산서 주시겠어요?',
        'It was delicious. Could we get the check, please?',
        '미국에서는 check, 영국에서는 bill이라고 해요.',
        alternatives: [
          'Everything was great. Can we have the check, please?',
          'It was really good. Could I get the bill, please?',
          'It was delicious, thanks. Can we get the check?'
        ]),
  ]),
  Scenario('cafe', '☕', '카페에서 주문', '일상 · 주문부터 결제까지', [
    DialogueTurn(
        'What can I get started for you?',
        '아이스 라테 한 잔 주세요. 우유는 오트 밀크로 바꿔주세요.',
        "I'd like an iced latte with oat milk, please.",
        "I'd like ...는 정중한 주문 표현이에요. Can I get an iced latte with oat milk?도 자연스러워요.",
        alternatives: [
          'Can I get an iced latte with oat milk?',
          'Could I have an iced latte with oat milk, please?',
          'An iced latte with oat milk, please.'
        ]),
    DialogueTurn(
        'Sure. What size would you like?',
        '중간 사이즈로 주세요.',
        'A medium, please.',
        '사이즈만 말할 때는 A medium, please.처럼 짧게 답해요. 카페에 따라 tall, grande라고도 해요.',
        alternatives: [
          'Medium, please.',
          "I'd like a medium.",
          'Can I get a medium?'
        ]),
    DialogueTurn(
        'Would you like that for here or to go?',
        '가져갈게요.',
        'To go, please.',
        'for here = 매장에서, to go = 포장이에요. 영국에서는 takeaway라고도 해요.',
        alternatives: ["I'll take it to go.", "It's to go.", 'To go, thanks.']),
    DialogueTurn(
        'Anything else? Our blueberry muffins are fresh today.',
        '그럼 블루베리 머핀도 하나 주세요.',
        "Then I'll have a blueberry muffin too.",
        'too, as well은 "~도"라는 뜻으로 문장 끝에 붙여요.',
        alternatives: [
          "Sure, I'll take a blueberry muffin as well.",
          'Okay, one blueberry muffin too, please.',
          'Then can I get a blueberry muffin too?'
        ]),
    DialogueTurn(
        "That'll be eight fifty. How would you like to pay?",
        '휴대폰으로 결제할게요.',
        "I'll pay with my phone.",
        'pay with + 수단: with my phone, with cash. 카드는 pay by card라고도 해요.',
        alternatives: [
          'Can I pay with my phone?',
          "I'll use my phone to pay.",
          "I'd like to pay with my phone."
        ]),
  ]),
  Scenario('directions', '🗺️', '길 물어보기', '여행 · 길 찾기와 버스 타기', [
    DialogueTurn(
        'Hi! Do you need some help?',
        '가장 가까운 지하철역이 어디인지 알려주시겠어요?',
        'Could you tell me where the nearest subway station is?',
        '간접 의문문에서는 where + 주어 + 동사 순서로 말해요.',
        alternatives: [
          'Where is the nearest subway station?',
          'Can you tell me how to get to the nearest subway station?',
          'Could you tell me the way to the nearest subway station?'
        ]),
    DialogueTurn(
        'Sure. Go straight for two blocks and turn left at the bank.',
        '은행에서 왼쪽이요? 걸어서 얼마나 걸려요?',
        'Left at the bank? How long does it take to walk there?',
        'How long does it take to + 동사?는 시간이 얼마나 걸리는지 물을 때 써요.',
        alternatives: [
          'Turn left at the bank? How long is the walk?',
          'Left at the bank. How long will it take on foot?',
          'At the bank? How long does it take on foot?'
        ]),
    DialogueTurn(
        "About ten minutes. You'll see the entrance next to a coffee shop.",
        '혹시 근처에 버스 정류장도 있나요?',
        'Is there a bus stop nearby, too?',
        'Is there ~ nearby?는 근처에 무엇이 있는지 물을 때 써요.',
        alternatives: [
          'Is there also a bus stop near here?',
          'Are there any bus stops around here?',
          'Is there a bus stop close by as well?'
        ]),
    DialogueTurn(
        'Yes, right across the street. Bus 12 goes to the station.',
        '12번 버스요. 버스에서 표를 살 수 있나요?',
        'Bus 12. Can I buy a ticket on the bus?',
        'on the bus = 버스 안에서. buy a ticket 대신 pay on the bus도 자연스러워요.',
        alternatives: [
          'Number 12. Can I get a ticket on the bus?',
          'Bus 12, okay. Do they sell tickets on the bus?',
          'Bus 12. Can I pay on the bus?'
        ]),
    DialogueTurn(
        'You can tap your card when you get on. Have a nice day!',
        '정말 감사합니다. 좋은 하루 보내세요!',
        'Thank you so much. You too!',
        'Have a nice day!에는 You too! 또는 Same to you!로 짧게 답해요.',
        alternatives: [
          'Thanks a lot. Have a nice day too!',
          'Thank you very much. You have a good day too!',
          'Thanks so much. Same to you!'
        ]),
  ]),
  Scenario('airport', '✈️', '공항 탑승 수속', '여행 · 짐 부치기부터 탑승구까지', [
    DialogueTurn(
        'Good morning. Where are you flying today?',
        '인천으로 가요. 여기 제 여권이에요.',
        "I'm flying to Incheon. Here's my passport.",
        'fly to + 도시 = ~로 가는 비행기를 타다.',
        alternatives: [
          "I'm going to Incheon. Here is my passport.",
          "To Incheon. Here's my passport.",
          "I'm flying to Incheon, and here is my passport."
        ]),
    DialogueTurn(
        'Thank you. Do you have any bags to check?',
        '네, 가방 하나 부칠게요.',
        'Yes, I have one bag to check.',
        'check a bag = 짐을 부치다. 기내에 들고 타는 짐은 carry-on이라고 해요.',
        alternatives: [
          'Yes, just one bag.',
          "Yes, I'd like to check one bag.",
          'Yes, one bag, please.'
        ]),
    DialogueTurn(
        'Would you like a window or an aisle seat?',
        '창가 자리로 주세요.',
        'A window seat, please.',
        'window seat = 창가 자리, aisle seat = 통로 자리예요. aisle의 s는 소리 나지 않아요.',
        alternatives: [
          "I'd like a window seat.",
          'Window, please.',
          'Can I have a window seat?'
        ]),
    DialogueTurn(
        "Here's your boarding pass. Boarding starts at 9:40 at gate 23.",
        '23번 게이트요. 비행기는 정시에 출발하나요?',
        'Gate 23. Is the flight on time?',
        'on time = 정시에. 늦어지면 delayed라고 해요.',
        alternatives: [
          'Gate 23, got it. Is the flight leaving on time?',
          'Gate 23. Is the flight on schedule?',
          'Gate 23. Will the flight leave on time?'
        ]),
    DialogueTurn(
        "Yes, it's on time. Please be at the gate thirty minutes before boarding.",
        '알겠어요. 근처에 환전소가 있나요?',
        'Okay. Is there a currency exchange nearby?',
        'exchange money = 환전하다. currency exchange는 환전소예요.',
        alternatives: [
          'Got it. Where can I exchange money?',
          'Okay. Is there a place to change money near here?',
          'All right. Is there a money exchange around here?'
        ]),
  ]),
  Scenario('shopping', '🛍️', '옷 가게에서', '쇼핑 · 사이즈 찾기부터 계산까지', [
    DialogueTurn(
        'Hi! Can I help you find anything?',
        '이 셔츠 다른 사이즈 있나요?',
        'Do you have this shirt in another size?',
        'Do you have this in + 사이즈/색?는 다른 사이즈나 색을 찾을 때 써요.',
        alternatives: [
          'Do you have this shirt in a different size?',
          'Is this shirt available in other sizes?',
          'Do you have this in another size?'
        ]),
    DialogueTurn('What size are you looking for?', '라지 사이즈요.',
        'A large, please.', '사이즈는 small, medium, large, 줄여서 S, M, L이라고 해요.',
        alternatives: [
          "I'm looking for a large.",
          'Large, please.',
          'Do you have a large?'
        ]),
    DialogueTurn(
        'Here you go. The fitting room is over there.',
        '고마워요. 한번 입어 볼게요.',
        "Thanks. I'll try it on.",
        'try on = 입어 보다. 대명사는 try it on처럼 가운데에 넣어요.',
        alternatives: [
          "Thank you. I'll try it on.",
          "Thanks, I'd like to try it on.",
          "Great, I'll go try it on."
        ]),
    DialogueTurn(
        'How does it fit?',
        '딱 맞아요. 이걸로 할게요.',
        "It fits perfectly. I'll take it.",
        "I'll take it.은 물건을 사기로 결정할 때 쓰는 표현이에요.",
        alternatives: [
          "It fits well. I'll take it.",
          "It's perfect. I'll get this one.",
          "It fits great. I'll buy it."
        ]),
    DialogueTurn(
        'Great choice. Would you like a bag?',
        '아니요, 괜찮아요. 영수증 주시겠어요?',
        'No, thank you. Could I have the receipt?',
        'No, thank you.로 정중히 거절해요. receipt의 p는 소리 나지 않아요.',
        alternatives: [
          "No, I'm fine. Can I get the receipt?",
          'No thanks. Could you give me the receipt?',
          "That's okay. May I have a receipt, please?"
        ]),
  ]),
];
