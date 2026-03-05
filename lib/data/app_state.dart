// lib/data/app_state.dart
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Профиль
  String userName = 'Исследователь';
  int totalXP = 0;
  int level = 1;
  int questsCompleted = 0;
  int tasksCompleted = 0;
  int totalMinutes = 0;

  // Прогресс квестов: questId -> кол-во выполненных заданий
  final Map<String, int> _questProgress = {};
  // Завершённые квесты
  final Set<String> _completedQuests = {};

  int get xpForNextLevel => level * 200;
  double get levelProgress => totalXP / (level * 200);

  String get levelTitle {
    if (level >= 10) return 'Легенда Б-корпуса';
    if (level >= 7) return 'Мастер-исследователь';
    if (level >= 5) return 'Исследователь Б-корпуса';
    if (level >= 3) return 'Путешественник';
    return 'Новичок';
  }

  List<Achievement> get achievements => [
    Achievement('first_quest', 'Первые шаги', 'Завершить первый квест', Icons.flag_rounded, isUnlocked: questsCompleted >= 1),
    Achievement('explorer', 'Исследователь', 'Завершить 2 квеста', Icons.explore_rounded, isUnlocked: questsCompleted >= 2),
    Achievement('master', 'Мастер', 'Завершить все квесты', Icons.workspace_premium_rounded, isUnlocked: questsCompleted >= 3),
    Achievement('speedy', 'Спидраннер', 'Набрать 500 XP', Icons.bolt_rounded, isUnlocked: totalXP >= 500),
    Achievement('dedicated', 'Преданный', 'Выполнить 10 заданий', Icons.check_circle_rounded, isUnlocked: tasksCompleted >= 10),
  ];

  int getQuestProgress(String questId) => _questProgress[questId] ?? 0;
  bool isQuestCompleted(String questId) => _completedQuests.contains(questId);

  void updateQuestProgress(String questId, int completedTasks) {
    _questProgress[questId] = completedTasks;
    tasksCompleted = _questProgress.values.fold(0, (a, b) => a + b);
    notifyListeners();
  }

  void completeQuest(String questId, int xpReward, int durationMinutes) {
    if (!_completedQuests.contains(questId)) {
      _completedQuests.add(questId);
      questsCompleted++;
      totalXP += xpReward;
      totalMinutes += durationMinutes;
      _checkLevelUp();
      notifyListeners();
    }
  }

  void _checkLevelUp() {
    while (totalXP >= level * 200) {
      level++;
    }
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;

  const Achievement(this.id, this.title, this.description, this.icon, {this.isUnlocked = false});
}