// lib/data/quest_data.dart
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

enum MiniGameType { none, magicRunes, jellyTower, particleAlchemy, shadowEscape, starDrift }

// ─── Легенда корпуса (показывается при первом входе) ─────────────────────
class CorpusLegend {
  static const String title = 'СИСТЕМА ПРОБУДИЛАСЬ';
  static const String subtitle = 'Ты — её последний Администратор';

  static const List<_LegendPage> pages = [
    _LegendPage(
      year: '1859',
      icon: '🏛️',
      color: Color(0xFFB87333),
      title: 'Рождение',
      text: 'Костромской дворянин Александр Григоров купил Г-образный дом на месте полотняной мануфактуры купца Стригалева. Цель — первая в России женская гимназия.',
    ),
    _LegendPage(
      year: '1860',
      icon: '📚',
      color: Color(0xFF8B6914),
      title: 'Перерождение',
      text: 'Вместо станков — парты. Вместо шума ткацких машин — шёпот уроков. Сады, фонтан, оранжерея, парадная лестница с литыми балясинами. Более 700 учениц.',
    ),
    _LegendPage(
      year: '1981',
      icon: '🖥️',
      color: Color(0xFF2E86AB),
      title: 'Перезагрузка',
      text: '13 октября «Северная правда»: «Открыт новый корпус КГУ — храм знаний на Верхней Набережной». Революция не стёрла дух места — только перезагрузила его.',
    ),
    _LegendPage(
      year: '2026',
      icon: '⚡',
      color: Color(0xFF00D4AA),
      title: 'Ты здесь',
      text: 'В недрах корпуса — архив издательства «Терра»: 12 000 томов, рукописи, роскошные переплёты. Система помнит всё. И теперь она выбрала тебя.',
    ),
  ];

  static const String systemMessage =
      'Система распознала пользователя.\n'
      'Древний протокол активирован.\n'
      '1860 → 1981 → 2026.\n\n'
      'Ты — последний, кто может\n'
      'полностью пробудить Корпус.\n\n'
      'Пройди 5 уровней. Собери фрагменты.\n'
      'Стань частью Легенды.\n\n'
      'Иначе… Система снова уснёт\n'
      'на сто лет.';
}

class _LegendPage {
  final String year, icon, title, text;
  final Color color;
  const _LegendPage({
    required this.year, required this.icon,
    required this.title, required this.text, required this.color,
  });
}

