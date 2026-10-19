import '../view_models/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:edu_voca/features/learning/view_models/learning_view_model.dart';
import 'package:edu_voca/shared/widgets/ui.dart';
import 'package:edu_voca/shared/widgets/vocabulary_source_footer.dart';

class SettingsPage extends StatefulWidget {
  final LearningViewModel state;
  const SettingsPage({super.key, required this.state});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsViewModel vm = SettingsViewModel(widget.state);
  int get goal => vm.goal;
  int get selectedLevel => vm.level;
  @override
  void initState() {
    super.initState();
    vm.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    vm.removeListener(_refresh);
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('나의 학습 설정')),
      body: PageBody(children: [
        const Label('YOUR OWN PACE'),
        const SizedBox(height: 10),
        const TitleText('꾸준히 할 수 있는 만큼.'),
        const SizedBox(height: 24),
        Panel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const TitleText('하루 학습량', size: 20),
          const SizedBox(height: 8),
          const Text('하루 목표예요.\n목표를 달성해도 계속 연습할 수 있어요.'),
          const SizedBox(height: 20),
          TitleText('$goal문제', size: 30),
          Slider(
              value: goal.toDouble(),
              min: 5,
              max: 30,
              divisions: 25,
              label: '$goal문제',
              onChanged: (value) => vm.setGoal(value.round())),
          const Text('처음에는 10문제를 추천해요.', style: TextStyle(fontSize: 12)),
        ])),
        const SizedBox(height: 18),
        Panel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const TitleText('학습 레벨', size: 20),
          const SizedBox(height: 8),
          const Text(
              'Lv. 1~4: ★☆☆☆☆ A1\nLv. 5~8: ★★☆☆☆ A2\nLv. 9~12: ★★★☆☆ B1\nLv. 13~16: ★★★★☆ B2\nLv. 17~20: ★★★★★ C1'),
          const SizedBox(height: 20),
          TitleText('Lv. $selectedLevel / 20', size: 30),
          Slider(
              value: selectedLevel.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              label: 'Lv. $selectedLevel',
              onChanged: (v) => vm.setLevel(v.round())),
          Text(
              '익힌 단어 ${widget.state.learnedCount} / ${widget.state.vocabulary.words.length}개'),
          const SizedBox(height: 14),
          const Text(
              '현재 난이도 단어를 맞히면 경험치 +1, 정답 보기나 힌트를 쓰면 −2예요.\n'
              '경험치가 다 차면 레벨이 오르고, 0 아래로 내려가면 레벨이 내려가요.\n'
              '필요한 경험치는 Lv. 1에서 5, Lv. 19에서 20으로 레벨이 높을수록 많아요.\n'
              '같은 레벨에서 같은 단어는 한 번만 경험치를 받아요.\n'
              '다른 난이도와 미분류 단어는 경험치에 반영되지 않아요.',
              style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          const Text(
              '틀리게 입력해도 다시 도전할 수 있어요.\n정답 보기나 힌트를 썼을 때만 오답으로 기록해요.\n이 레벨은 앱 학습 단계이며 공인 CEFR 실력 평가가 아니에요.',
              style: TextStyle(fontSize: 12)),
        ])),
        const SizedBox(height: 24),
        ActionButton('설정 저장', onPressed: () {
          vm.save();
          Navigator.pop(context);
        }),
        const SizedBox(height: 20),
        const Text('Daily English 0.1 · UI 프로토타입\n기록은 이 기기에 저장됩니다.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
        const SizedBox(height: 20),
        const Text('자료 출처',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const VocabularySourceFooter(),
      ]));
}
