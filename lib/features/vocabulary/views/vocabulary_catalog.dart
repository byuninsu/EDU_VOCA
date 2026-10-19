import '../view_models/vocabulary_view_model.dart';
import 'package:flutter/material.dart';
import 'package:edu_voca/domain/models/exercise.dart';
import 'package:edu_voca/features/learning/view_models/learning_view_model.dart';
import 'package:edu_voca/shared/widgets/ui.dart';
import 'package:edu_voca/shared/widgets/vocabulary_source_footer.dart';
import 'package:edu_voca/features/learning/views/word_practice.dart';
import 'package:edu_voca/shared/widgets/word_indicators.dart';

class VocabularyCatalog extends StatefulWidget {
  final LearningViewModel state;
  const VocabularyCatalog({super.key, required this.state});
  @override
  State<VocabularyCatalog> createState() => _VocabularyCatalogState();
}

class _VocabularyCatalogState extends State<VocabularyCatalog> {
  late final VocabularyViewModel vm =
      VocabularyViewModel(widget.state.vocabulary);
  bool get spokenOnly => vm.spokenOnly;
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
  Widget build(BuildContext context) {
    final matches = vm.matches;
    return Scaffold(
      appBar: AppBar(title: const Text('전체 단어장')),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
              child: TextField(
                onChanged: (value) => vm.search(value),
                decoration: const InputDecoration(
                    labelText: '영어 단어 또는 한국어 뜻 검색',
                    prefixIcon: Icon(Icons.search)),
              )),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                        label: const Text('회화 핵심만'),
                        selected: spokenOnly,
                        onSelected: (value) => vm.filterSpoken(value)),
                    FilterChip(
                        label: const Text('숙어·구동사'),
                        selected: vm.phrasesOnly,
                        onSelected: vm.filterPhrases),
                    Text('${matches.length}개'),
                  ])),
          Expanded(
              child: matches.isEmpty
                  ? const Center(child: Text('검색 결과가 없어요.'))
                  : ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.all(22),
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final word = matches[index];
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Panel(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Row(children: [
                                    Expanded(
                                        child:
                                            TitleText(word.headword, size: 24)),
                                  ]),
                                  const SizedBox(height: 8),
                                  Text(word.meaning ?? word.translation),
                                  const SizedBox(height: 8),
                                  WordIndicators(word: word),
                                  if (word.spokenCore) ...[
                                    const SizedBox(height: 8),
                                    const Tag('회화 핵심'),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(word.rankLabel,
                                      style: const TextStyle(fontSize: 11)),
                                  Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                          onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute<void>(
                                                  builder: (_) => WordPractice(
                                                      state: widget.state,
                                                      exercises: [
                                                        Exercise(word,
                                                            review: widget
                                                                .state.seen
                                                                .contains(
                                                                    word.id))
                                                      ],
                                                      countsToday: true))),
                                          child: const Text('이 단어 연습하기'))),
                                ])));
                      })),
        ]),
      ))),
    );
  }
}
