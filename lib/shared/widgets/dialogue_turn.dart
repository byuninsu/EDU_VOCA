import 'package:flutter/material.dart';
import 'ui.dart';

/// Keeps each speaker's English and Korean together, including at large text
/// scales. The English child can be the editable cloze or the revealed answer.
class DialogueTurn extends StatelessWidget {
  final String speaker;
  final Widget english, translation;
  final bool reply;
  const DialogueTurn(
      {super.key,
      required this.speaker,
      required this.english,
      required this.translation,
      this.reply = false});

  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: reply ? mint : const Color(0xFFF5F3EE),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(speaker,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: reply ? teal : muted)),
        const SizedBox(height: 3),
        _fitText(english, maximum: 18, minimum: 14),
        const SizedBox(height: 4),
        _fitText(translation, maximum: 14, minimum: 12),
      ]));

  // Prefer one line without clipping, ellipses, or shrinking large accessibility
  // text indefinitely. At the minimum size the full text wraps naturally.
  Widget _fitText(Widget child,
      {required double maximum, required double minimum}) {
    if (child is! Text) return child;
    return LayoutBuilder(builder: (context, constraints) {
      final base = DefaultTextStyle.of(context).style.merge(child.style);
      final content = child.textSpan ?? TextSpan(text: child.data);
      var size = maximum;
      for (; size > minimum; size--) {
        final painter = TextPainter(
            text: TextSpan(
                style: base.copyWith(fontSize: size, height: 1.3),
                children: [content]),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context))
          ..layout(maxWidth: constraints.maxWidth);
        final fits = painter.computeLineMetrics().length <= 1;
        painter.dispose();
        if (fits) break;
      }
      return Text.rich(content,
          key: child.key,
          style: base.copyWith(fontSize: size, height: 1.3),
          textAlign: child.textAlign,
          semanticsLabel: child.semanticsLabel);
    });
  }
}
