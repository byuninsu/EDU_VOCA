import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'ui.dart';

/// Connects the in-app keyboard to the blanks of a [ClozeSentence].
class ClozeKeys {
  _ClozeSentenceState? _target;
  void type(String letter) => _target?._type(letter);
  void backspace() => _target?._backspace();
}

/// One continuous underline per word; optional editing happens inside the sentence.
class ClozeSentence extends StatefulWidget {
  final String sentence, answer, input;
  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback? onChanged, onSubmitted;

  /// Shrinks the font (down to 14) so the sentence fits in this many lines.
  final int? fitLines;
  final double maxFontSize;

  /// When set, the in-app keyboard types here and the system one stays hidden.
  final ClozeKeys? keys;
  const ClozeSentence(
      {super.key,
      required this.sentence,
      required this.answer,
      this.input = '',
      this.controller,
      this.readOnly = false,
      this.onChanged,
      this.onSubmitted,
      this.fitLines,
      this.maxFontSize = 26,
      this.keys});
  @override
  State<ClozeSentence> createState() => _ClozeSentenceState();
}

class _ClozeSentenceState extends State<ClozeSentence> {
  final fields = <TextEditingController>[];
  final nodes = <FocusNode>[];
  bool publishing = false;
  List<String> get words => widget.answer.trim().split(RegExp(r'\s+'));
  @override
  void initState() {
    super.initState();
    _create();
    widget.controller?.addListener(_externalChange);
    widget.keys?._target = this;
  }

  void _create() {
    for (final field in fields) {
      field.dispose();
    }
    for (final node in nodes) {
      node.dispose();
    }
    fields.clear();
    nodes.clear();
    for (final _ in words) {
      fields.add(TextEditingController());
      nodes.add(FocusNode());
    }
    _sync();
  }

