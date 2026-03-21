// lib/screens/map_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

// ─── Данные о комнатах ────────────────────────────────────────────────────
class _Room {
  final String id;
  final String number;
  final String name;
  final String description;
  final String emoji;
  final double left, top, width, height;
  final _RoomType type;

  const _Room({
    required this.id,
    required this.number,
    required this.name,
    required this.description,
    required this.emoji,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.type,
  });

  Color get color => switch (type) {
    _RoomType.classroom  => const Color(0xFF2E86AB),
    _RoomType.lab        => const Color(0xFF00D4AA),
    _RoomType.social     => const Color(0xFFFFD700),
    _RoomType.service    => const Color(0xFF8E44AD),
    _RoomType.entrance   => const Color(0xFF00D4AA),
  };

  Rect get rect => Rect.fromLTWH(left, top, width, height);
  Offset get center => rect.center;
}

enum _RoomType { classroom, lab, social, service, entrance }

// ─── Все комнаты 1 этажа ──────────────────────────────────────────────────
const _rooms = [
  _Room(id: 'entrance', number: 'Вход', name: 'Главный вход',
    description: 'Портал в мир ИТ. Легенда гласит: войди ровно в 08:00:00 — и код скомпилируется с первого раза.',
    emoji: '🚪', left: 430, top: 980, width: 120, height: 90, type: _RoomType.entrance),

  _Room(id: 'wardrobe', number: 'Гардероб', name: 'Гардероб',
    description: 'Самая стабильная база данных в корпусе. Никогда не было сбоя.',
    emoji: '🧥', left: 680, top: 980, width: 130, height: 90, type: _RoomType.service),

  _Room(id: 'security', number: 'Охрана', name: 'Охрана',
    description: 'Файрволл Б-корпуса. Работает в режиме 24/7.',
    emoji: '🛡️', left: 570, top: 980, width: 100, height: 90, type: _RoomType.service),

  _Room(id: 'coworking', number: '104', name: 'Коворкинг',
    description: 'Место где зародилось больше стартапов, чем в гаражах Кремниевой долины. 10 столов, маркерные доски, быстрый Wi-Fi.',
    emoji: '💡', left: 290, top: 760, width: 220, height: 140, type: _RoomType.social),

  _Room(id: 'vending', number: '105', name: 'Вендинг / Кофе',
    description: 'Главный топливный бак корпуса. Большинство напитков — 100 рублей.',
    emoji: '☕', left: 520, top: 760, width: 130, height: 140, type: _RoomType.social),

  _Room(id: 'storage', number: '106', name: 'Хоз. помещение',
    description: 'Системный раздел. Пользователям вход запрещён.',
    emoji: '📦', left: 660, top: 760, width: 110, height: 140, type: _RoomType.service),

  _Room(id: '101', number: '101', name: 'Лекционная',
    description: 'Большой лекционный зал. Где начинается путь каждого студента.',
    emoji: '🎓', left: 25, top: 760, width: 160, height: 140, type: _RoomType.classroom),

  _Room(id: '111', number: '111', name: 'Аудитория 111',
    description: 'Учебная аудитория. Семинары, практики, защиты проектов.',
    emoji: '📖', left: 920, top: 980, width: 110, height: 90, type: _RoomType.classroom),

  _Room(id: '112', number: '112', name: 'Аудитория 112',
    description: 'Просторная аудитория для больших групп.',
    emoji: '📖', left: 1040, top: 980, width: 330, height: 90, type: _RoomType.classroom),

  _Room(id: '114', number: '114', name: 'Аудитория 114',
    description: 'Учебная аудитория правого крыла.',
    emoji: '📖', left: 920, top: 760, width: 130, height: 140, type: _RoomType.classroom),

  _Room(id: '115', number: '115', name: 'Компьютерный класс',
    description: 'Мощные ПК для практических занятий по программированию. Твоё второе рабочее место.',
    emoji: '💻', left: 1110, top: 760, width: 320, height: 140, type: _RoomType.lab),

  _Room(id: 'server', number: '~110', name: 'Серверная',
    description: 'Цифровое сердце Б-корпуса. Температура 18–20°C. Здесь хранятся все данные школы.',
    emoji: '🖥️', left: 25, top: 980, width: 160, height: 90, type: _RoomType.lab),
];

// ─── Лестницы ─────────────────────────────────────────────────────────────
class _Stair {
  final String name;
  final double left, top, width, height;
  const _Stair(this.name, this.left, this.top, this.width, this.height);
}

const _stairs = [
  _Stair('Лестница A', 195, 580, 85, 360),
  _Stair('Лестница B', 810, 580, 85, 360),
];

