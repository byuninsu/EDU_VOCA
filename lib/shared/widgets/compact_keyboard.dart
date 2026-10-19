import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui.dart';

/// Lowercase English keyboard for blanks, much shorter than the system one
/// so the sentence and translation stay visible.
class CompactKeyboard extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace, onDone;
  const CompactKeyboard(
      {super.key,
      required this.onKey,
      required this.onBackspace,
      required this.onDone});

  static const _rows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];

  Widget _key(String label,
          {required VoidCallback onTap,
          int flex = 2,
          Color color = Colors.white,
          Color text = ink,
          IconData? icon,
          String? semantics}) =>
      Expanded(
          flex: flex,
          child: Padding(
              padding: const EdgeInsets.all(2.5),
              child: Semantics(
                  button: true,
                  label: semantics ?? label,
                  child: Material(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                          key: ValueKey('key-$label'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTap();
                          },
                          child: SizedBox(
                              height: 36,
                              child: Center(
                                  child: icon != null
                                      ? Icon(icon, size: 20, color: text)
                                      : Text(label,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: text)))))))));

  @override
  Widget build(BuildContext context) => Container(
      color: const Color(0xFFE7ECE5),
      padding: const EdgeInsets.fromLTRB(4, 5, 4, 4),
      child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Every row spans 20 units and is symmetric, so letters sit centred.
            for (final (index, row) in _rows.indexed)
              Row(children: [
                if (index == 1) const Spacer(),
                if (index == 2) _key("'", flex: 3, onTap: () => onKey("'")),
                for (final letter in row.split(''))
                  _key(letter, onTap: () => onKey(letter)),
                if (index == 1) const Spacer(),
                if (index == 2)
                  _key('⌫',
                      flex: 3,
                      color: const Color(0xFFD5DDD3),
                      icon: Icons.backspace_outlined,
                      semantics: '지우기',
                      onTap: onBackspace),
              ]),
            Row(children: [
              const Spacer(flex: 3),
              _key('space',
                  flex: 9, semantics: '띄어쓰기', onTap: () => onKey(' ')),
              _key('확인',
                  flex: 5, color: teal, text: Colors.white, onTap: onDone),
              const Spacer(flex: 3),
            ]),
          ])));
}
