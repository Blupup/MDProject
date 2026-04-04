// lib/data/quest_data.dart
//
// ═══════════════════════════════════════════════════════════════════════════
//  СЮЖЕТ: Ты — новый пользователь. Б-корпус — система.
//  Пройди 5 уровней чтобы получить полный доступ.
// ═══════════════════════════════════════════════════════════════════════════
//
//  КАРТА ИГР:
//  Квест 1 «Посвящение»     → 👁️  disappeared  (Найди исчезнувшее)
//  Квест 2 «Железо»         → 🧩  puzzle        (Пятнашки)
//  Квест 3 «Debug»          → 🎓  runner        (Коридорный раннер)
//  Квест 4 «Cyber Life»     → 🚀  planetHop     (Межпланетный прыжок)
//  Квест 5 «Диплом»         → 🃏  pairs         (Найди пары)
//
// ─────────────────────────────────────────────────────────────────────────
//  КАК ДОБАВИТЬ ФОТО:
//  1. Создай папку assets/images/
//  2. В pubspec.yaml:  flutter: assets: - assets/images/
//  3. Замени null на путь в поле locationPhoto / puzzlePhoto / pairPhotos
// ═══════════════════════════════════════════════════════════════════════════

// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

enum MiniGameType { none, magicRunes, jellyTower, particleAlchemy, shadowEscape, starDrift }

