// lib/data/quest_data.dart
//
// ═══════════════════════════════════════════════════════════════════════════
//  ГДЕ ВСТАВИТЬ СВОИ ФОТОГРАФИИ — ПОЛНАЯ ИНСТРУКЦИЯ
// ═══════════════════════════════════════════════════════════════════════════
//
//  Шаг 1: Создай папку assets/images/ в корне проекта.
//
//  Шаг 2: Брось туда все свои фото. Рекомендуемые имена:
//    Для мест квеста:  location_entrance.jpg, location_server.jpg, ...
//    Для игры «Пары»:  pairs_1.jpg, pairs_2.jpg, pairs_3.jpg, pairs_4.jpg
//    Для «Пятнашки»:   puzzle_entrance.jpg, puzzle_lab.jpg, ...
//
//  Шаг 3: В pubspec.yaml добавь:
//    flutter:
//      assets:
//        - assets/images/
//
//  Шаг 4: Замени null на путь к фото в нужном поле (помечены ← ФОТО).
//
// ───────────────────────────────────────────────────────────────────────────
//  В КАЖДОМ ЗАДАНИИ (QuestTask) есть поля:
//
//  locationPhoto  — фото места на экране задания
//  locationStory  — текст-история под фото
//  miniGameItems  — слова для игры «Найди исчезнувшее» и «Собери слово»
//  pairPhotos     — 4–6 фото для игры «Найди пары»
//  puzzlePhoto    — фото для игры «Пятнашки» (нарежется на 12 кусочков)
//
//  Если фото = null — игра работает с цветными заглушками.
// ═══════════════════════════════════════════════════════════════════════════

// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

enum MiniGameType { none, disappeared }

