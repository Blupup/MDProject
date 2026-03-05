// lib/data/quest_data.dart
//
// ═══════════════════════════════════════════════════════════════════════════
//  КАК РЕДАКТИРОВАТЬ КВЕСТЫ — ЧИТАЙ СЮДА 👇
// ═══════════════════════════════════════════════════════════════════════════
//
//  Каждое задание (QuestTask) содержит:
//
//  title         — короткое название задания
//  description   — основной текст, что нужно сделать
//  hint          — текст подсказки (появляется при нажатии 💡)
//  location      — название места (показывается под заголовком)
//
//  locationStory — БОЛЬШОЕ описание места которое читает студент.
//                  ✏️ ЭТО ТЫ МЕНЯЕШЬ САМИ. Расскажи историю места,
//                  факты, что интересного. Несколько предложений — хорошо.
//
//  locationPhoto — путь к фото места.
//                  📸 КАК ДОБАВИТЬ СВОЁ ФОТО:
//                  1. Создай папку assets/images/ в корне проекта
//                  2. Положи туда своё фото (например entrance.jpg)
//                  3. Открой pubspec.yaml, найди раздел flutter: и добавь:
//                       flutter:
//                         assets:
//                           - assets/images/entrance.jpg
//                  4. Укажи здесь: locationPhoto: 'assets/images/entrance.jpg'
//                  Если фото нет — оставь null.
//
//  miniGameItems — список слов для мини-игры (4–6 слов).
//                  ✏️ МЕНЯЙ как хочешь.
//
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

enum MiniGameType { none, disappeared }

