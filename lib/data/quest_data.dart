// lib/data/quest_data.dart
//
// ═══════════════════════════════════════════════════════════════════════════
//  ГДЕ ВСТАВИТЬ СВОИ ФОТОГРАФИИ — ПОЛНАЯ ИНСТРУКЦИЯ
// ═══════════════════════════════════════════════════════════════════════════
//
//  Шаг 1: Создай папку assets/images/ в корне проекта.
//
//  Шаг 2: Брось туда все свои фото. Рекомендуемые имена:
//    Для мест квеста:  location_entrance.jpg, location_lab.jpg, ...
//    Для игры «Пары»:  pairs_1.jpg, pairs_2.jpg, pairs_3.jpg, pairs_4.jpg
//    Для «Пятнашки»:   puzzle_entrance.jpg, puzzle_lab.jpg, ...
//
//  Шаг 3: Открой pubspec.yaml, найди раздел flutter: и добавь:
//    flutter:
//      assets:
//        - assets/images/location_entrance.jpg
//        - assets/images/pairs_1.jpg
//        - assets/images/puzzle_entrance.jpg
//        ... (каждый файл отдельной строкой)
//
//  Шаг 4: Замени null на путь к фото в нужном поле (см. ниже).
//
// ───────────────────────────────────────────────────────────────────────────
//  В КАЖДОМ ЗАДАНИИ (QuestTask) есть 3 поля для фото:
//
//  locationPhoto  — фото места которое нужно найти (показывается на экране
//                   задания). Пример: 'assets/images/location_entrance.jpg'
//
//  pairPhotos     — список фото для игры «Найди пары». Нужно 4–6 штук.
//                   Каждое фото = одна пара карточек.
//                   Пример: ['assets/images/pairs_1.jpg',
//                             'assets/images/pairs_2.jpg', ...]
//
//  puzzlePhoto    — одно фото для игры «Пятнашки». Оно нарежется на 12
//                   кусочков (3×4) и перемешается.
//                   Пример: 'assets/images/puzzle_entrance.jpg'
//
//  Если поле = null — игра работает с цветными заглушками (для тестирования).
// ═══════════════════════════════════════════════════════════════════════════

// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

enum MiniGameType { none, disappeared }