// ─── Экран карты ──────────────────────────────────────────────────────────
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  _Room? _selectedRoom;

  // Анимация выбранной комнаты
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Анимация панели информации
  late AnimationController _panelCtrl;
  late Animation<double> _panelAnim;

  // Анимация входа
  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.85, end: 1.15)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _panelCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _panelAnim = CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOutCubic);

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _panelCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _selectRoom(_Room? room) {
    if (_selectedRoom?.id == room?.id) {
      setState(() => _selectedRoom = null);
      _panelCtrl.reverse();
    } else {
      setState(() => _selectedRoom = room);
      if (room != null) {
        _panelCtrl.forward(from: 0);
      } else {
        _panelCtrl.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryAnim,
          child: Column(children: [
            _buildHeader(context),
            _buildLegend(),
            Expanded(child: _buildMapArea()),
            if (_selectedRoom != null) _buildInfoPanel(),
            _buildHint(),
          ]),
        ),
      ),
    );
  }

  // ─── Заголовок ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kBg, kCard.withOpacity(0.8)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 4),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(colors: [kBlue, kGreen]).createShader(b),
          child: const Text('Карта Б-Корпуса',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
        ),
        const Spacer(),
        // Бейдж этажа
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kBlue, kGreen]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: kGreen.withOpacity(0.35), blurRadius: 10)],
          ),
          child: const Row(children: [
            Icon(Icons.layers_rounded, color: Colors.white, size: 14),
            SizedBox(width: 6),
            Text('1 этаж', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }

  // ─── Легенда ──────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    final items = [
      (const Color(0xFF2E86AB), 'Аудитории'),
      (const Color(0xFF00D4AA), 'Лаборатории'),
      (const Color(0xFFFFD700), 'Общественные'),
      (const Color(0xFF8E44AD), 'Сервис'),
      (const Color(0xFFFF6B6B), 'Лестницы'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((item) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: item.$1,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: item.$1.withOpacity(0.5), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 6),
              Text(item.$2,
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
            ]),
          )).toList(),
        ),
      ),
    );
  }

  // ─── Область карты ────────────────────────────────────────────────────────
  Widget _buildMapArea() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: kBlue.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(120),
          minScale: 0.04,
          maxScale: 6.0,
          constrained: false,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseCtrl]),
            builder: (_, __) => CustomPaint(
              size: const Size(1600, 1100),
              painter: _MapPainter(
                selectedRoomId: _selectedRoom?.id,
                pulseValue: _pulseAnim.value,
              ),
              child: SizedBox(
                width: 1600,
                height: 1100,
                child: Stack(children: [
                  // Комнаты
                  ..._rooms.map((room) => _buildRoomWidget(room)),
                  // Лестницы
                  ..._stairs.map((s) => _buildStairWidget(s)),
                  // Туалет
                  _buildToiletWidget(),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomWidget(_Room room) {
    final isSelected = _selectedRoom?.id == room.id;

    return Positioned(
      left: room.left, top: room.top,
      child: GestureDetector(
        onTap: () => _selectRoom(room),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: room.width,
          height: room.height,
          decoration: BoxDecoration(
            color: isSelected
                ? room.color.withOpacity(0.45)
                : room.color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? room.color : room.color.withOpacity(0.6),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: room.color.withOpacity(0.5), blurRadius: 16, spreadRadius: 2)]
                : [],
          ),
          child: Stack(children: [
            // Фоновый паттерн для выбранной
            if (isSelected)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: CustomPaint(painter: _DotPatternPainter(room.color)),
                ),
              ),
            // Контент
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Эмодзи
                  Text(room.emoji,
                      style: TextStyle(fontSize: isSelected ? 18 : 14)),
                  const SizedBox(height: 3),
                  // Номер
                  Text(room.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSelected ? 10 : 8,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
                      )),
                  // Название (только если выбрана или большая)
                  if (room.width > 140 || isSelected) ...[
                    const SizedBox(height: 2),
                    Text(room.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isSelected ? 8 : 7,
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.75),
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        )),
                  ],
                ],
              ),
            ),
            // Индикатор выбора
            if (isSelected)
              Positioned(
                top: 4, right: 4,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: room.color,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: room.color, blurRadius: 6)],
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildStairWidget(_Stair s) {
    return Positioned(
      left: s.left, top: s.top,
      child: Container(
        width: s.width, height: s.height,
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.7), width: 1.5),
        ),
        child: RotatedBox(
          quarterTurns: 1,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🪜', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(s.name,
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFFFF6B6B))),
          ]),
        ),
      ),
    );
  }

  Widget _buildToiletWidget() {
    return Positioned(
      left: 1055, top: 760,
      child: Container(
        width: 45, height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.7), width: 1.5),
        ),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('🚻', style: TextStyle(fontSize: 14)),
          SizedBox(height: 4),
          RotatedBox(quarterTurns: 1,
              child: Text('WC', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF4CAF50)))),
        ]),
      ),
    );
  }

  // ─── Панель информации ────────────────────────────────────────────────────
  Widget _buildInfoPanel() {
    final room = _selectedRoom!;
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(_panelAnim),
      child: FadeTransition(
        opacity: _panelAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [room.color.withOpacity(0.2), kCard],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: room.color.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(color: room.color.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(children: [
            // Иконка
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: room.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: room.color.withOpacity(0.5)),
              ),
              child: Center(child: Text(room.emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            // Текст
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: room.color.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(room.number,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: room.color)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(room.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                      overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 6),
                Text(room.description,
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7), height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            )),
            // Закрыть
            GestureDetector(
              onTap: () => _selectRoom(null),
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.5), size: 16),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Подсказка ────────────────────────────────────────────────────────────
  Widget _buildHint() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.pinch_rounded, color: kGreen.withOpacity(0.8), size: 14),
        const SizedBox(width: 6),
        Text('Сведи/разведи пальцы для масштаба',
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45))),
        const SizedBox(width: 12),
        Icon(Icons.touch_app_rounded, color: kGreen.withOpacity(0.8), size: 14),
        const SizedBox(width: 6),
        Text('Нажми на комнату',
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45))),
      ]),
    );
  }
}