class QuestData {
  static final List<Quest> quests = [

    // ════════════════════════════════════════════════════════════════════════
    //  КВЕСТ 1 — «Level One: Посвящение» (Ознакомительный)
    // ════════════════════════════════════════════════════════════════════════
    Quest(
      id: 'quest_1',
      title: 'Level One: Посвящение',
      description: 'Базовая навигация по главному маршруту студента. Познакомься с корпусом!',
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
          description: 'Посмотри на табличку на входе в корпус. Какой адрес там написан?',
          hint: 'Это место — портал в мир ИТ. Начни там, где ты зашёл в здание.',
          location: 'Главный вход, 1 этаж',
          icon: Icons.door_front_door_rounded,
          locationStory: 'Главный холл — точка входа в систему. Существует легенда: если зайти в здание ровно в 08:00:00, твой код сегодня скомпилируется с первого раза.',
          locationPhoto: 'assets/images/quest1.jpg',  // ← ФОТО главного входа
          miniGameType: MiniGameType.none,
          miniGameItems: ['Вход', 'Табличка', 'Дверь', 'Адрес', 'Ручка', 'Стекло'],
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
          locationStory: 'Место временного хранения твоего «внешнего интерфейса» — верхней одежды. Самая стабильная база данных в корпусе: ни разу не было сбоя.',
          locationPhoto: null,  // ← ФОТО гардероба
          miniGameType: MiniGameType.none,
          miniGameItems: ['Крючок', 'Стойка', 'Куртка', 'Номер', 'Окно', 'Вешалка'],
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
          locationStory: 'Административный Root-доступ. Здесь решаются вопросы прав доступа (зачисления) и удаления из системы (отчисления). Войти можно, но осторожно.',
          locationPhoto: null,  // ← ФОТО таблички дирекции
          miniGameType: MiniGameType.none,
          miniGameItems: ['Табличка', 'Дверь', 'Кабинет', 'Расписание', 'Этаж', 'Центр'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 4,
          title: 'Главная лестница',
          description: 'Посчитай количество ступенек в первом пролёте от 1 этажа до первой площадки. Сколько их? (13 ступеней)',
          hint: 'Путь наверх к знаниям. Найди главную лестницу, ведущую к аудиториям.',
          location: '1–2 этаж, лестница',
          icon: Icons.stairs_rounded,
          locationStory: 'Аналоговый путь наверх. Говорят, каждый подъём по этой лестнице добавляет +1 к выносливости перед сессией. Проверено тысячами студентов.',
          locationPhoto: null,  // ← ФОТО лестницы
          miniGameType: MiniGameType.disappeared,
          miniGameItems: ['Перила', 'Ступень', 'Площадка', 'Пролёт', 'Поручень', 'Марш'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

      ],
    ),

    // ════════════════════════════════════════════════════════════════════════
    //  КВЕСТ 2 — «Код доступа: Железо» (Технический)
    // ════════════════════════════════════════════════════════════════════════
    Quest(
      id: 'quest_2',
      title: 'Код доступа: Железо',
      description: 'Исследуй ИТ-мощности корпуса — серверы, роботов и огромные мониторы.',
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
          description: 'Какой номер на двери серверной? Подсказка: это 110²',
          hint: 'Ищи дверь, из-за которой доносится гул вентиляторов. Здесь хранятся данные.',
          location: '1 этаж, техническое крыло',
          icon: Icons.dns_rounded,
          locationStory: 'Сердце сети. Здесь поддерживается арктический холод, чтобы серверы школы не превратились в обогреватели. Температура — строго 18–20°C.',
          locationPhoto: null,  // ← ФОТО решётки на двери серверной
          miniGameType: MiniGameType.disappeared,
          miniGameItems: ['Сервер', 'Решётка', 'Замок', 'Вентилятор', 'Кабель', 'Стойка'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 2,
          title: 'Лаборатория робототехники',
          description: 'Посмотри через стекло. Какого цвета элементы у ближайшего робота-манипулятора?',
          hint: 'Место, где код оживляет механизмы. Ищи лабораторию по 3D-принтерам за стеклом.',
          location: 'Лаборатория робототехники',
          icon: Icons.precision_manufacturing_rounded,
          locationStory: 'Место, где код обретает физическую форму. Здесь студенты учат железо думать и двигаться. 3D-принтеры работают круглосуточно над учебными проектами.',
          locationPhoto: null,  // ← ФОТО манипулятора или 3D-принтера
          miniGameType: MiniGameType.disappeared,
          miniGameItems: ['Принтер', 'Манипулятор', 'Филамент', 'Модель', 'Стол', 'Сопло'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 3,
          title: 'Аудитория ИИ (Киберполигон)',
          description: 'Сколько дверей ведёт в эту аудиторию? (2 двери)',
          hint: 'Здесь обучают ИИ и проводят киберспортивные турниры. Ориентируйся по табличке.',
          location: 'Аудитория киберполигона',
          icon: Icons.security_rounded,
          locationStory: 'Здесь тренируются будущие защитники сетей и создатели нейросетей. Вечерами тут часто «фармят» победы в киберспортивных дисциплинах. Две двери — два пути к знаниям.',
          locationPhoto: null,  // ← ФОТО логотипа на двери или системника
          miniGameType: MiniGameType.none,
          miniGameItems: ['Монитор', 'Клавиатура', 'Мышь', 'Кресло', 'Наушники', 'Экран'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 4,
          title: 'Кабинет с Ультра-монитором',
          description: 'Найди огромный экран, за которым можно смотреть фильм. На каком этаже эта аудитория? (4 этаж)',
          hint: 'Эта аудитория самая большая в корпусе, находится на самом высоком этаже.',
          location: '4 этаж, большой зал',
          icon: Icons.tv_rounded,
          locationStory: 'Легендарное место, где проводят встречи для всех гостей ВУЗа и организовывают просмотр фильмов. Экран настолько большой, что виден с любого места в зале.',
          locationPhoto: 'assets/images/quest4.jpg',  // ← ФОТО огромного монитора
          miniGameType: MiniGameType.none,
          miniGameItems: ['Монитор', 'Экран', 'Зал', 'Кресло', 'Проектор', 'Трибуна'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

      ],
    ),

    // ════════════════════════════════════════════════════════════════════════
    //  КВЕСТ 3 — «Режим отладки (Debug)» (Отдых)
    // ════════════════════════════════════════════════════════════════════════
    Quest(
      id: 'quest_3',
      title: 'Режим отладки (Debug)',
      description: 'Найди все точки релакса и подзарядки — места где можно перезагрузиться.',
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
          description: 'Сколько столов находится в зоне отдыха? Совмещённые столы считай отдельно. (10 столов)',
          hint: 'Здесь кипит командная работа над проектами. Ищи зону с мягкой мебелью.',
          location: '1 этаж, коворкинг',
          icon: Icons.groups_rounded,
          locationStory: 'Пространство для командных брейнштормов. Здесь зародилось больше стартапов, чем в гаражах Кремниевой долины. Удобные столы, маркерные доски, быстрый Wi-Fi.',
          locationPhoto: 'assets/images/pairs_board4.jpg',  // ← ФОТО коворкинга
          miniGameType: MiniGameType.none,
          miniGameItems: ['Стол', 'Пуфик', 'Доска', 'Стул', 'Розетка', 'Wi-Fi'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 2,
          title: 'Читальный зал',
          description: 'Сколько высоких «барных» стульев стоит у окна в этом зале?',
          hint: 'Самое тихое место для концентрации на самом верхнем этаже корпуса.',
          location: '4 этаж, читальный зал',
          icon: Icons.menu_book_rounded,
          locationStory: 'Зона тишины. Место для тех, кому нужно войти в состояние «потока» и чтобы никто не отвлекал уведомлениями. Панорамный вид на город прилагается.',
          locationPhoto: null,  // ← ФОТО барной стойки или стульев
          miniGameType: MiniGameType.none,
          miniGameItems: ['Стул', 'Стол', 'Книга', 'Окно', 'Полка', 'Тишина'],
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
          locationStory: 'Секретный хаб для подзарядки ноутбуков и обмена слухами о предстоящих зачётах. Диваны мягкие — засыпать не рекомендуется, хотя многие пробовали.',
          locationPhoto: null,  // ← ФОТО дивана или розетки
          miniGameType: MiniGameType.none,
          miniGameItems: ['Диван', 'Розетка', 'Подушка', 'Зарядка', 'Ноутбук', 'Стена'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 4,
          title: 'Кофе-автомат',
          description: 'Сколько стоит большинство напитков в автомате? (100 рублей)',
          hint: 'Источник энергии для программиста. Ищи его в углу на первом этаже.',
          location: '1 этаж, кофе-автомат',
          icon: Icons.local_cafe_rounded,
          locationStory: 'Главный «топливный бак» корпуса. Программист — это организм, перерабатывающий кофе в программный код. Работает круглосуточно, никогда не ломается.',
          locationPhoto: null,  // ← ФОТО кофе-автомата
          miniGameType: MiniGameType.disappeared,
          miniGameItems: ['Кофе', 'Кнопка', 'Стакан', 'Монета', 'Экран', 'Сахар'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

      ],
    ),

    // ════════════════════════════════════════════════════════════════════════
    //  КВЕСТ 4 — «Cyber Life» (Исследовательский)
    // ════════════════════════════════════════════════════════════════════════
    Quest(
      id: 'quest_4',
      title: 'Cyber Life',
      description: 'Найди самые необычные и скрытые локации корпуса — от игровой до панорамного окна.',
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
          description: 'Сколько ступенек ведёт вниз в игровую зону?',
          hint: 'Путь в зону развлечений лежит через эти ступени. Найди спуск вниз.',
          location: 'Цоколь, лестница вниз',
          icon: Icons.arrow_downward_rounded,
          locationStory: 'Путь в цоколь — переход из учебной реальности в игровую. Один спуск отделяет мир дедлайнов от мира развлечений.',
          locationPhoto: null,  // ← ФОТО поручня лестницы вниз
          miniGameType: MiniGameType.none,
          miniGameItems: ['Ступень', 'Поручень', 'Спуск', 'Цоколь', 'Пролёт', 'Перила'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 2,
          title: 'Игровая комната',
          description: 'Найди зелёные трубы (как в Марио). Из скольких этажей состоит эта аудитория? (2 этажа)',
          hint: 'Здесь люди играют в настольные игры и не только. Ищи двухэтажную аудиторию.',
          location: 'Цоколь, игровая комната',
          icon: Icons.sports_esports_rounded,
          locationStory: 'Пространство для отдыха. Зелёные трубы — символ того, что в ИТ всегда есть скрытые уровни и пасхалки. Эта аудитория в два этажа — главная пасхалка корпуса.',
          locationPhoto: null,  // ← ФОТО зелёных труб
          miniGameType: MiniGameType.disappeared,
          miniGameItems: ['Труба', 'Игра', 'Этаж', 'Стол', 'Контроллер', 'Экран'],
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
          locationStory: 'Зал для съёмок ток-шоу. Здесь записываются интервью с лидерами индустрии. Место, где создаётся цифровой контент школы. Кресла с особенными подлокотниками.',
          locationPhoto: null,  // ← ФОТО рядов кресел
          miniGameType: MiniGameType.none,
          miniGameItems: ['Кресло', 'Камера', 'Ряд', 'Микрофон', 'Свет', 'Сцена'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 4,
          title: 'Панорамное окно',
          description: 'Что видно прямо по центру из окна 4 этажа?\n1) Реку Волгу  2) Другой корпус  3) Лес  4) Парк',
          hint: 'Найди окно на 4 этаже, там же где барные стулья — с лучшим видом на Волгу.',
          location: '4 этаж, панорамное окно',
          icon: Icons.window_rounded,
          locationStory: 'Точка обзора с лучшим видом в корпусе. Идеальное место, чтобы отвлечься от монитора и дать глазам отдохнуть. 20–20–20: каждые 20 минут смотри 20 секунд вдаль на 20 метров.',
          locationPhoto: null,  // ← ФОТО вида из окна
          miniGameType: MiniGameType.none,
          miniGameItems: ['Окно', 'Волга', 'Вид', 'Горизонт', 'Небо', 'Панорама'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

      ],
    ),

    // ════════════════════════════════════════════════════════════════════════
    //  КВЕСТ 5 — «Путь к диплому» (Административный)
    // ════════════════════════════════════════════════════════════════════════
    Quest(
      id: 'quest_5',
      title: 'Путь к диплому',
      description: 'Финальный маршрут — пройди путь от главной вывески до конференц-зала.',
      duration: '40 мин',
      difficulty: 'Сложный',
      difficultyLevel: 3,
      taskCount: 4,
      xpReward: 500,
      emoji: '🎓',
      tasks: [

        QuestTask(
          number: 1,
          title: 'Главная вывеска (Логотип)',
          description: 'Сколько букв на главной вывеске корпуса?',
          hint: 'Вывеска находится на крыше крыльца при входе в здание.',
          location: 'Крыльцо, главная вывеска',
          icon: Icons.emoji_events_rounded,
          locationStory: 'Этой вывеской была положена новая история айтишников КГУ. Каждая буква — символ нового поколения разработчиков, дизайнеров и инженеров.',
          locationPhoto: null,  // ← ФОТО вывески
          miniGameType: MiniGameType.none,
          miniGameItems: ['Буква', 'Вывеска', 'Логотип', 'Крыша', 'Крыльцо', 'Школа'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 2,
          title: 'Фото активистов',
          description: 'Найди место с фото самых активных ребят из нашего института. Запомни все детали!',
          hint: 'Ищи на втором этаже напротив одной из лестниц.',
          location: '2 этаж, галерея',
          icon: Icons.photo_library_rounded,
          locationStory: 'Галерея лучших студентов — гордость факультета. Здесь лица тех, кто уже оставил след в истории школы. Может быть, однажды здесь окажется и твоё фото.',
          locationPhoto: 'assets/images/quest3.jpg',  // ← ФОТО галереи активистов
          miniGameType: MiniGameType.disappeared,
          miniGameItems: ['Фото', 'Рамка', 'Лицо', 'Подпись', 'Стена', 'Портрет'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 3,
          title: 'Конференц-зал',
          description: 'Найди главный конференц-зал, где проходят защиты и все важные события.',
          hint: 'Место решающих битв за диплом. Самый большой зал в корпусе.',
          location: '4 этаж, конференц-зал',
          icon: Icons.theater_comedy_rounded,
          locationStory: 'Здесь проходят посвящения в студенты, вручения дипломов, конференции и встречи с гостями ВУЗа. Зал вмещает весь поток — это финальная точка пути к диплому.',
          locationPhoto: 'assets/images/quest4.jpg',  // ← ФОТО конференц-зала
          miniGameType: MiniGameType.none,
          miniGameItems: ['Трибуна', 'Кресло', 'Экран', 'Ряд', 'Диплом', 'Зал'],
          pairPhotos: ['assets/images/pairs_board1.jpg','assets/images/pairs_board2.jpg','assets/images/pairs_board3.jpg','assets/images/pairs_board4.jpg','assets/images/pairs_board5.jpg','assets/images/pairs_board6.jpg'],
          puzzlePhoto: 'assets/images/puzzle_photo.jpg',
        ),

        QuestTask(
          number: 4,
          title: 'Стенд для выпускников',
          description: 'Найди стенд с информацией о защитах и практиках для выпускников.',
          hint: 'Ищи специальный стенд рядом с деканатом на 2 этаже.',
          location: '2 этаж, рядом с деканатом',
          icon: Icons.info_rounded,
          locationStory: 'Последний рубеж перед дипломом. На этом стенде — всё что нужно знать о защите: сроки, требования, контакты комиссии. Читай внимательно.',
          locationPhoto: null,  // ← ФОТО стенда
          miniGameType: MiniGameType.disappeared,
          miniGameItems: ['Стенд', 'Объявление', 'Диплом', 'Дата', 'Кафедра', 'Приказ'],
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
    required this.taskCount, required this.xpReward, required this.emoji,
    required this.tasks,
  });
}

class QuestTask {
  final int number;
  final String title, description, hint, location;
  final IconData icon;
  final MiniGameType miniGameType;

  // ── Предметы для игры «Найди исчезнувшее» и «Собери слово» ───────────────
  final List<String> miniGameItems;

  // ── Фото для игры «Найди исчезнувшее» (если указаны — вместо слов) ───────
  final List<String> disappearedPhotos;

  // ── Фото места (показывается на экране задания) ───────────────────────────
  // ✏️ МЕНЯЙ: locationPhoto = 'assets/images/location_entrance.jpg'
  final String? locationPhoto;

  // ── Текст описания места ──────────────────────────────────────────────────
  // ✏️ МЕНЯЙ: расскажи что интересного в этом месте
  final String? locationStory;

  // ── Фото для игры «Найди пары» ────────────────────────────────────────────
  // ✏️ МЕНЯЙ: добавь 4–6 путей к фото
  final List<String> pairPhotos;

  // ── Фото для игры «Пятнашки» ─────────────────────────────────────────────
  // ✏️ МЕНЯЙ: одно фото, которое нарежется на 12 кусочков
  final String? puzzlePhoto;

  bool get hasMiniGame => miniGameType == MiniGameType.disappeared;

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