class QuestData {
  static final List<Quest> quests = [

    // ════════════════════════════════════════════════════════════════════════
    //  КВЕСТ 1
    // ════════════════════════════════════════════════════════════════════════
    Quest(
      id: 'quest_1',
      title: 'Знакомство с Б-корпусом',
      description: 'Пройди вводный квест — найди главные места и почувствуй себя как дома!',
      duration: '30 мин', difficulty: 'Новичок', difficultyLevel: 1,
      taskCount: 3, xpReward: 150, emoji: '🗺️',
      tasks: [

        QuestTask(
          number: 1,
          title: 'Главный вход',
          description: 'Найди главный вход Б-корпуса и встань под вывеской',
          hint: 'Большая стеклянная дверь с надписью «Б-корпус» на первом этаже',
          location: 'Главный вход, 1 этаж',
          icon: Icons.door_front_door_rounded,
          // ✏️ Описание места (текст под фото):
          locationStory: 'Главный вход — сердце Б-корпуса. Здесь каждый день начинается путь тысяч студентов. Обрати внимание на вывеску и информационный стенд справа.',
          // 📸 Фото места (меняй на свой путь):
          locationPhoto: null,  // ← замени: 'assets/images/location_entrance.jpg'
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          // 🃏 Фото для игры «Найди пары» (нужно 4–6 фото):
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],  // ← замени: ['assets/images/pairs_1.jpg', 'assets/images/pairs_2.jpg', ...]
          // 🧩 Фото для игры «Пятнашки» (одно фото):
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',  // ← замени: 'assets/images/puzzle_entrance.jpg'
        ),

        QuestTask(
          number: 2,
          title: 'Компьютерный класс',
          description: 'Найди аудиторию 115 — компьютерный класс в правом крыле',
          hint: 'Пройди мимо раздевалки по правому коридору — класс будет после куллера',
          location: '1 этаж, ауд. 115',
          icon: Icons.computer_rounded,
          // ✏️ Описание места:
          locationStory: 'Аудитория 115 — компьютерный класс на 24 места. Здесь проходят практические занятия по программированию.',
          // 📸 Фото места:
          locationPhoto: null,  // ← 'assets/images/location_computer_lab.jpg'
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 3,
          title: 'Коворкинг',
          description: 'Найди коворкинг — пространство для командной работы студентов',
          hint: 'Ауд. 104, по центральному коридору прямо от главного входа',
          location: '1 этаж, ауд. 104',
          icon: Icons.groups_rounded,
          // ✏️ Описание места:
          locationStory: 'Коворкинг 104 — любимое место студентов. Удобные столы, маркерные доски, быстрый Wi-Fi. Открыт с 8:00 до 22:00.',
          // 📸 Фото места:
          locationPhoto: null,  // ← 'assets/images/location_coworking.jpg'
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

      ],
    ),

    // ════════════════════════════════════════════════════════════════════════
    //  КВЕСТ 2
    // ════════════════════════════════════════════════════════════════════════
    Quest(
      id: 'quest_2',
      title: 'Исторический маршрут',
      description: 'Погрузись в историю университета — найди памятные места и реликвии',
      duration: '60 мин', difficulty: 'Средний', difficultyLevel: 2,
      taskCount: 4, xpReward: 300, emoji: '📜',
      tasks: [

        QuestTask(
          number: 1,
          title: 'Мемориальная доска',
          description: 'Найди мемориальную доску основателям — запомни все детали!',
          hint: 'Ищи у главного входа на стене слева',
          location: 'Главный холл, 1 этаж',
          icon: Icons.history_edu_rounded,
          // ✏️ Описание места:
          locationStory: 'Мемориальная доска установлена в 1975 году. На ней выгравированы имена первых профессоров и дата основания кафедры.',
          // 📸 Фото места:
          locationPhoto: null,  // ← 'assets/images/location_memorial.jpg'
          miniGameType: MiniGameType.disappeared,
          // ✏️ Предметы для игры «Найди исчезнувшее»:
          miniGameItems: ['Доска', 'Портрет', 'Надпись', 'Дата', 'Имя', 'Фамилия'],
          // 🃏 Фото для «Найди пары» — добавь 4–6 фото (например фото деталей доски):
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          // 🧩 Фото для «Пятнашки»:
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',  // ← 'assets/images/puzzle_memorial.jpg'
        ),

        QuestTask(
          number: 2,
          title: 'Актовый зал',
          description: 'Найди главный актовый зал, где проходят все важные события',
          hint: 'Большое помещение со сценой на 2 этаже, левое крыло',
          location: '2 этаж, левое крыло',
          icon: Icons.theaters_rounded,
          locationStory: 'Актовый зал вмещает 300+ человек. Здесь проходят посвящение в студенты, вручение дипломов, конференции.',
          locationPhoto: null,  // ← 'assets/images/location_hall.jpg'
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 3,
          title: 'Фотогалерея',
          description: 'Найди историческую галерею фотографий выпускников',
          hint: 'На втором этаже рядом с актовым залом вдоль коридора',
          location: '2 этаж, коридор',
          icon: Icons.photo_library_rounded,
          locationStory: 'Фотографии лучших выпускников с 1960-х до наших дней. Может быть, однажды и твоё фото окажется здесь!',
          locationPhoto: null,  // ← 'assets/images/location_gallery.jpg'
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 4,
          title: 'Памятник',
          description: 'Найди памятник выдающемуся учёному перед зданием',
          hint: 'Выйди на площадь перед Б-корпусом',
          location: 'Площадь перед входом',
          icon: Icons.account_balance_rounded,
          locationStory: 'Традиционное место для фото на память. Студенты фотографируются здесь после защиты диплома.',
          locationPhoto: null,  // ← 'assets/images/location_monument.jpg'
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

      ],
    ),

    // ════════════════════════════════════════════════════════════════════════
    //  КВЕСТ 3
    // ════════════════════════════════════════════════════════════════════════
    Quest(
      id: 'quest_3',
      title: 'Технический детектив',
      description: 'Исследуй лаборатории, найди скрытые артефакты и реши загадки корпуса',
      duration: '45 мин', difficulty: 'Сложный', difficultyLevel: 3,
      taskCount: 3, xpReward: 450, emoji: '🔬',
      tasks: [

        QuestTask(
          number: 1,
          title: 'Серверная комната',
          description: 'Найди место, где хранится «мозг» всего корпуса',
          hint: 'Прислушайся — её выдаёт гул вентиляторов. Обычно в техническом крыле',
          location: 'Тех. помещение',
          icon: Icons.dns_rounded,
          locationStory: 'Серверная — цифровое сердце Б-корпуса. Серверы обеспечивают Wi-Fi и учебные системы. Температура держится 18–20°C.',
          locationPhoto: null,  // ← 'assets/images/location_server.jpg'
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 2,
          title: 'Лаборатория 3D-печати',
          description: 'Найди лабораторию 4хх с 3D-принтерами — запомни детали оборудования!',
          hint: 'Ауд. 312 на 3 этаже',
          location: '3 этаж, ауд. 312',
          icon: Icons.precision_manufacturing_rounded,
          locationStory: 'Лаборатория ауд. 4хх — профессиональные 3D-принтеры для студенческих проектов. Открыта в 2019 году.',
          locationPhoto: null,  // ← 'assets/images/location_3dlab.jpg'
          miniGameType: MiniGameType.disappeared,
          // ✏️ Предметы для «Найди исчезнувшее»:
          miniGameItems: ['Принтер', 'Филамент', 'Слайсер', 'Модель', 'Стол', 'Сопло'],
          // 🃏 Фото для «Найди пары» (фото деталей лаборатории):
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],  // ← ['assets/images/pairs_lab1.jpg', 'assets/images/pairs_lab2.jpg', ...]
          // 🧩 Фото для «Пятнашки»:
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',  // ← 'assets/images/puzzle_lab.jpg'
        ),

        QuestTask(
          number: 3,
          title: 'Стена достижений',
          description: 'Найди стену с дипломами и наградами студентов',
          hint: 'Обычно у деканата на 2 этаже',
          location: '2 этаж, деканат',
          icon: Icons.emoji_events_rounded,
          locationStory: 'Стена достижений — гордость факультета. Дипломы олимпиад, кубки, грамоты. Самый старый диплом — 1982 год.',
          locationPhoto: null,  // ← 'assets/images/location_achievements.jpg'
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

      ],
    ),

  ];
}

// ─── Модели ──────────────────────────────────────────────────────────────
class Quest {
  final String id, title, description, duration, difficulty, emoji;
  final int difficultyLevel, taskCount, xpReward;
  final List<QuestTask> tasks;
  const Quest({
    required this.id, required this.title, required this.description,
    required this.duration, required this.difficulty, required this.difficultyLevel,
    required this.taskCount, required this.xpReward, required this.emoji, required this.tasks,
  });
}

class QuestTask {
  final int number;
  final String title, description, hint, location;
  final IconData icon;
  final MiniGameType miniGameType;

