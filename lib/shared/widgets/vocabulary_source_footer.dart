import 'package:flutter/material.dart';

// Short attribution shown as plain text; full sources, changes and licence
// texts are in data/*/NOTICE.md (the NGSL licence is bundled with the app).
const vocabularyCredits = '단어: NGSL · NGSL-Spoken (CC BY-SA 4.0, 앱에서 뜻·순서 추가)\n'
    '난이도: Oxford 3000/5000 · 예문: Tatoeba (CC BY 2.0 FR) 및 앱 작성\n'
    '음성: KittenTTS · sherpa-onnx (Apache 2.0) · espeak-ng (GPL-3.0)';

class VocabularySourceFooter extends StatelessWidget {
  const VocabularySourceFooter({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Text(vocabularyCredits,
          textAlign: TextAlign.center,
          style:
              TextStyle(fontSize: 10, height: 1.5, color: Color(0xFF667770))));
}
