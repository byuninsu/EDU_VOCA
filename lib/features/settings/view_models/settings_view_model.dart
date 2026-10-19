import 'package:flutter/foundation.dart';
import 'package:edu_voca/features/learning/view_models/learning_view_model.dart';

class SettingsViewModel extends ChangeNotifier {
  final LearningViewModel learning;
  int goal, level;
  SettingsViewModel(this.learning)
      : goal = learning.dailyGoal,
        level = learning.level;
  void setGoal(int value) {
    goal = value.clamp(5, 30);
    notifyListeners();
  }

  void setLevel(int value) {
    level = value.clamp(1, 20);
    notifyListeners();
  }

  void save() => learning.settings(goal,
      startingLevel: level == learning.level ? null : level);
}
