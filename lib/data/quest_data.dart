// lib/data/quest_data.dart
import 'package:flutter/material.dart';

enum MiniGameType { none, disappeared }

class QuestData {
  static final List<Quest> quests = [
    Quest(
      id: 'quest_1',
      title: 'Знакомство с Б-корпусом',
      description: 'Пройди вводный квест — найди главные места и почувствуй себя как дома!',
      duration: '30 мин', difficulty: 'Новичок', difficultyLevel: 1,
      taskCount: 3, xpReward: 150, emoji: '🗺️',
      tasks: [
        QuestTask(number: 1, title: 'Главный вход',
          description: 'Найди главный вход Б-корпуса и встань под вывеской',
          hint: 'Большая стеклянная дверь с надписью «Б-корпус» на первом этаже',
          location: 'Главный вход, 1 этаж', icon: Icons.door_front_door_rounded,
          miniGameType: MiniGameType.none, miniGameItems: []),
        QuestTask(number: 2, title: 'Компьютерный класс',
          description: 'Найди аудиторию 115 — компьютерный класс в правом крыле',
          hint: 'Пройди мимо раздевалки по правому коридору — класс будет после куллера',
          location: '1 этаж, ауд. 115', icon: Icons.computer_rounded,
          miniGameType: MiniGameType.none, miniGameItems: []),
        QuestTask(number: 3, title: 'Коворкинг',
          description: 'Найди коворкинг — пространство для командной работы студентов',
          hint: 'Ауд. 104, по центральному коридору прямо от главного входа',
          location: '1 этаж, ауд. 104', icon: Icons.groups_rounded,
          miniGameType: MiniGameType.none, miniGameItems: []),
      ],
    ),
    Quest(
      id: 'quest_2',
      title: 'Исторический маршрут',
      description: 'Погрузись в историю университета — найди памятные места и реликвии',
      duration: '60 мин', difficulty: 'Средний', difficultyLevel: 2,
      taskCount: 4, xpReward: 300, emoji: '📜',
      tasks: [
        QuestTask(number: 1, title: 'Мемориальная доска',
          description: 'Найди мемориальную доску основателям — запомни все детали!',
          hint: 'Ищи у главного входа на стене слева',
          location: 'Главный холл, 1 этаж', icon: Icons.history_edu_rounded,
          miniGameType: MiniGameType.disappeared,
          miniGameItems: ['Доска', 'Портрет', 'Надпись', 'Дата', 'Имя', 'Фамилия']),
        QuestTask(number: 2, title: 'Актовый зал',
          description: 'Найди главный актовый зал, где проходят все важные события',
          hint: 'Большое помещение со сценой на 2 этаже, левое крыло',
          location: '2 этаж, левое крыло', icon: Icons.theaters_rounded,
          miniGameType: MiniGameType.none, miniGameItems: []),
        QuestTask(number: 3, title: 'Фотогалерея',
          description: 'Найди историческую галерею фотографий выпускников',
          hint: 'На втором этаже рядом с актовым залом вдоль коридора',
          location: '2 этаж, коридор', icon: Icons.photo_library_rounded,
          miniGameType: MiniGameType.none, miniGameItems: []),
        QuestTask(number: 4, title: 'Памятник',
          description: 'Найди памятник выдающемуся учёному перед зданием',
          hint: 'Выйди на площадь перед Б-корпусом',
          location: 'Площадь перед входом', icon: Icons.account_balance_rounded,
          miniGameType: MiniGameType.none, miniGameItems: []),
      ],
    ),
    Quest(
      id: 'quest_3',
      title: 'Технический детектив',
      description: 'Исследуй лаборатории, найди скрытые артефакты и реши загадки корпуса',
      duration: '45 мин', difficulty: 'Сложный', difficultyLevel: 3,
      taskCount: 3, xpReward: 450, emoji: '🔬',
      tasks: [
        QuestTask(number: 1, title: 'Серверная комната',
          description: 'Найди место, где хранится «мозг» всего корпуса',
          hint: 'Прислушайся — её выдаёт гул вентиляторов. Обычно в техническом крыле',
          location: 'Тех. помещение', icon: Icons.dns_rounded,
          miniGameType: MiniGameType.none, miniGameItems: []),
        QuestTask(number: 2, title: 'Лаборатория 3D-печати',
          description: 'Найди лабораторию 312 с 3D-принтерами — запомни детали оборудования!',
          hint: 'Ауд. 312 на 3 этаже',
          location: '3 этаж, ауд. 312', icon: Icons.precision_manufacturing_rounded,
          miniGameType: MiniGameType.disappeared,
          miniGameItems: ['Принтер', 'Филамент', 'Слайсер', 'Модель', 'Стол', 'Сопло']),
        QuestTask(number: 3, title: 'Стена достижений',
          description: 'Найди стену с дипломами и наградами студентов',
          hint: 'Обычно у деканата на 2 этаже',
          location: '2 этаж, деканат', icon: Icons.emoji_events_rounded,
          miniGameType: MiniGameType.none, miniGameItems: []),
      ],
    ),
  ];
}

class Quest {
  final String id, title, description, duration, difficulty, emoji;
  final int difficultyLevel, taskCount, xpReward;
  final List<QuestTask> tasks;
  const Quest({required this.id, required this.title, required this.description,
    required this.duration, required this.difficulty, required this.difficultyLevel,
    required this.taskCount, required this.xpReward, required this.emoji, required this.tasks});
}

class QuestTask {
  final int number;
  final String title, description, hint, location;
  final IconData icon;
  final MiniGameType miniGameType;
  final List<String> miniGameItems;
  bool get hasMiniGame => miniGameType == MiniGameType.disappeared;
  const QuestTask({required this.number, required this.title, required this.description,
    required this.hint, required this.location, required this.icon,
    required this.miniGameType, required this.miniGameItems});
}