  // ── Предметы для игры «Найди исчезнувшее» ────────────────────────────────
  final List<String> miniGameItems;

  // ── Фото для игры «Найди исчезнувшее» ────────────────────────────────────
  // ✏️ Если указаны — вместо слов показываются фотографии (нужно 4–6 штук).
  // Пример: disappearedPhotos: ['assets/images/item1.jpg', 'assets/images/item2.jpg', ...]
  // Если пусто — игра работает со словами из miniGameItems (как раньше).
  final List<String> disappearedPhotos;

  // ── Фото места (показывается на экране задания) ───────────────────────────
  // ✏️ МЕНЯЙ: locationPhoto = 'assets/images/location_entrance.jpg'
  final String? locationPhoto;

  // ── Текст описания места ──────────────────────────────────────────────────
  // ✏️ МЕНЯЙ: расскажи что интересного в этом месте
  final String? locationStory;

  // ── Фото для игры «Найди пары» ────────────────────────────────────────────
  // ✏️ МЕНЯЙ: добавь 4–6 путей к фото
  // Каждое фото = одна пара карточек
  // Пример: ['assets/images/pairs_1.jpg', 'assets/images/pairs_2.jpg', ...]
  final List<String> pairPhotos;

  // ── Фото для игры «Пятнашки» ─────────────────────────────────────────────
  // ✏️ МЕНЯЙ: одно фото, которое нарежется на 12 кусочков
  // Пример: puzzlePhoto = 'assets/images/puzzle_entrance.jpg'
  final String? puzzlePhoto;

  bool get hasMiniGame => miniGameType == MiniGameType.disappeared;

  // Возвращает фото или слова для игры «Найди исчезнувшее»
  // Если disappearedPhotos не пустой — использует фото, иначе — miniGameItems
  List<String> get disappearedItems =>
      disappearedPhotos.isNotEmpty ? disappearedPhotos : miniGameItems;

  // Для игр: преобразует puzzlePhoto/pairPhotos в List<String>
  List<String> get puzzlePhotos => puzzlePhoto != null ? [puzzlePhoto!] : [];

  const QuestTask({
    required this.number, required this.title, required this.description,
    required this.hint, required this.location, required this.icon,
    required this.miniGameType, required this.miniGameItems,
    this.locationPhoto, this.locationStory,
    this.pairPhotos = const [],
    this.puzzlePhoto,
    this.disappearedPhotos = const [],
  });
}