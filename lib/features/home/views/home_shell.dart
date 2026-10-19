import 'package:flutter/material.dart';
import '../../account/view_models/account_view_model.dart';
import '../../account/views/account_page.dart';
import 'package:edu_voca/domain/models/scenario.dart';
import 'package:edu_voca/domain/models/exercise.dart';
import 'package:edu_voca/features/learning/view_models/learning_view_model.dart';
import 'package:edu_voca/shared/widgets/ui.dart';
import 'package:edu_voca/shared/widgets/xp_bar.dart';
import 'package:edu_voca/shared/widgets/cloze_sentence.dart';
import 'package:edu_voca/shared/widgets/vocabulary_source_footer.dart';
import 'package:edu_voca/features/learning/views/word_practice.dart';
import 'package:edu_voca/features/writing/views/writing_practice.dart';
import 'package:edu_voca/features/settings/views/settings_page.dart';
import 'package:edu_voca/features/vocabulary/views/vocabulary_catalog.dart';

class HomeShell extends StatefulWidget {
  final LearningViewModel state;
  final AccountViewModel? account;
  const HomeShell({super.key, required this.state, this.account});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int tab = 0;
  LearningViewModel get s => widget.state;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) s.refreshDay();
  }

  void start() {
    final session = s.makeSession();
    if (session.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('연습할 단어가 아직 없어요.')));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (_) => WordPractice(
                  state: s, exercises: session, countsToday: true)));
    }
  }

  void role(Scenario item, {int turn = 0}) => Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (_) =>
              WritingPractice(state: s, scenario: item, startTurn: turn)));
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: s,
      // Sections open from the home shortcuts; back returns home.
      builder: (context, _) => PopScope(
          canPop: tab == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) selectTab(0);
          },
          child: Scaffold(
            appBar: AppBar(
                leading: tab == 0
                    ? null
                    : BackButton(
                        key: const ValueKey('section-back'),
                        onPressed: () => selectTab(0)),
                title: tab == 0
                    ? const Row(children: [
                        PuppyMascot(size: 40),
                        SizedBox(width: 10),
                        Flexible(
                            child: Text('daily english',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800))),
                      ])
                    : Text(const ['', '단어', '영작', '복습'][tab],
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                actions: [
                  if (widget.account != null)
                    IconButton(
                        tooltip: '내 계정',
                        icon: const Icon(Icons.account_circle_outlined),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) =>
                                    AccountPage(vm: widget.account!)))),
                  IconButton(
                      tooltip: '학습 설정',
                      icon: const Icon(Icons.tune_rounded),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) => SettingsPage(state: s)))),
                  const SizedBox(width: 8)
                ]),
            body: PageBody(key: ValueKey(tab), children: [
              if (s.storageError != null) ...[
                Panel(
                    color: const Color(0xFFFFEEDB),
                    child: Text(s.storageError!)),
                const SizedBox(height: 16)
              ],
              ...switch (tab) {
                0 => home(),
                1 => vocabulary(),
                2 => roleplay(),
                _ => review()
              },
              const SizedBox(height: 24),
            ]),
          )));
  void selectTab(int value) {
    s.refreshDay();
    setState(() => tab = value);
  }

  Widget shortcut(String label, IconData icon, Color color, int destination) =>
      Expanded(
          child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                key: ValueKey('home-shortcut-$destination'),
                borderRadius: BorderRadius.circular(24),
                onTap: () => selectTab(destination),
                child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                    child: Column(children: [
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(18)),
                          child: Icon(icon, color: teal, size: 28)),
                      const SizedBox(height: 8),
                      Text(label,
                          style: const TextStyle(
                              color: ink, fontWeight: FontWeight.w700)),
                    ])),
              )));

  List<Widget> home() => [
        Row(children: [
          const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                TitleText('오늘도 같이 한 걸음!', size: 23),
                SizedBox(height: 4),
                Text('오늘은 어떤 영어를 만나볼까요?'),
              ])),
          const SizedBox(width: 12),
          SizedBox(
              width: 96,
              child: XpBar(level: s.level, xp: s.xp, needed: s.xpToNext)),
        ]),
        const SizedBox(height: 18),
        Material(
            color: teal,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: start,
              key: const ValueKey('home-start'),
              child: Ink(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF276A68), Color(0xFF438C80)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)),
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(
                                      s.completed >= s.dailyGoal
                                          ? '오늘 목표 달성 · 더 해볼까요?'
                                          : '강아지와 함께하는 영어 산책',
                                      style: const TextStyle(
                                          color: Color(0xFFDDEFE5),
                                          fontSize: 12)),
                                  const SizedBox(height: 8),
                                  Text(
                                      s.completed >= s.dailyGoal
                                          ? '단어 계속하기'
                                          : '오늘의 학습 시작',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          height: 1.3,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    const Icon(Icons.pets_rounded,
                                        color: biscuit, size: 16),
                                    const SizedBox(width: 6),
                                    Flexible(
                                        child: Text(
                                            '${s.completed} / ${s.dailyGoal}문제 완료',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12))),
                                  ]),
                                ])),
                            const SizedBox(width: 8),
                            PuppyMascot(
                                size: 92,
                                pose: s.completed >= s.dailyGoal
                                    ? PuppyPose.happy
                                    : PuppyPose.cards),
                          ]),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(
                                child: LinearProgressIndicator(
                                    value:
                                        (s.completed / s.dailyGoal).clamp(0, 1),
                                    minHeight: 6,
                                    color: biscuit,
                                    backgroundColor: const Color(0xFF205855))),
                            const SizedBox(width: 14),
                            const CircleAvatar(
                                radius: 17,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.arrow_forward_rounded,
                                    size: 20, color: teal)),
                          ]),
                        ])),
              ),
            )),
        const SizedBox(height: 22),
        const TitleText('골라서 연습해요', size: 18),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          shortcut('단어', Icons.auto_stories_rounded, mint, 1),
          const SizedBox(width: 10),
          shortcut('영작', Icons.chat_bubble_rounded, peach, 2),
          const SizedBox(width: 10),
          shortcut('복습', Icons.history_rounded, const Color(0xFFFFEDBC), 3),
        ]),
        const SizedBox(height: 16),
        Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: mint, borderRadius: BorderRadius.circular(22)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('익힌 단어 ${s.learnedCount} / ${s.vocabulary.words.length}개',
                  style:
                      const TextStyle(color: ink, fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text('${s.targetCefr} 중심 학습 · 오늘 복습 ${s.dueCount}개',
                  style: const TextStyle(fontSize: 12, color: teal)),
            ])),
      ];
  List<Widget> vocabulary() => [
        const Label('NGSL VOCABULARY'),
        const SizedBox(height: 10),
        const TitleText('자주 쓰는 단어부터 차근차근'),
        const SizedBox(height: 10),
        const Text(
            'NGSL 단어 2,833개와 숙어·구동사 64개를 함께 배워요.\n문장 전체 해석을 보고 빈칸을 채워보세요.'),
        const SizedBox(height: 24),
        Panel(
            color: mint,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Tag('학습 Lv. ${s.level} · 익힌 단어 ${s.learnedCount}개'),
              const SizedBox(height: 24),
              const ClozeSentence(sentence: 'Can you ____ me?', answer: 'help'),
              const SizedBox(height: 10),
              const Text('나 좀 도와줄 수 있어?',
                  style: TextStyle(fontSize: 17, color: ink)),
              const SizedBox(height: 24),
              Text('오늘 ${s.completed} / ${s.dailyGoal}문제 완료'),
              const SizedBox(height: 16),
              ActionButton('단어 연습하기', onPressed: start),
              const SizedBox(height: 8),
              TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => VocabularyCatalog(state: s))),
                  child: const Text('전체 단어 보기')),
            ])),
        const SizedBox(height: 20),
        const Panel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TitleText('이렇게 학습해요', size: 20),
          SizedBox(height: 14),
          Text(
              '01   영어 예문과 문장 전체 해석을 읽어요.\n02   빈칸에 맞는 형태의 단어를 입력해요.\n03   틀려도 정답까지 계속 도전해요.\n04   정답 보기를 누르면 복습에 저장해요.\n하루 목표를 마쳐도 계속 연습할 수 있어요.',
              style: TextStyle(height: 2, color: ink)),
        ])),
        const SizedBox(height: 16),
        const Text(
            '내 레벨에 맞는 난이도 중심으로 회화 핵심·빈도순으로 만나요.\n기초 단어와 복습도 함께 연습할 수 있어요.',
            style: TextStyle(fontSize: 12)),
      ];
  Widget scenarioCard(Scenario item) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
          onTap: () => role(item),
          borderRadius: BorderRadius.circular(24),
          child: Panel(
              child: Row(children: [
            Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: paper, borderRadius: BorderRadius.circular(18)),
                child: Text(item.emoji, style: const TextStyle(fontSize: 28))),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  TitleText(item.title, size: 17),
                  const SizedBox(height: 4),
                  Text(item.subtitle, style: const TextStyle(fontSize: 12)),
                ])),
            const Icon(Icons.arrow_forward_rounded, size: 19, color: teal),
          ]))));
  List<Widget> roleplay() => [
        const Label('REAL-LIFE ENGLISH'),
        const SizedBox(height: 10),
        const TitleText('나라면 어떻게 말할까?'),
        const SizedBox(height: 10),
        const Text('익숙한 상황에서 한 문장씩 말해보세요.\n상대방 말을 듣고 대답하면 AI 코치가 평가해 줘요.'),
        const SizedBox(height: 24),
        ...s.vocabulary.scenarios.map(scenarioCard),
        const SizedBox(height: 8),
        const Panel(
            color: mint, child: PuppyNote('완벽하지 않아도 괜찮아요.\n한 문장씩 함께 연습해요!')),
      ];
  List<Widget> review() => [
        const Label('MAKE IT YOURS'),
        const SizedBox(height: 10),
        const TitleText('다시 만나면,\n더 오래 기억해요.'),
        const SizedBox(height: 10),
        Text('단어 ${s.reviews.length}개 · 영작 표현 ${s.writingReviews.length}개'),
        const SizedBox(height: 24),
        if (s.reviews.isEmpty && s.writingReviews.isEmpty)
          const Panel(
              child: Column(children: [
            SizedBox(height: 12),
            PuppyMascot(size: 132, pose: PuppyPose.happy),
            SizedBox(height: 16),
            TitleText('아직 쌓인 복습이 없어요', size: 20),
            SizedBox(height: 10),
            Text('틀린 단어나 다시 연습할 표현을\n이곳에 모아드릴게요.', textAlign: TextAlign.center),
            SizedBox(height: 12),
          ])),
        for (final entry in s.reviews.values)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Panel(child: Builder(builder: (context) {
                final word = s.vocabulary.byId[entry.id]!;
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: TitleText(word.answer, size: 22)),
                        Tag(
                            [
                              '${entry.missedAgo(DateTime.now())} 틀림',
                              if (entry.misses >= 2) '${entry.misses}번',
                              entry.due.isAfter(DateTime.now())
                                  ? '${entry.due.month}/${entry.due.day} 복습'
                                  : '지금 복습',
                            ].join(' · '),
                            warm: entry.misses >= 3)
                      ]),
                      const SizedBox(height: 8),
                      Text(word.translation),
                      Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                      builder: (_) => WordPractice(
                                          state: s,
                                          exercises: [
                                            Exercise.fromReview(word, entry)
                                          ],
                                          countsToday: false))),
                              child: const Text('다시 풀기 →'))),
                    ]);
              }))),
        for (final entry in s.writingReviews.entries)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Panel(child: Builder(builder: (context) {
                final item =
                    s.vocabulary.scenarios.firstWhere((v) => v.id == entry.key);
                final (turn, answer) = Scenario.parseReview(entry.value);
                final step = item.turns[turn.clamp(0, item.turns.length - 1)];
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tag('${item.emoji}  ${item.title}'),
                      const SizedBox(height: 12),
                      Text(step.prompt, style: const TextStyle(color: ink)),
                      const SizedBox(height: 8),
                      Text('지난 답변: $answer'),
                      Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: () => role(item, turn: turn),
                              child: const Text('다시 써보기 →'))),
                    ]);
              }))),
      ];
}