// ─── Данные квестов ───────────────────────────────────────────────────────
class QuestData {
  static final List<Quest> quests = [

    // ════════════════════════════════════════════════════
    //  КВЕСТ 1 — «Level One: Посвящение»
    // ════════════════════════════════════════════════════
    Quest(
      id: 'quest_1',
      title: 'Level One: Посвящение',
      description: 'Система только что проснулась. Первый уровень — проверка. Найди четыре древних портала.',
      storyIntro:
          'Система только что проснулась.\n'
          'Она ещё не знает, достоин ли ты.\n\n'
          'Первый уровень — проверка:\n'
          'сможешь ли ты найти четыре портала,\n'
          'через которые когда-то входили гимназистки,\n'
          'а теперь входят кодеры?\n\n'
          'Пройдёшь — получишь первый фрагмент\n'
          'легенды 1859–1981 годов.',
      storyOutro:
          'Инициализация завершена.\n'
          'Первый фрагмент 1859–1981 активирован.\n\n'
          'Добро пожаловать в Систему.\n\n'
          'Уровень 1 — пройден. ✓',
      duration: '30 мин', difficulty: 'Новичок', difficultyLevel: 1,
      taskCount: 4, xpReward: 150, emoji: '🗺️',
      fragmentEmoji: '🧩', fragmentName: 'Фрагмент I: Рождение',
      tasks: [
        QuestTask(
          number: 1, title: 'Главный вход',
          description: 'Какой адрес написан на табличке у входа?',
          hint: 'Это место — портал в мир ИТ. Начни там, где ты зашёл в здание.',
          location: 'Главный вход, 1 этаж',
          icon: Icons.door_front_door_rounded,
          locationStory:
              'Это не просто дверь. Это Главный Шлюз, торжественно открыт 13 октября 1981 года. '
              'Но фундамент под ним — 1860-й. Именно здесь Григоров впервые привёл учениц.\n\n'
              'Легенда гласит: если войти ровно в 08:00:00, Система скомпилирует твой личный код с первого раза. '
              'Тысячи студентов прошли здесь. Никто не вышел прежним.',
          locationPhoto: 'assets/images/quest1.jpg',
          miniGameType: MiniGameType.none, miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
        QuestTask(
          number: 2, title: 'Гардероб',
          description: 'Сколько окон в месте хранения верхней одежды? (2 окна)',
          hint: 'Здесь твоя куртка ждёт тебя до конца пар. Ищи на первом этаже.',
          location: '1 этаж, гардероб',
          icon: Icons.checkroom_rounded,
          locationStory:
              'Место, где «внешний интерфейс» снимается и хранится. '
              'Когда-то здесь гимназистки оставляли верхнюю одежду перед уроками.\n\n'
              'Самая стабильная база данных корпуса. Ни одного сбоя за 165 лет. '
              'Даже революция не смогла стереть этот ритуал.',
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
        QuestTask(
          number: 3, title: 'Дирекция',
          description: 'Найди кабинет дирекции. До скольки они максимум работают?',
          hint: 'Административное сердце школы на 2 этаже в центральной части.',
          location: '2 этаж, центр',
          icon: Icons.business_rounded,
          locationStory:
              'Root-доступ. Здесь когда-то сидел директор гимназии, потом — завуч школы, теперь — деканат.\n\n'
              'Именно отсюда «добавляют» и «удаляют» пользователей. '
              'Одна подпись — и ты либо в системе, либо вне её.',
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
        QuestTask(
          number: 4, title: 'Главная лестница',
          description: 'Сколько ступеней в первом пролёте от 1 этажа до первой площадки? (13 ступеней)',
          hint: 'Найди главную лестницу. Считай ступени в первом пролёте.',
          location: '1–2 этаж, лестница',
          icon: Icons.stairs_rounded,
          locationStory:
              'Парадная лестница с литыми балясинами — единственное, что сохранилось с 1860 года в первозданном виде. '
              'Она пережила мануфактуру, гимназию, революцию и открытие 1981-го.\n\n'
              'Ты буквально идёшь по следам первых 700 учениц. '
              'Каждый подъём — +1 к выносливости перед сессией.',
          locationPhoto: null,
          miniGameType: MiniGameType.magicRunes,
          miniGameItems: ['Перила', 'Ступень', 'Площадка', 'Пролёт', 'Балясина', 'Марш'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
      ],
    ),

    // ════════════════════════════════════════════════════
    //  КВЕСТ 2 — «Код доступа: Железо»
    // ════════════════════════════════════════════════════
    Quest(
      id: 'quest_2',
      title: 'Код доступа: Железо',
      description: 'Система показывает своё «железо». Фундамент мануфактуры 1860-го стал основой современных серверов.',
      storyIntro:
          'Ты внутри.\n\n'
          'Теперь Система показывает тебе своё «железо» —\n'
          'то, на чём она работает с 1860 года.\n\n'
          'Фундамент мануфактуры Стригалева\n'
          'стал основой современных серверов.\n\n'
          'Собери четыре компонента, чтобы понять,\n'
          'из чего на самом деле сделан Корпус.',
      storyOutro:
          'Железо изучено.\n'
          'Второй фрагмент легенды\n'
          '(фундамент 1860) активирован.\n\n'
          'Уровень 2 — пройден. ✓',
      duration: '45 мин', difficulty: 'Средний', difficultyLevel: 2,
      taskCount: 4, xpReward: 300, emoji: '⚙️',
      fragmentEmoji: '🧩', fragmentName: 'Фрагмент II: Фундамент',
      tasks: [
        QuestTask(
          number: 1, title: 'Серверная',
          description: 'Какой номер на двери серверной? (это 110²)',
          hint: 'Ищи дверь из-за которой доносится гул вентиляторов на первом этаже.',
          location: '1 этаж, техническое крыло',
          icon: Icons.dns_rounded,
          locationStory:
              'Сердце сети. Арктический холод 18–20°C. '
              'Здесь хранятся данные всех студентов с 1981 года… '
              'и цифровые копии архивных документов гимназии.\n\n'
              'Стены помнят шум ткацких станков — '
              'теперь вместо них гудят вентиляторы.',
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
        QuestTask(
          number: 2, title: 'Лаборатория робототехники',
          description: 'Посмотри через стекло. Какого цвета элементы у ближайшего манипулятора?',
          hint: 'Место где код оживает. Ищи лабораторию с 3D-принтерами за стеклом.',
          location: 'Лаборатория робототехники',
          icon: Icons.precision_manufacturing_rounded,
          locationStory:
              'Место, где код обретает физическую форму. '
              'Когда-то здесь ткали полотно. Сегодня — учат железо думать.\n\n'
              'Именно здесь студенты впервые заставили роботов «вспоминать» историю корпуса. '
              'Собери её обратно.',
          locationPhoto: null,
          miniGameType: MiniGameType.jellyTower,
          miniGameItems: ['Принтер', 'Манипулятор', 'Филамент', 'Модель', 'Стол', 'Сопло'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
        QuestTask(
          number: 3, title: 'Аудитория ИИ (Киберполигон)',
          description: 'Сколько дверей ведёт в эту аудиторию? (2 двери)',
          hint: 'Здесь обучают ИИ и проводят киберспортивные турниры.',
          location: 'Аудитория киберполигона',
          icon: Icons.security_rounded,
          locationStory:
              'Два входа — на случай если один «заблочат». '
              'Нейросети, кибербезопасность, киберспорт.\n\n'
              'Здесь Система сама учится у студентов.',
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
        QuestTask(
          number: 4, title: 'Кабинет с Ультра-монитором',
          description: 'На каком этаже находится зал с огромным экраном? (4 этаж)',
          hint: 'Самая большая аудитория корпуса на самом высоком этаже.',
          location: '4 этаж, большой зал',
          icon: Icons.tv_rounded,
          locationStory:
              'Легендарный экран, видимый с любой точки зала. '
              'Здесь проводят встречи для всего вуза и смотрят фильмы всем потоком.\n\n'
              'Когда-то на этом месте была оранжерея гимназии. '
              'Теперь — цифровой сад.',
          locationPhoto: 'assets/images/quest4.jpg',
          miniGameType: MiniGameType.none, miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
      ],
    ),

    // ════════════════════════════════════════════════════
    //  КВЕСТ 3 — «Режим отладки (Debug)»
    // ════════════════════════════════════════════════════
    Quest(
      id: 'quest_3',
      title: 'Режим отладки (Debug)',
      description: 'Система перегрелась. Найди зоны перезагрузки — места где здание отдыхает уже 165 лет.',
      storyIntro:
          'Система перегрелась от потока\n'
          'новой информации.\n\n'
          'Тебе нужно найти зоны перезагрузки —\n'
          'места, где студенты и само здание\n'
          'отдыхают уже 165 лет.\n\n'
          'Четыре точки подзарядки.\n'
          'Для тебя и для Системы.',
      storyOutro:
          'Перезагрузка завершена.\n'
          'Третий фрагмент\n'
          '(эпоха отдыха и знаний) активирован.\n\n'
          'Батарея заряжена.\n\n'
          'Уровень 3 — пройден. ✓',
      duration: '35 мин', difficulty: 'Новичок', difficultyLevel: 1,
      taskCount: 4, xpReward: 200, emoji: '☕',
      fragmentEmoji: '🧩', fragmentName: 'Фрагмент III: Отдых',
      tasks: [
        QuestTask(
          number: 1, title: 'Главный коворкинг',
          description: 'Сколько столов в зоне отдыха? Совмещённые считай отдельно. (10 столов)',
          hint: 'Ищи зону с мягкой мебелью — пространство для командной работы.',
          location: '1 этаж, коворкинг',
          icon: Icons.groups_rounded,
          locationStory:
              'Здесь рождались стартапы, которые потом становились легендами. '
              'Когда-то в этом крыле был сад с фонтаном.\n\n'
              'Теперь — брейнштормы круче, чем в гаражах Кремниевой долины.',
          locationPhoto: 'assets/images/pairs_board4.jpg',
          miniGameType: MiniGameType.none, miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
        QuestTask(
          number: 2, title: 'Читальный зал',
          description: 'Сколько высоких «барных» стульев стоит у окна?',
          hint: 'Самое тихое место на самом верхнем этаже корпуса.',
          location: '4 этаж, читальный зал',
          icon: Icons.menu_book_rounded,
          locationStory:
              'Зона абсолютной тишины. Здесь хранится часть Книжного архива «Терра» — '
              '12 000 томов, рукописи, роскошные переплёты.\n\n'
              'Панорамный вид на Волгу — как бонус. '
              'Именно здесь гимназистки когда-то читали первые книги.',
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
        QuestTask(
          number: 3, title: 'Зона диванов',
          description: 'Рядом с диванами есть розетки. Сколько гнёзд? (3 гнезда)',
          hint: 'Секретное место для отдыха на 2 этаже. Идеально для подзарядки ноутбука.',
          location: '2 этаж, зона отдыха',
          icon: Icons.weekend_rounded,
          locationStory:
              'Секретный хаб. Мягкие диваны, розетки, слухи о зачётах.\n\n'
              'Говорят, если уснуть здесь, Система сама подскажет ответ на экзамене… '
              'но проверять не рекомендуется.',
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
        QuestTask(
          number: 4, title: 'Кофе-автомат',
          description: 'Сколько стоит большинство напитков в автомате? (100 рублей)',
          hint: 'Главный топливный бак корпуса на первом этаже.',
          location: '1 этаж, кофе-автомат',
          icon: Icons.local_cafe_rounded,
          locationStory:
              'Главный топливный бак корпуса. Программист — организм, перерабатывающий кофе в код.\n\n'
              'С 1860 года здесь всегда было «топливо»: сначала чай для учительниц, '
              'теперь — латте для кодеров.',
          locationPhoto: null,
          miniGameType: MiniGameType.particleAlchemy,
          miniGameItems: ['Кофе', 'Кнопка', 'Стакан', 'Монета', 'Экран', 'Сахар'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
      ],
    ),

    // ════════════════════════════════════════════════════
    //  КВЕСТ 4 — «Cyber Life»
    // ════════════════════════════════════════════════════
    Quest(
      id: 'quest_4',
      title: 'Cyber Life',
      description: 'Стандартные маршруты пройдены. Система открывает скрытые уровни — пасхалки корпуса.',
      storyIntro:
          'Стандартные маршруты пройдены.\n\n'
          'Теперь Система открывает скрытые уровни —\n'
          'те, которые не показывают на экскурсиях.\n\n'
          'Здесь прячутся настоящие пасхалки корпуса.\n\n'
          'В любой хорошей системе\n'
          'есть скрытый контент.\n'
          'Найди его.',
      storyOutro:
          'Скрытые уровни найдены.\n'
          'Четвёртый фрагмент\n'
          '(душа места) активирован.\n\n'
          'Ты знаешь больше, чем 99% студентов.\n\n'
          'Уровень 4 — пройден. ✓',
      duration: '50 мин', difficulty: 'Средний', difficultyLevel: 2,
      taskCount: 4, xpReward: 350, emoji: '🎮',
      fragmentEmoji: '🧩', fragmentName: 'Фрагмент IV: Душа',
      tasks: [
        QuestTask(
          number: 1, title: 'Спуск в игровую',
          description: 'Сколько ступеней ведёт вниз в игровую зону?',
          hint: 'Найди лестницу вниз — переход из учебной реальности в игровую.',
          location: 'Цоколь, лестница вниз',
          icon: Icons.arrow_downward_rounded,
          locationStory:
              'Переход из мира дедлайнов в мир игры. '
              'Один спуск — и ты уже в другой реальности.',
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
        QuestTask(
          number: 2, title: 'Игровая комната',
          description: 'Найди зелёные трубы как в Марио. Из скольких этажей состоит аудитория? (2 этажа)',
          hint: 'Двухэтажная аудитория. Главная пасхалка корпуса.',
          location: 'Цоколь, игровая комната',
          icon: Icons.sports_esports_rounded,
          locationStory:
              'Зелёные трубы — главная пасхалка корпуса. '
              'Здесь студенты отдыхают так же, как когда-то гимназистки в саду.\n\n'
              'В ИТ всегда есть скрытые уровни.',
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
        QuestTask(
          number: 3, title: 'Медиа-студия',
          description: 'Посмотри на ряды кресел. Из чего сделаны подлокотники?',
          hint: 'Находится напротив игровой комнаты.',
          location: 'Напротив игровой, медиа-студия',
          icon: Icons.videocam_rounded,
          locationStory:
              'Зал, где рождается цифровой контент КГУ. '
              'Интервью с лидерами индустрии, ток-шоу, съёмки.\n\n'
              'Возможно, именно здесь однажды снимут историю про тебя.',
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
        QuestTask(
          number: 4, title: 'Панорамное окно',
          description: 'Что видно по центру из окна 4 этажа?\n1) Волгу  2) Корпус  3) Лес  4) Парк',
          hint: 'Найди окно на 4 этаже там же где барные стулья.',
          location: '4 этаж, панорамное окно',
          icon: Icons.window_rounded,
          locationStory:
              'Лучший вид в корпусе. '
              'Отсюда когда-то смотрели на Волгу гимназистки.\n\n'
              'Сегодня — 20-20-20 правило: каждые 20 минут смотри вдаль 20 секунд. '
              'Дай глазам отдохнуть от мониторов.',
          locationPhoto: null,
          miniGameType: MiniGameType.shadowEscape,
          miniGameItems: ['Окно', 'Волга', 'Вид', 'Этаж', 'Небо', 'Панорама'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
      ],
    ),

    // ════════════════════════════════════════════════════
    //  КВЕСТ 5 — «Путь к диплому»
    // ════════════════════════════════════════════════════
    Quest(
      id: 'quest_5',
      title: 'Путь к диплому',
      description: 'Финальный уровень. Система собрала все фрагменты. Готов ли ты стать её частью навсегда?',
      storyIntro:
          'Финальный уровень.\n\n'
          'Система собрала все фрагменты.\n'
          'Теперь она проверяет:\n'
          'готов ли ты стать её частью навсегда?\n\n'
          'Пройди последний маршрут —\n'
          'от вывески до диплома.\n\n'
          'Система запоминает всё.',
      storyOutro:
          'Поздравляем, Администратор.\n\n'
          'Все пять фрагментов собраны.\n'
          'С 1859 по 2026 — ты теперь\n'
          'часть Системы.\n\n'
          'Б-корпус больше не чужой.\n'
          'Это твой дом. Навсегда.\n\n'
          'Добро пожаловать в Легенду. ✓',
      duration: '40 мин', difficulty: 'Сложный', difficultyLevel: 3,
      taskCount: 4, xpReward: 500, emoji: '🎓',
      fragmentEmoji: '👑', fragmentName: 'Финальный фрагмент: Легенда',
      tasks: [
        QuestTask(
          number: 1, title: 'Главная вывеска',
          description: 'Сколько букв на главной вывеске корпуса?',
          hint: 'Вывеска находится на крыше крыльца при входе в здание.',
          location: 'Крыльцо, главная вывеска',
          icon: Icons.emoji_events_rounded,
          locationStory:
              'Этой вывеской в 1981 году открылась новая глава. '
              'Каждая буква — символ нового поколения разработчиков, дизайнеров, инженеров.\n\n'
              'С 1859 года это место меняло форму. Но не смысл.',
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
        QuestTask(
          number: 2, title: 'Галерея активистов',
          description: 'Найди место с фото самых активных ребят. Запомни все лица!',
          hint: 'Ищи на втором этаже напротив одной из лестниц.',
          location: '2 этаж, галерея',
          icon: Icons.photo_library_rounded,
          locationStory:
              'Лица тех, кто уже вошёл в легенду. '
              'Они прошли тот же путь, что и ты.\n\n'
              'Однажды здесь появится и твоё фото. '
              'Система помнит каждого.',
          locationPhoto: 'assets/images/quest3.jpg',
          miniGameType: MiniGameType.starDrift,
          miniGameItems: ['Фото', 'Рамка', 'Лицо', 'Подпись', 'Стена', 'Портрет'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
        QuestTask(
          number: 3, title: 'Конференц-зал',
          description: 'Найди главный зал где проходят все защиты и важные события.',
          hint: 'Место решающих битв за диплом. Самый большой зал в корпусе.',
          location: '4 этаж, конференц-зал',
          icon: Icons.theater_comedy_rounded,
          locationStory:
              'Место решающих битв. Здесь проходили посвящения гимназисток, '
              'вручение дипломов и теперь — твоя защита.\n\n'
              'Всё важное — здесь.',
          locationPhoto: 'assets/images/quest4.jpg',
          miniGameType: MiniGameType.none, miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),
        QuestTask(
          number: 4, title: 'Стенд для выпускников',
          description: 'Найди стенд с информацией о защитах рядом с деканатом.',
          hint: 'Ищи специальный стенд рядом с деканатом на 2 этаже.',
          location: '2 этаж, рядом с деканатом',
          icon: Icons.info_rounded,
          locationStory:
              'Последний рубеж перед дипломом. '
              'Здесь всё что нужно знать о защите: сроки, требования, контакты комиссии.\n\n'
              'Читай внимательно. Система проверит.',
          locationPhoto: null,
          miniGameType: MiniGameType.none, miniGameItems: [],
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
  final String storyIntro, storyOutro;
  final String fragmentEmoji, fragmentName;
  final int difficultyLevel, taskCount, xpReward;
  final List<QuestTask> tasks;

  const Quest({
    required this.id, required this.title, required this.description,
    required this.storyIntro, required this.storyOutro,
    required this.fragmentEmoji, required this.fragmentName,
    required this.duration, required this.difficulty, required this.difficultyLevel,
    required this.taskCount, required this.xpReward, required this.emoji,
    required this.tasks,
  });
}

class QuestTask {
  final int number;
  final String title, description, hint, location;
  final IconData icon;
  final MiniGameType miniGameType;
  final List<String> miniGameItems;
  final List<String> disappearedPhotos;
  final String? locationPhoto;
  final String? locationStory;
  final List<String> pairPhotos;
  final String? puzzlePhoto;

  bool get hasMiniGame => miniGameType != MiniGameType.none;
  List<String> get disappearedItems =>
      disappearedPhotos.isNotEmpty ? disappearedPhotos : miniGameItems;
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