  void _sync() {
    if (fields.map((field) => field.text).join(' ') ==
        (widget.controller?.text ?? widget.input)) {
      return;
    }
    final parts =
        (widget.controller?.text ?? widget.input).split(RegExp(r'\s+'));
    for (var i = 0; i < fields.length; i++) {
      final text = i == fields.length - 1
          ? parts.skip(i).join(' ')
          : (i < parts.length ? parts[i] : '');
      if (fields[i].text != text) {
        fields[i].value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length));
      }
    }
  }

  void _externalChange() {
    if (!publishing) setState(_sync);
  }

  @override
  void didUpdateWidget(ClozeSentence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_externalChange);
      widget.controller?.addListener(_externalChange);
    }
    if (oldWidget.keys != widget.keys) {
      if (identical(oldWidget.keys?._target, this)) {
        oldWidget.keys!._target = null;
      }
      widget.keys?._target = this;
    }
    if (oldWidget.answer != widget.answer) {
      _create();
    } else {
      _sync();
    }
  }

  void _edit(int index, String value) {
    if (RegExp(r'\s').hasMatch(value) && index < fields.length - 1) {
      final parts = value.trimLeft().split(RegExp(r'\s+'));
      for (var j = 0; j < parts.length && index + j < fields.length; j++) {
        final position = index + j;
        final text =
            position == fields.length - 1 ? parts.skip(j).join(' ') : parts[j];
        fields[position].value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length));
      }
      nodes[math.min(index + parts.length - 1, nodes.length - 1)]
          .requestFocus();
    } else if (index < fields.length - 1 &&
        value.length == words[index].length) {
      // A filled word moves on to the next blank of the phrase.
      nodes[index + 1].requestFocus();
    }
    publishing = true;
    widget.controller?.text = fields.map((field) => field.text).join(' ');
    publishing = false;
    widget.onChanged?.call();
    setState(() {});
  }

  /// The blank being typed into: the focused one, else the first unfinished.
  int _active() {
    final focused = nodes.indexWhere((node) => node.hasFocus);
    if (focused >= 0) return focused;
    final open = [
      for (var i = 0; i < fields.length; i++)
        if (fields[i].text.length < words[i].length) i
    ];
    return open.isEmpty ? fields.length - 1 : open.first;
  }

  void _type(String letter) {
    if (widget.readOnly || fields.isEmpty) return;
    final i = _active();
    if (letter == ' ') {
      if (i < nodes.length - 1) nodes[i + 1].requestFocus();
      return;
    }
    final field = fields[i];
    final selection = field.selection;
    final start = selection.isValid ? selection.start : field.text.length;
    final end = selection.isValid ? selection.end : field.text.length;
    final text = field.text.replaceRange(start, end, letter);
    field.value = TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: start + 1));
    nodes[i].requestFocus();
    _edit(i, text);
  }

  void _backspace() {
    if (widget.readOnly || fields.isEmpty) return;
    var i = _active();
    var field = fields[i];
    var at = field.selection.isValid && field.selection.isCollapsed
        ? field.selection.start
        : field.text.length;
    if (at == 0 && i > 0) {
      i--;
      field = fields[i];
      at = field.text.length;
    }
    nodes[i].requestFocus();
    if (at == 0) return;
    final text = field.text.replaceRange(at - 1, at, '');
    field.value = TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: at - 1));
    _edit(i, text);
  }

  @override
  void dispose() {
    if (identical(widget.keys?._target, this)) widget.keys!._target = null;
    widget.controller?.removeListener(_externalChange);
    for (final field in fields) {
      field.dispose();
    }
    for (final node in nodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marker = widget.sentence.indexOf('____');
    if (marker < 0) return TitleText(widget.sentence, size: 29);
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(builder: (context, constraints) {
      final size = _fitSize(context, constraints.maxWidth, marker, scaler);
      return _sentence(context, constraints, marker, scaler, size);
    });
  }

  /// Largest font size whose layout, with blanks as wide as they will be
  /// drawn, stays within [ClozeSentence.fitLines] lines.
  double _fitSize(
      BuildContext context, double width, int marker, TextScaler scaler) {
    final lines = widget.fitLines;
    if (lines == null) return 29;
    final base = DefaultTextStyle.of(context).style;
    final direction = Directionality.of(context);
    for (var size = widget.maxFontSize; size > 14; size--) {
      final style = base.merge(
          TextStyle(fontSize: size, fontWeight: FontWeight.w800, height: 1.35));
      double measure(String text) {
        final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: direction,
            textScaler: scaler)
          ..layout();
        final result = painter.width;
        painter.dispose();
        return result;
      }

      final painter = TextPainter(
          text: TextSpan(style: style, children: [
            TextSpan(text: widget.sentence.substring(0, marker)),
            for (var i = 0; i < words.length; i++) ...[
              if (i > 0) const TextSpan(text: ' '),
              const WidgetSpan(
                  alignment: PlaceholderAlignment.bottom,
                  child: SizedBox.shrink()),
            ],
            TextSpan(text: widget.sentence.substring(marker + 4)),
          ]),
          textDirection: direction,
          textScaler: scaler)
        ..setPlaceholderDimensions([
          for (final word in words)
            PlaceholderDimensions(
                size: Size(math.min(width, math.max(48, measure(word) + 16)),
                    size * 1.65),
                alignment: PlaceholderAlignment.bottom)
        ])
        ..layout(maxWidth: width);
      final fits = painter.computeLineMetrics().length <= lines;
      painter.dispose();
      if (fits) return size;
    }
    return 14;
  }

  Widget _sentence(BuildContext context, BoxConstraints constraints, int marker,
      TextScaler scaler, double size) {
    final style = DefaultTextStyle.of(context).style.merge(TextStyle(
        fontSize: size, fontWeight: FontWeight.w800, color: ink, height: 1.35));
    double measure(String text) {
      final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: scaler)
        ..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    return Text.rich(
      TextSpan(children: [
        TextSpan(text: widget.sentence.substring(0, marker)),
        for (var i = 0; i < words.length; i++) ...[
          if (i > 0) const TextSpan(text: ' '),
          WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Container(
                key: ValueKey(
                    i == 0 ? 'cloze-answer-line' : 'cloze-answer-line-$i'),
                width: math.min(
                    constraints.maxWidth,
                    math.max(
                        48,
                        math.max(measure(words[i]), measure(fields[i].text)) +
                            16)),
                constraints: BoxConstraints(minHeight: size * 1.65),
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: teal, width: 2))),
                child: widget.controller == null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Text(
                            fields[i].text.isEmpty ? ' ' : fields[i].text,
                            style: style,
                            textAlign: TextAlign.center))
                    : Semantics(
                        label: '빈칸 ${i + 1} / ${words.length}',
                        child: TextField(
                          key: ValueKey('cloze-input-$i'),
                          controller: fields[i],
                          focusNode: nodes[i],
                          readOnly: widget.readOnly,
                          autocorrect: false,
                          enableSuggestions: false,
                          keyboardType: widget.keys == null
                              ? TextInputType.text
                              : TextInputType.none,
                          showCursor: true,
                          textCapitalization: TextCapitalization.none,
                          style: style,
                          textAlign: TextAlign.center,
                          textInputAction: i < words.length - 1
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onChanged: (value) => _edit(i, value),
                          onSubmitted: (_) {
                            if (widget.readOnly) return;
                            if (i < nodes.length - 1) {
                              nodes[i + 1].requestFocus();
                            } else {
                              widget.onSubmitted?.call();
                            }
                          },
                          decoration: const InputDecoration(
                              isDense: true,
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4)),
                        )),
              )),
        ],
        TextSpan(text: widget.sentence.substring(marker + 4)),
      ]),
      style: style,
      textScaler: scaler,
    );
  }
}
