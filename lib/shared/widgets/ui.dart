import 'package:flutter/material.dart';

const ink = Color(0xFF47342B),
    teal = Color(0xFF276A68),
    mint = Color(0xFFE6F2EB),
    paper = Color(0xFFFFF9EF),
    muted = Color(0xFF806D5F),
    peach = Color(0xFFF9DFC3),
    biscuit = Color(0xFFEAC17B),
    warmLine = Color(0xFFEADFCC);

enum PuppyPose {
  welcome('main_Character'),
  thinking('book_puppy'),
  cards('card_puppy'),
  disappointed('disappoint_puppy'),
  happy('happy_puppy'),
  studying('studying_puppy');

  final String filename;
  const PuppyPose(this.filename);
  String get asset => 'images/$filename.png';
}

class PuppyMascot extends StatelessWidget {
  final double size;
  final PuppyPose pose;
  const PuppyMascot(
      {super.key, this.size = 120, this.pose = PuppyPose.welcome});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: Image.asset(pose.asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          cacheWidth:
              (size * MediaQuery.devicePixelRatioOf(context).clamp(2, 4))
                  .ceil(),
          filterQuality: FilterQuality.medium));
}

class PuppyNote extends StatelessWidget {
  final String text;
  final PuppyPose pose;
  const PuppyNote(this.text, {super.key, this.pose = PuppyPose.studying});
  @override
  Widget build(BuildContext context) => Row(children: [
        PuppyMascot(size: 64, pose: pose),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style:
                    const TextStyle(color: ink, fontWeight: FontWeight.w600))),
      ]);
}

class PageBody extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  const PageBody(
      {super.key,
      required this.children,
      this.padding = const EdgeInsets.fromLTRB(22, 12, 22, 28)});
  @override
  Widget build(BuildContext context) => SafeArea(
      child: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                  padding: padding,
                  children: children))));
}

class Panel extends StatelessWidget {
  final Widget child;
  final Color color;
  const Panel({super.key, required this.child, this.color = Colors.white});
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A70492C), blurRadius: 16, offset: Offset(0, 5))
          ],
          border: Border.all(color: color == Colors.white ? warmLine : color)),
      child: child);
}

class TitleText extends StatelessWidget {
  final String text;
  final double size;
  const TitleText(this.text, {super.key, this.size = 26});
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: ink,
          height: 1.35));
}

class Label extends StatelessWidget {
  final String text;
  const Label(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: teal,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4));
}

class Tag extends StatelessWidget {
  final String text;

  /// Warm colours for something that needs attention, e.g. an often-missed word.
  final bool warm;
  const Tag(this.text, {super.key, this.warm = false});
  @override
  Widget build(BuildContext context) => Align(
      alignment: Alignment.centerLeft,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: warm ? const Color(0xFFFFEEDB) : mint,
              borderRadius: BorderRadius.circular(30)),
          child: Text(text,
              style: TextStyle(
                  fontSize: 11,
                  color: warm ? const Color(0xFFB0721E) : teal,
                  fontWeight: FontWeight.w700))));
}

class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const ActionButton(this.text, {super.key, required this.onPressed});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      child: FilledButton(
          onPressed: onPressed,
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(text, textAlign: TextAlign.center))));
}
