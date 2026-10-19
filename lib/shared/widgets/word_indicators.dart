import 'package:flutter/material.dart';
import 'package:edu_voca/domain/models/word_item.dart';
import 'package:edu_voca/shared/widgets/ui.dart';

class WordIndicators extends StatelessWidget {
  final WordItem word;
  const WordIndicators({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    final stars = word.frequencyStars;
    return DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 11, color: muted, height: 1.5),
        child: Wrap(spacing: 14, runSpacing: 6, children: [
          if (word.partsOfSpeech.isNotEmpty)
            Tooltip(
                message: '이 단어의 대표 품사예요.\n여러 품사가 있으면 문장에 맞는 쓰임을 생각해 보세요.',
                child: Text('품사: ${word.partsOfSpeech.join(' · ')}',
                    style: const TextStyle(
                        color: teal, fontWeight: FontWeight.w700))),
          if (word.isPhrase) const Text('숙어·구동사'),
          Tooltip(
            message: word.cefr == null
                ? 'Oxford 목록에 없거나 품사별 CEFR이 달라 난이도를 확정하지 않았어요.'
                : 'Oxford ${word.cefr} · 별이 많을수록 어려워요.\n품사별 등급이 같은 표제어만 연결했어요.',
            child: Text(word.cefr == null
                ? '난이도 미분류'
                : '난이도 ${'★' * word.difficultyStars!}${'☆' * (5 - word.difficultyStars!)} ${word.cefr}'),
          ),
          Tooltip(
              message: word.frequencyExplanation,
              child: Semantics(
                  label: stars == null
                      ? '빈도 자료 없음'
                      : '${word.frequencyLabel} 별 $stars개, 5개 만점',
                  child: ExcludeSemantics(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(stars == null ? '빈도 자료 없음' : word.frequencyLabel),
                    if (stars != null) ...[
                      const SizedBox(width: 4),
                      for (var i = 0; i < 5; i++)
                        Icon(
                            i < stars
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 14,
                            color: i < stars ? teal : muted),
                    ],
                  ])))),
          if (word.spokenCore) const Text('회화 핵심'),
        ]));
  }
}
