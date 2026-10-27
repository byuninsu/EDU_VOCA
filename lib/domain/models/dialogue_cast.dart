import 'dart:math';

/// Cast is chosen once per question, shared by practice and answer views.
class DialogueCast {
  final String partner, learner;
  const DialogueCast(this.partner, this.learner);

  static const maleNames = [
    'Sam',
    'Tomas',
    'Samuel',
    'Oliver',
    'James',
    'William',
    'Henry',
    'Noah',
    'Liam',
    'Ethan',
    'Lucas',
    'Daniel',
    'Benjamin',
    'Jack',
    'Leo',
    'Alexander',
    'David',
    'Nathan',
    'Ryan',
    'Matthew',
  ];
  static const femaleNames = [
    'Sally',
    'Emma',
    'Olivia',
    'Sophia',
    'Isabella',
    'Amelia',
    'Charlotte',
    'Emily',
    'Grace',
    'Lily',
    'Chloe',
    'Lucy',
    'Hannah',
    'Ella',
    'Alice',
    'Clara',
    'Julia',
    'Sophie',
    'Rose',
    'Victoria',
  ];
  static final _random = Random();

  factory DialogueCast.random({DialogueCast? previous}) {
    String pick(List<String> names) {
      final candidates = names
          .where(
              (name) => name != previous?.partner && name != previous?.learner)
          .toList();
      return candidates[_random.nextInt(candidates.length)];
    }

    final male = pick(maleNames);
    final female = pick(femaleNames);
    return _random.nextBool()
        ? DialogueCast(male, female)
        : DialogueCast(female, male);
  }
}
