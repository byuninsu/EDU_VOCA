import 'package:flutter/material.dart';
import 'package:edu_voca/shared/widgets/ui.dart';

/// Level with its experience bar, e.g. `Lv. 3` over `4 / 7 XP`.
class XpBar extends StatelessWidget {
  final int level, xp, needed;

  /// Wide layout puts the level and numbers on one line above the bar.
  final bool wide;
  const XpBar(
      {super.key,
      required this.level,
      required this.xp,
      required this.needed,
      this.wide = false});

  @override
  Widget build(BuildContext context) {
    final max = needed == 0;
    final label = max ? '최고 레벨' : '$xp / $needed XP';
    final bar = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
            key: const ValueKey('xp-bar'),
            value: max ? 1 : xp / needed,
            minHeight: 8,
            backgroundColor: Colors.white,
            color: teal));
    final title = Text('Lv. $level',
        style: const TextStyle(
            color: teal, fontWeight: FontWeight.w800, fontSize: 15));
    final count =
        Text(label, style: const TextStyle(fontSize: 11, color: muted));
    return Semantics(
        label: 'Lv. $level, 경험치 $label',
        excludeSemantics: true,
        child: wide
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [title, const Spacer(), count]),
                const SizedBox(height: 6),
                bar,
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                title,
                const SizedBox(height: 4),
                bar,
                const SizedBox(height: 2),
                count,
              ]));
  }
}