// ─── Painter: фон карты, коридоры, сетка ─────────────────────────────────
class _MapPainter extends CustomPainter {
  final String? selectedRoomId;
  final double pulseValue;

  _MapPainter({this.selectedRoomId, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawGrid(canvas, size);
    _drawCorridors(canvas);
    _drawWalls(canvas);
    _drawCompassRose(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = const LinearGradient(
        colors: [Color(0xFF1A1F45), Color(0xFF141830)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    final thinPaint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 0.5;
    final boldPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), thinPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), thinPaint);
    }
    for (double x = 0; x < size.width; x += 200) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), boldPaint);
    }
    for (double y = 0; y < size.height; y += 200) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), boldPaint);
    }
  }

  void _drawCorridors(Canvas canvas) {
    final paint = Paint()..color = Colors.white.withOpacity(0.06);
    final glowPaint = Paint()
      ..color = kBlue.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final corridors = [
      // Горизонтальные
      Rect.fromLTWH(25, 920, 810, 50),   // левый горизонт
      Rect.fromLTWH(905, 920, 480, 50),  // правый горизонт
      Rect.fromLTWH(25, 700, 1560, 50),  // центральный горизонт
      // Вертикальные
      Rect.fromLTWH(195, 580, 85, 380),  // лестница A зона
      Rect.fromLTWH(810, 580, 85, 380),  // лестница B зона
    ];

    for (final c in corridors) {
      canvas.drawRect(c, glowPaint);
      canvas.drawRect(c, paint);
    }

    // Центральная линия коридора со свечением
    final linePaint = Paint()
      ..color = kBlue.withOpacity(0.3)
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(25, 725), const Offset(1585, 725), linePaint);
  }

  void _drawWalls(Canvas canvas) {
    // Внешние стены здания
    final wallPaint = Paint()
      ..color = kBlue.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = kBlue.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final path = Path()
      ..moveTo(25, 560)
      ..lineTo(25, 1090)
      ..lineTo(1585, 1090)
      ..lineTo(1585, 560)
      ..lineTo(25, 560)
      ..close();

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, wallPaint);

    // Внутренние стены — разделитель крыльев
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Вертикальные разделители
    for (final x in [280.0, 900.0]) {
      canvas.drawLine(Offset(x, 700), Offset(x, 1090), innerPaint);
    }
  }

  void _drawCompassRose(Canvas canvas, Size size) {
    const cx = 1530.0;
    const cy = 80.0;
    const r  = 28.0;

    // Фоновый круг
    canvas.drawCircle(const Offset(cx, cy), r + 4,
        Paint()..color = kCard.withOpacity(0.8));
    canvas.drawCircle(const Offset(cx, cy), r + 4,
        Paint()..color = kBlue.withOpacity(0.3)
          ..style = PaintingStyle.stroke..strokeWidth = 1);

    // Стрелки
    void drawArrow(double angle, Color color, double len) {
      final dx = cos(angle) * len;
      final dy = sin(angle) * len;
      canvas.drawLine(
        const Offset(cx, cy),
        Offset(cx + dx, cy + dy),
        Paint()..color = color..strokeWidth = 2..strokeCap = StrokeCap.round,
      );
    }

    drawArrow(-pi / 2, kGreen, r - 2);    // Север (вверх) — зелёный
    drawArrow(pi / 2, Colors.white.withOpacity(0.3), r * 0.6);  // Юг
    drawArrow(0, Colors.white.withOpacity(0.3), r * 0.6);       // Восток
    drawArrow(pi, Colors.white.withOpacity(0.3), r * 0.6);      // Запад

    // Буква N
    final tp = TextPainter(
      text: TextSpan(text: 'N',
          style: TextStyle(color: kGreen, fontSize: 10, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - r - tp.height - 2));
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.selectedRoomId != selectedRoomId || old.pulseValue != pulseValue;
}

// ─── Painter: точечный паттерн для выбранной комнаты ────────────────────
class _DotPatternPainter extends CustomPainter {
  final Color color;
  _DotPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.12);
    const spacing = 12.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter old) => old.color != color;
}