class QuestData {
  static final List<Quest> quests = [

    // ════════════════════════════════════════════════════════════════════════
    //  КВЕСТ 1 — «Level One: Посвящение»
    //  Ты только что поступил. Пора загрузить систему.
    //  Игра: «Найди исчезнувшее» — тренировка памяти новичка
    // ════════════════════════════════════════════════════════════════════════
    Quest(
      id: 'quest_1',
      title: 'Level One: Посвящение',
      description: 'Первый день. Система загружается. Найди 4 точки входа и пройди базовую инициализацию.',
      storyIntro: 'Добро пожаловать, новый пользователь.\nСистема инициализирована.\nПройди 5 уровней чтобы получить полный доступ к корпусу.',
      storyOutro: 'Инициализация завершена.\nДобро пожаловать в систему.\n\nУровень 1 — пройден. ✓',
      duration: '30 мин',
      difficulty: 'Новичок',
      difficultyLevel: 1,
      taskCount: 4,
      xpReward: 150,
      emoji: '🗺️',
      tasks: [

        QuestTask(
          number: 1,
          title: 'Главный вход',
          description: 'Посмотри на табличку на входе. Какой адрес там написан?',
          hint: 'Это место — портал в мир ИТ. Начни там, где ты зашёл в здание.',
          location: 'Главный вход, 1 этаж',
          icon: Icons.door_front_door_rounded,
          locationStory: 'Портал активирован. Каждый день тысячи пользователей проходят через этот шлюз. Существует легенда: если зайти ровно в 08:00:00 — твой код скомпилируется с первого раза.',
          locationPhoto: 'assets/images/quest1.jpg',
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 2,
          title: 'Гардероб',
          description: 'Сколько окон есть в месте хранения верхней одежды? (2 окна)',
          hint: 'Здесь твоя куртка ждёт тебя до конца пар. Ищи на первом этаже.',
          location: '1 этаж, гардероб',
          icon: Icons.checkroom_rounded,
          locationStory: 'Место временного хранения внешнего интерфейса. Самая стабильная база данных корпуса — ни разу не было сбоя. Uptime 100%.',
          locationPhoto: null,
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 3,
          title: 'Дирекция',
          description: 'Найди кабинет дирекции. До скольки они максимум работают?',
          hint: 'Административное сердце школы. Ищи кабинет на втором этаже в центральной части.',
          location: '2 этаж, центр',
          icon: Icons.business_rounded,
          locationStory: 'Root-доступ корпуса. Здесь решается всё: от зачисления (добавить пользователя) до отчисления (удалить пользователя). Войти можно — но осторожно.',
          locationPhoto: null,
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        // ── ИГРОВАЯ ТОЧКА ─────────────────────────────────────────────────
        QuestTask(
          number: 4,
          title: 'Главная лестница',
          description: 'Посчитай ступеньки в первом пролёте от 1 этажа до первой площадки. Сколько их? (13 ступеней)',
          hint: 'Путь наверх к знаниям. Найди главную лестницу.',
          location: '1–2 этаж, лестница',
          icon: Icons.stairs_rounded,
          locationStory: 'Аналоговый лифт. Каждый подъём добавляет +1 к выносливости перед сессией. Проверено тысячами студентов. А теперь — проверь свою память.',
          locationPhoto: null,
          // 🔦 Игра 1: Неоновый луч — найди путь как новичок
          miniGameType: MiniGameType.magicRunes,
          miniGameItems: ['Перила', 'Ступень', 'Площадка', 'Пролёт', 'Поручень', 'Марш'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

      ],
    ),

    // ════════════════════════════════════════════════════════════════════════
    //  КВЕСТ 2 — «Код доступа: Железо»
    //  Ты освоился. Пора узнать из чего сделан этот корпус.
    //  Игра: «Пятнашки» — собери картинку как разбирают железо
    // ════════════════════════════════════════════════════════════════════════
    Quest(
      id: 'quest_2',
      title: 'Код доступа: Железо',
      description: 'Доступ к техническому уровню получен. Б-корпус — это не просто стены. Это железо.',
      storyIntro: 'Уровень 1 завершён. Открываю технический доступ...\nБ-корпус работает на реальном железе.\nНайди 4 точки где код обретает физическую форму.',
      storyOutro: 'Железо изучено. Теперь ты знаешь что работает за стенами.\n\nУровень 2 — пройден. ✓',
      duration: '45 мин',
      difficulty: 'Средний',
      difficultyLevel: 2,
      taskCount: 4,
      xpReward: 300,
      emoji: '⚙️',
      tasks: [

        QuestTask(
          number: 1,
          title: 'Серверная',
          description: 'Какой номер на двери серверной? Подсказка: это 110 в квадрате.',
          hint: 'Ищи дверь, из-за которой доносится гул вентиляторов на первом этаже.',
          location: '1 этаж, техническое крыло',
          icon: Icons.dns_rounded,
          locationStory: 'Сердце сети. Здесь поддерживается арктический холод — серверы не должны перегреться. Все твои учебные данные хранятся именно здесь.',
          locationPhoto: null,
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        // ── ИГРОВАЯ ТОЧКА ─────────────────────────────────────────────────
        QuestTask(
          number: 2,
          title: 'Лаборатория робототехники',
          description: 'Посмотри через стекло. Какого цвета элементы у ближайшего робота-манипулятора?',
          hint: 'Место где код оживляет механизмы. Ищи лабораторию с 3D-принтерами за стеклом.',
          location: 'Лаборатория робототехники',
          icon: Icons.precision_manufacturing_rounded,
          locationStory: 'Здесь код обретает физическую форму. Студенты учат железо думать и двигаться. А ты — собери его обратно.',
          locationPhoto: null,
          // ⚙️ Игра 2: Механический лотос — крути шестерни
          miniGameType: MiniGameType.jellyTower,
          miniGameItems: ['Принтер', 'Манипулятор', 'Филамент', 'Модель', 'Стол', 'Сопло'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',  // ← ЗАМЕНИ на фото лаборатории
        ),

        QuestTask(
          number: 3,
          title: 'Аудитория ИИ (Киберполигон)',
          description: 'Сколько дверей ведёт в эту аудиторию? (2 двери)',
          hint: 'Здесь обучают ИИ и проводят киберспортивные турниры.',
          location: 'Аудитория киберполигона',
          icon: Icons.security_rounded,
          locationStory: 'Тренировочный полигон. Нейросети, кибербезопасность, киберспорт. Два входа — на случай если один заблокируют.',
          locationPhoto: null,
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 4,
          title: 'Кабинет с Ультра-монитором',
          description: 'Найди огромный экран для просмотра фильмов. На каком этаже эта аудитория? (4 этаж)',
          hint: 'Самая большая аудитория корпуса, на самом высоком этаже.',
          location: '4 этаж, большой зал',
          icon: Icons.tv_rounded,
          locationStory: 'Легендарный экран. Виден с любого места в зале. Здесь проводят встречи для гостей ВУЗа и смотрят фильмы всем потоком.',
          locationPhoto: 'assets/images/quest4.jpg',
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

      ],
    ),

    // ════════════════════════════════════════════════════════════════════════
    //  КВЕСТ 3 — «Режим отладки (Debug)»
    //  Система перегрета. Найди точки подзарядки.
    //  Игра: «Коридорный раннер» — беги как на дедлайне
    // ════════════════════════════════════════════════════════════════════════
    Quest(
      id: 'quest_3',
      title: 'Режим отладки (Debug)',
      description: 'Система перегрета. Требуется перезагрузка. Найди 4 точки подзарядки — для себя и ноутбука.',
      storyIntro: 'Внимание: перегрев системы.\nТребуется отладка и перезапуск.\nНайди зоны восстановления в корпусе.',
      storyOutro: 'Перезагрузка завершена. Батарея заряжена.\nСистема стабилизирована.\n\nУровень 3 — пройден. ✓',
      duration: '35 мин',
      difficulty: 'Новичок',
      difficultyLevel: 1,
      taskCount: 4,
      xpReward: 200,
      emoji: '☕',
      tasks: [

        QuestTask(
          number: 1,
          title: 'Главный коворкинг',
          description: 'Сколько столов в зоне отдыха? Совмещённые считай отдельно. (10 столов)',
          hint: 'Здесь кипит командная работа. Ищи зону с мягкой мебелью.',
          location: '1 этаж, коворкинг',
          icon: Icons.groups_rounded,
          locationStory: 'Пространство для брейнштормов. Здесь зародилось больше стартапов, чем в гаражах Кремниевой долины. Удобные столы, маркерные доски, быстрый Wi-Fi.',
          locationPhoto: 'assets/images/pairs_board4.jpg',
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 2,
          title: 'Читальный зал',
          description: 'Сколько высоких «барных» стульев стоит у окна?',
          hint: 'Самое тихое место на самом верхнем этаже корпуса.',
          location: '4 этаж, читальный зал',
          icon: Icons.menu_book_rounded,
          locationStory: 'Зона тишины. Режим потока. Никаких уведомлений. Только ты и задача. Панорамный вид на город прилагается.',
          locationPhoto: null,
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 3,
          title: 'Зона диванов',
          description: 'Рядом с диванами есть розетки. Сколько гнёзд розеток там есть? (3 гнезда)',
          hint: 'Секретное место для отдыха на 2 этаже. Идеально для подзарядки ноутбука.',
          location: '2 этаж, зона отдыха',
          icon: Icons.weekend_rounded,
          locationStory: 'Секретный хаб. Мягкие диваны, розетки, слухи о предстоящих зачётах. Засыпать не рекомендуется — хотя многие пробовали.',
          locationPhoto: null,
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        // ── ИГРОВАЯ ТОЧКА ─────────────────────────────────────────────────
        QuestTask(
          number: 4,
          title: 'Кофе-автомат',
          description: 'Сколько стоит большинство напитков в автомате? (100 рублей)',
          hint: 'Главный топливный бак корпуса. Ищи на первом этаже.',
          location: '1 этаж, кофе-автомат',
          icon: Icons.local_cafe_rounded,
          locationStory: 'Программист — организм, перерабатывающий кофе в код. Автомат работает круглосуточно. А теперь — беги по коридору за зачётками!',
          locationPhoto: null,
          // 💫 Игра 3: Алхимия частиц — отлаживай поток
          miniGameType: MiniGameType.particleAlchemy,
          miniGameItems: ['Кофе', 'Кнопка', 'Стакан', 'Монета', 'Экран', 'Сахар'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

      ],
    ),

    // ════════════════════════════════════════════════════════════════════════
    //  КВЕСТ 4 — «Cyber Life»
    //  Стандартный маршрут пройден. Время изучить скрытые уровни.
    //  Игра: «Межпланетный прыжок» — прыгай точно как ищешь пасхалки
    // ════════════════════════════════════════════════════════════════════════
    Quest(
      id: 'quest_4',
      title: 'Cyber Life',
      description: 'Стандартный маршрут пройден. Время изучить скрытые уровни. В любой системе есть пасхалки.',
      storyIntro: 'Все стандартные локации изучены.\nОткрываю скрытый контент...\nВ любой хорошей системе есть пасхалки.\nНайди их.',
      storyOutro: 'Скрытые уровни найдены.\nТы знаешь больше чем большинство.\n\nУровень 4 — пройден. ✓',
      duration: '50 мин',
      difficulty: 'Средний',
      difficultyLevel: 2,
      taskCount: 4,
      xpReward: 350,
      emoji: '🎮',
      tasks: [

        QuestTask(
          number: 1,
          title: 'Спуск в игровую',
          description: 'Сколько ступеней ведёт вниз в игровую зону?',
          hint: 'Путь в зону развлечений лежит через ступени вниз. Найди спуск.',
          location: 'Цоколь, лестница вниз',
          icon: Icons.arrow_downward_rounded,
          locationStory: 'Переход из учебной реальности в игровую. Один спуск отделяет мир дедлайнов от мира развлечений.',
          locationPhoto: null,
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 2,
          title: 'Игровая комната',
          description: 'Найди зелёные трубы как в Марио. Из скольких этажей состоит эта аудитория? (2 этажа)',
          hint: 'Двухэтажная аудитория с трубами. Главная пасхалка корпуса.',
          location: 'Цоколь, игровая комната',
          icon: Icons.sports_esports_rounded,
          locationStory: 'В ИТ всегда есть скрытые уровни и пасхалки. Эта аудитория в два этажа — главная пасхалка всего корпуса.',
          locationPhoto: null,
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 3,
          title: 'Медиа-студия',
          description: 'Посмотри на ряды кресел. Из чего сделаны подлокотники у них?',
          hint: 'Здесь снимаются интересные люди. Ищи напротив игровой комнаты.',
          location: 'Напротив игровой, медиа-студия',
          icon: Icons.videocam_rounded,
          locationStory: 'Зал для съёмок ток-шоу. Здесь записываются интервью с лидерами индустрии. Место где создаётся цифровой контент школы.',
          locationPhoto: null,
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        // ── ИГРОВАЯ ТОЧКА ─────────────────────────────────────────────────
        QuestTask(
          number: 4,
          title: 'Панорамное окно',
          description: 'Что видно по центру из окна 4 этажа?\n1) Реку Волгу  2) Другой корпус  3) Лес  4) Парк',
          hint: 'Найди окно на 4 этаже, там же где барные стулья.',
          location: '4 этаж, панорамное окно',
          icon: Icons.window_rounded,
          locationStory: 'Лучший вид в корпусе. Дай глазам отдохнуть от мониторов. А теперь — прыгай точно как ищешь пасхалки в коде!',
          locationPhoto: null,
          // 👾 Игра 4: Побег тени — беги по скрытым уровням
          miniGameType: MiniGameType.shadowEscape,
          miniGameItems: ['Окно', 'Волга', 'Вид', 'Этаж', 'Небо', 'Панорама'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

      ],
    ),

    // ════════════════════════════════════════════════════════════════════════
    //  КВЕСТ 5 — «Путь к диплому»
    //  Финальный уровень. Система проверяет готовность.
    //  Игра: «Найди пары» — сопоставь знания о корпусе
    // ════════════════════════════════════════════════════════════════════════
    Quest(
      id: 'quest_5',
      title: 'Путь к диплому',
      description: 'Финальный уровень. Система проверяет готовность. Пройди последний маршрут — от вывески до диплома.',
      storyIntro: 'Финальная проверка запущена.\nВсе предыдущие уровни учтены.\nПройди последний маршрут.\nСистема запоминает всё.',
      storyOutro: 'Поздравляем.\nВсе уровни пройдены.\nБ-корпус больше не чужой — это твой дом.\n\nДобро пожаловать в систему. Навсегда. ✓',
      duration: '40 мин',
      difficulty: 'Сложный',
      difficultyLevel: 3,
      taskCount: 4,
      xpReward: 500,
      emoji: '🎓',
      tasks: [

        QuestTask(
          number: 1,
          title: 'Главная вывеска',
          description: 'Сколько букв на главной вывеске корпуса?',
          hint: 'Вывеска находится на крыше крыльца при входе в здание.',
          location: 'Крыльцо, главная вывеска',
          icon: Icons.emoji_events_rounded,
          locationStory: 'Этой вывеской была открыта новая история айтишников КГУ. Каждая буква — символ нового поколения разработчиков, дизайнеров, инженеров.',
          locationPhoto: null,
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        // ── ИГРОВАЯ ТОЧКА ─────────────────────────────────────────────────
        QuestTask(
          number: 2,
          title: 'Галерея активистов',
          description: 'Найди место с фото самых активных ребят из нашего института. Запомни все лица!',
          hint: 'Ищи на втором этаже напротив одной из лестниц.',
          location: '2 этаж, галерея',
          icon: Icons.photo_library_rounded,
          locationStory: 'Лица тех, кто уже оставил след в истории школы. Однажды здесь окажется и твоё фото. А пока — найди все пары.',
          locationPhoto: 'assets/images/quest3.jpg',
          // 🌟 Игра 5: Звёздный дрифт — финальный забег к диплому
          miniGameType: MiniGameType.starDrift,
          miniGameItems: ['Фото', 'Рамка', 'Лицо', 'Подпись', 'Стена', 'Портрет'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 3,
          title: 'Конференц-зал',
          description: 'Найди главный зал где проходят защиты и все важные события.',
          hint: 'Место решающих битв за диплом. Самый большой зал в корпусе.',
          location: '4 этаж, конференц-зал',
          icon: Icons.theater_comedy_rounded,
          locationStory: 'Посвящения, вручения дипломов, конференции. Всё важное — здесь. Это финальная точка пути каждого студента.',
          locationPhoto: 'assets/images/quest4.jpg',
          miniGameType: MiniGameType.none,
          miniGameItems: [],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 4,
          title: 'Стенд для выпускников',
          description: 'Найди стенд с информацией о защитах и практиках рядом с деканатом.',
          hint: 'Ищи специальный стенд рядом с деканатом на 2 этаже.',
          location: '2 этаж, рядом с деканатом',
          icon: Icons.info_rounded,
          locationStory: 'Последний рубеж перед дипломом. Здесь всё что нужно знать о защите: сроки, требования, контакты комиссии. Читай внимательно.',
          locationPhoto: null,
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
  final String storyIntro;   // текст перед началом квеста
  final String storyOutro;   // текст после завершения квеста
  final int difficultyLevel, taskCount, xpReward;
  final List<QuestTask> tasks;

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.storyIntro,
    required this.storyOutro,
    required this.duration,
    required this.difficulty,
    required this.difficultyLevel,
    required this.taskCount,
    required this.xpReward,
    required this.emoji,
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

  // true если у задания есть игра
  bool get hasMiniGame => miniGameType != MiniGameType.none;

  List<String> get disappearedItems =>
      disappearedPhotos.isNotEmpty ? disappearedPhotos : miniGameItems;

  List<String> get puzzlePhotos => puzzlePhoto != null ? [puzzlePhoto!] : [];

  const QuestTask({
    required this.number,
    required this.title,
    required this.description,
    required this.hint,
    required this.location,
    required this.icon,
    required this.miniGameType,
    required this.miniGameItems,
    this.locationPhoto,
    this.locationStory,
    this.pairPhotos = const [],
    this.puzzlePhoto,
    this.disappearedPhotos = const [],
  });
}