class QuestData {
  static final List<Quest> quests = [

    // КВЕСТ 1
    const Quest(
      id: 'quest_1',
      title: 'Знакомство с Б-корпусом',
      description: 'Пройди вводный квест — найди главные места и почувствуй себя как дома!',
      duration: '30 мин', difficulty: 'Новичок', difficultyLevel: 1,
      taskCount: 3, xpReward: 150, emoji: '🗺️',
      tasks: [
        QuestTask(
          number: 1, title: 'Главный вход',
          description: 'Найди главный вход Б-корпуса и встань под вывеской',
          hint: 'Большая стеклянная дверь с надписью «Б-корпус» на первом этаже',
          location: 'Главный вход, 1 этаж',
          icon: Icons.door_front_door_rounded,
          // ✏️ МЕНЯЙ — описание места:
          locationStory: 'Главный вход — это сердце Б-корпуса. Именно здесь каждое утро тысячи студентов начинают свой день. Обрати внимание на вывеску над дверью и информационный стенд справа.',
          // 📸 МЕНЯЙ — путь к фото: 'assets/images/entrance.jpg'
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
        ),
        QuestTask(
          number: 2, title: 'Компьютерный класс',
          description: 'Найди аудиторию 115 — компьютерный класс в правом крыле',
          hint: 'Пройди мимо раздевалки по правому коридору — класс будет после куллера',
          location: '1 этаж, ауд. 115',
          icon: Icons.computer_rounded,
          // ✏️ МЕНЯЙ — описание места:
          locationStory: 'Аудитория 115 — компьютерный класс на 24 рабочих места. Здесь проходят практические занятия по программированию и работе с программным обеспечением.',
          // 📸 МЕНЯЙ — путь к фото: 'assets/images/computer_lab.jpg'
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
        ),
        QuestTask(
          number: 3, title: 'Коворкинг',
          description: 'Найди коворкинг — пространство для командной работы студентов',
          hint: 'Ауд. 104, по центральному коридору прямо от главного входа',
          location: '1 этаж, ауд. 104',
          icon: Icons.groups_rounded,
          // ✏️ МЕНЯЙ — описание места:
          locationStory: 'Коворкинг в ауд. 104 — любимое место студентов для групповой работы. Здесь есть удобные столы, маркерные доски и быстрый Wi-Fi. Пространство открыто с 8:00 до 22:00.',
          // 📸 МЕНЯЙ — путь к фото: 'assets/images/coworking.jpg'
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
        ),
      ],
    ),

    // КВЕСТ 2
    const Quest(
      id: 'quest_2',
      title: 'Исторический маршрут',
      description: 'Погрузись в историю университета — найди памятные места и реликвии',
      duration: '60 мин', difficulty: 'Средний', difficultyLevel: 2,
      taskCount: 4, xpReward: 300, emoji: '📜',
      tasks: [
        QuestTask(
          number: 1, title: 'Мемориальная доска',
          description: 'Найди мемориальную доску основателям — запомни все детали!',
          hint: 'Ищи у главного входа на стене слева',
          location: 'Главный холл, 1 этаж',
          icon: Icons.history_edu_rounded,
          // ✏️ МЕНЯЙ — описание места:
          locationStory: 'Мемориальная доска установлена в 1975 году в честь основателей нашего факультета. На ней выгравированы имена первых профессоров и дата основания кафедры.',
          // 📸 МЕНЯЙ — путь к фото: 'assets/images/memorial_board.jpg'
          locationPhoto: null,
          miniGameType: MiniGameType.disappeared,
          // ✏️ МЕНЯЙ — слова для мини-игры:
          miniGameItems: ['Доска', 'Портрет', 'Надпись', 'Дата', 'Имя', 'Фамилия'],
        ),
        QuestTask(
          number: 2, title: 'Актовый зал',
          description: 'Найди главный актовый зал, где проходят все важные события',
          hint: 'Большое помещение со сценой на 2 этаже, левое крыло',
          location: '2 этаж, левое крыло',
          icon: Icons.theaters_rounded,
          // ✏️ МЕНЯЙ — описание места:
          locationStory: 'Актовый зал вмещает более 300 человек. Здесь проходят все торжественные мероприятия: посвящение в студенты, вручение дипломов и научные конференции.',
          // 📸 МЕНЯЙ — путь к фото: 'assets/images/assembly_hall.jpg'
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
        ),
        QuestTask(
          number: 3, title: 'Фотогалерея',
          description: 'Найди историческую галерею фотографий выпускников',
          hint: 'На втором этаже рядом с актовым залом вдоль коридора',
          location: '2 этаж, коридор',
          icon: Icons.photo_library_rounded,
          // ✏️ МЕНЯЙ — описание места:
          locationStory: 'Вдоль коридора развешены фотографии лучших выпускников разных лет с 1960-х до наших дней. Может быть, однажды и твоё фото окажется на этой стене!',
          // 📸 МЕНЯЙ — путь к фото: 'assets/images/photo_gallery.jpg'
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
        ),
        QuestTask(
          number: 4, title: 'Памятник',
          description: 'Найди памятник выдающемуся учёному перед зданием',
          hint: 'Выйди на площадь перед Б-корпусом',
          location: 'Площадь перед входом',
          icon: Icons.account_balance_rounded,
          // ✏️ МЕНЯЙ — описание места:
          locationStory: 'Перед Б-корпусом установлен памятник выдающемуся учёному. Это традиционное место для фотографий на память — студенты фотографируются здесь после защиты диплома.',
          // 📸 МЕНЯЙ — путь к фото: 'assets/images/monument.jpg'
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
        ),
      ],
    ),

    // КВЕСТ 3
    const Quest(
      id: 'quest_3',
      title: 'Технический детектив',
      description: 'Исследуй лаборатории, найди скрытые артефакты и реши загадки корпуса',
      duration: '45 мин', difficulty: 'Сложный', difficultyLevel: 3,
      taskCount: 3, xpReward: 450, emoji: '🔬',
      tasks: [
        QuestTask(
          number: 1, title: 'Серверная комната',
          description: 'Найди место, где хранится «мозг» всего корпуса',
          hint: 'Прислушайся — её выдаёт гул вентиляторов. Обычно в техническом крыле',
          location: 'Тех. помещение',
          icon: Icons.dns_rounded,
          // ✏️ МЕНЯЙ — описание места:
          locationStory: 'Серверная — сердце цифровой инфраструктуры Б-корпуса. Здесь работают серверы, которые обеспечивают Wi-Fi и учебные системы. Температура поддерживается на уровне 18–20°C.',
          // 📸 МЕНЯЙ — путь к фото: 'assets/images/server_room.jpg'
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
        ),
        QuestTask(
          number: 2, title: 'Лаборатория 3D-печати',
          description: 'Найди лабораторию 312 с 3D-принтерами — запомни детали оборудования!',
          hint: 'Ауд. 312 на 3 этаже',
          location: '3 этаж, ауд. 312',
          icon: Icons.precision_manufacturing_rounded,
          // ✏️ МЕНЯЙ — описание места:
          locationStory: 'Лаборатория ауд. 312 оснащена профессиональными 3D-принтерами. Студенты печатают здесь прототипы для дипломных работ. Открыта в 2019 году благодаря университетскому гранту.',
          // 📸 МЕНЯЙ — путь к фото: 'assets/images/3d_lab.jpg'
          locationPhoto: null,
          miniGameType: MiniGameType.disappeared,
          // ✏️ МЕНЯЙ — слова для мини-игры:
          miniGameItems: ['Принтер', 'Филамент', 'Слайсер', 'Модель', 'Стол', 'Сопло'],
        ),
        QuestTask(
          number: 3, title: 'Стена достижений',
          description: 'Найди стену с дипломами и наградами студентов',
          hint: 'Обычно у деканата на 2 этаже',
          location: '2 этаж, деканат',
          icon: Icons.emoji_events_rounded,
          // ✏️ МЕНЯЙ — описание места:
          locationStory: 'Стена достижений — гордость факультета. Здесь дипломы победителей олимпиад, грамоты за научные работы и кубки. Самый старый диплом датирован 1982 годом.',
          // 📸 МЕНЯЙ — путь к фото: 'assets/images/achievement_wall.jpg'
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
        ),
      ],
    ),

  ];
}

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
  final List<String> miniGameItems;
  final String? locationStory;   // описание места — МЕНЯЙ ТЕКСТ
  final String? locationPhoto;   // путь к фото — 'assets/images/...'

  bool get hasMiniGame => miniGameType == MiniGameType.disappeared;

  const QuestTask({
    required this.number, required this.title, required this.description,
    required this.hint, required this.location, required this.icon,
    required this.miniGameType, required this.miniGameItems,
    this.locationStory, this.locationPhoto,
  });
}