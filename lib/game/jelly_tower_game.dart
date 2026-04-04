// lib/game/jelly_tower_game.dart
//
// «Башня из желе» — роняй блоки точно на башню.
// Блоки раскачиваются, лишнее обрезается. Построй башню из 10 блоков!
// Квест 2 «Железо»
//
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

// ─── Блок башни ───────────────────────────────────────────────────────────
class _Block {
  double x;       // левый край (относительно ширины поля)
  double width;   // ширина (относительная 0..1)
  final Color color;
  double squishY = 0;   // сжатие при падении (0..1)
  double wobble  = 0;   // покачивание после приземления

  _Block({required this.x, required this.width, required this.color});
}

// Цвета желешек
const _jellyColors = [
  Color(0xFF00D4AA), Color(0xFF2E86AB), Color(0xFF9C27B0),
  Color(0xFFFF6B35), Color(0xFF4CAF50), Color(0xFFE91E63),
  Color(0xFFFFD700), Color(0xFF00BCD4), Color(0xFFFF5722),
  Color(0xFF8BC34A),
];

// ─── Главный виджет ───────────────────────────────────────────────────────
class JellyTowerGame extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const JellyTowerGame({super.key, required this.onSuccess, required this.onFail});

  @override
  State<JellyTowerGame> createState() => _JellyTowerGameState();
}

class _JellyTowerGameState extends State<JellyTowerGame> with TickerProviderStateMixin {
  static const _blockH   = 52.0;    // высота блока
  static const _winCount = 10;      // сколько блоков нужно
  static const _minWidth = 0.15;    // минимальная ширина (иначе game over)

  // Башня (снизу → вверх)
  final List<_Block> _tower = [];

  // Летящий блок
  double _flyX      = 0;      // левый край текущего
  double _flyWidth  = 0.7;    // ширина текущего
  double _flySpeed  = 0.45;   // скорость (относительная в сек)
  int    _flyDir    = 1;      // направление

  bool _won    = false;
  bool _failed = false;
  bool _dropping = false;    // анимация падения

  // Высота башни в px (вычисляем при layout)
  double _fieldH = 0;
  double _fieldW = 0;

  // Анимация: маятник текущего блока
  late AnimationController _swingCtrl;
  late Animation<double>   _swingAnim; // 0..1 — позиция по X

  // Анимация падения
  late AnimationController _dropCtrl;
  late Animation<double>   _dropAnim;

  // Анимация желе (squish)
  late AnimationController _squishCtrl;
  late Animation<double>   _squishAnim;

  // Победа/поражение
  late AnimationController _winCtrl, _failCtrl;
  late Animation<double>   _winScale, _failScale;

  final _rng = Random();
  int _score = 0; // перфектных совпадений

  @override
  void initState() {
    super.initState();

    _swingCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _dropCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _squishCtrl= AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _winCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _failCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _swingAnim  = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _swingCtrl, curve: Curves.easeInOut));
    _dropAnim   = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _dropCtrl,  curve: Curves.easeIn));
    _squishAnim = Tween(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _squishCtrl, curve: Curves.elasticOut));
    _winScale   = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _winCtrl,   curve: Curves.elasticOut));
    _failScale  = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _failCtrl,  curve: Curves.easeOut));

    // Базовый блок — платформа
    _tower.add(_Block(x: 0.15, width: 0.7, color: const Color(0xFF455A64)));
  }

  @override
  void dispose() {
    _swingCtrl.dispose(); _dropCtrl.dispose(); _squishCtrl.dispose();
    _winCtrl.dispose(); _failCtrl.dispose();
    super.dispose();
  }

  // ─── Позиция летящего блока (по анимации маятника) ───────────────────────
  double get _currentFlyX {
    final top = _tower.last;
    final maxX = 1.0 - _flyWidth;

    // Размах — чуть шире башни
    final swing = top.width * 0.4 + 0.12;
    final center = (top.x + top.x + top.width) / 2 - _flyWidth / 2;

    final t = _swingAnim.value;
    // sin для маятника: 0→1→0→-1→0
    final offset = sin(t * 2 * pi) * swing;
    return (center + offset).clamp(0.0, maxX);
  }

  // ─── Нажатие — сброс блока ────────────────────────────────────────────────
  void _onTap() {
    if (_won || _failed || _dropping) return;
    HapticFeedback.mediumImpact();

    final fx = _currentFlyX;
    final fw = _flyWidth;

    final top = _tower.last;
    final tx = top.x;
    final tw = top.width;

    // Вычисляем пересечение
    final overlapLeft  = max(fx, tx);
    final overlapRight = min(fx + fw, tx + tw);
    final overlap      = overlapRight - overlapLeft;

    if (overlap <= 0) {
      // Промах — конец игры
      setState(() => _dropping = true);
      _dropCtrl.forward(from: 0).then((_) { _triggerFail(); });
      return;
    }

    // Проверяем перфект (совпадение > 95%)
    final isPerfect = overlap / fw > 0.95 && overlap / tw > 0.95;

    // Новый блок — обрезанный
    final newBlock = _Block(
      x: overlapLeft,
      width: overlap,
      color: _jellyColors[_tower.length % _jellyColors.length],
    );

    if (isPerfect) {
      _score++;
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _dropping = true;
      _flyX     = fx;  // сохраняем позицию падающего
    });

    // Анимация падения
    _dropCtrl.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        _tower.add(newBlock);
        _dropping = false;
        // Следующий блок чуть уже
        _flyWidth = (overlap * (isPerfect ? 1.0 : 0.98)).clamp(_minWidth, 1.0);
        // Скорость растёт
        _flySpeed = min(0.45 + _tower.length * 0.04, 1.2);
        _updateSwingSpeed();
      });
      _squishCtrl.forward(from: 0);

      if (_flyWidth <= _minWidth) { _triggerFail(); return; }
      if (_tower.length > _winCount) { _triggerWin(); return; }
    });
  }

  void _updateSwingSpeed() {
    _swingCtrl.duration = Duration(milliseconds: (2000 / _flySpeed).round());
    _swingCtrl.repeat();
  }

  void _triggerWin() {
    if (_won) return;
    setState(() => _won = true);
    _swingCtrl.stop();
    HapticFeedback.heavyImpact();
    _winCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2400), () { if (mounted) widget.onSuccess(); });
  }

  void _triggerFail() {
    if (_failed) return;
    setState(() => _failed = true);
    _swingCtrl.stop();
    _failCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2400), () { if (mounted) widget.onFail(); });
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2D),
      body: SafeArea(child: Column(children: [
        _buildHeader(),
        Expanded(child: GestureDetector(
          onTapDown: (_) => _onTap(),
          behavior: HitTestBehavior.opaque,
          child: LayoutBuilder(builder: (ctx, cst) {
            _fieldW = cst.maxWidth;
            _fieldH = cst.maxHeight;
            return Stack(children: [
              // Фон
              Positioned.fill(child: CustomPaint(painter: _BgPainter())),
              // Игровое поле
              AnimatedBuilder(
                animation: Listenable.merge([_swingCtrl, _dropCtrl, _squishCtrl, _winCtrl, _failCtrl]),
                builder: (_, __) => CustomPaint(
                  size: Size(_fieldW, _fieldH),
                  painter: _TowerPainter(
                    tower: _tower,
                    flyX: _currentFlyX,
                    flyWidth: _flyWidth,
                    flyColor: _jellyColors[_tower.length % _jellyColors.length],
                    dropping: _dropping,
                    savedFlyX: _flyX,
                    dropProgress: _dropAnim.value,
                    squishProgress: _squishAnim.value,
                    fieldW: _fieldW, fieldH: _fieldH,
                    blockH: _blockH,
                    won: _won, failed: _failed,
                  ),
                ),
              ),
              // Оверлеи
              if (_won)    _buildOverlay(true),
              if (_failed) _buildOverlay(false),
            ]);
          }),
        )),
        // Подсказка
        Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          color: const Color(0xFF0A0F2D),
          child: Text(
            _won ? '🏆 Башня построена!' :
            _failed ? '💥 Башня упала!' :
            '☝️ Нажми чтобы сбросить блок  •  ${_tower.length - 1} / $_winCount',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
          ),
        ),
      ])),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      color: const Color(0xFF0A0F2D),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00796B), Color(0xFF00D4AA)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: const Color(0xFF00D4AA).withOpacity(0.4), blurRadius: 10)],
          ),
          child: const Row(children: [
            Text('🏗️', style: TextStyle(fontSize: 13)),
            SizedBox(width: 5),
            Text('Башня из желе',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
        const Spacer(),
        // Перфекты
        if (_score > 0)
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kGold.withOpacity(0.5)),
            ),
            child: Row(children: [
              const Text('⭐', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text('×$_score', style: const TextStyle(color: kGold, fontSize: 12, fontWeight: FontWeight.w800)),
            ]),
          ),
        // Прогресс
        ...List.generate(min(_winCount, 10), (i) {
          final done = i < _tower.length - 1;
          return Padding(
            padding: const EdgeInsets.only(left: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 8, height: done ? 18 : 10,
              decoration: BoxDecoration(
                color: done
                    ? _jellyColors[i % _jellyColors.length]
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildOverlay(bool win) {
    return Positioned.fill(child: Container(
      color: Colors.black.withOpacity(0.7),
      child: ScaleTransition(
        scale: win ? _winScale : _failScale,
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(win ? '🏆' : '💥', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 14),
          Text(win ? 'Башня построена!' : 'Башня упала!',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            win
                ? '${_tower.length - 1} блоков • $_score перфектов ⭐'
                : 'Блоков уложено: ${_tower.length - 1}',
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14),
          ),
        ])),
      ),
    ));
  }
}

// ─── Painter башни ────────────────────────────────────────────────────────
class _TowerPainter extends CustomPainter {
  final List<_Block> tower;
  final double flyX, flyWidth;
  final Color flyColor;
  final bool dropping;
  final double savedFlyX;
  final double dropProgress;
  final double squishProgress;
  final double fieldW, fieldH, blockH;
  final bool won, failed;

  _TowerPainter({
    required this.tower, required this.flyX, required this.flyWidth,
    required this.flyColor, required this.dropping, required this.savedFlyX,
    required this.dropProgress, required this.squishProgress,
    required this.fieldW, required this.fieldH, required this.blockH,
    required this.won, required this.failed,
  });

  // Нижняя Y последнего блока башни
  double _blockTop(int idx) {
    // Башня строится снизу вверх
    return fieldH - blockH * (idx + 1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Рисуем башню снизу вверх
    for (int i = 0; i < tower.length; i++) {
      final b = tower[i];
      final top = _blockTop(i);
      final isTop = i == tower.length - 1;

      // Squish-эффект для верхнего блока
      double scaleY = 1.0, scaleX = 1.0;
      if (isTop && squishProgress < 1.0) {
        final squish = 1.0 - squishProgress;
        scaleY = 1.0 - 0.18 * sin(squish * pi);
        scaleX = 1.0 + 0.09 * sin(squish * pi);
      }

      _drawJelly(canvas, b, top, scaleX, scaleY);
    }

    // Летящий блок
    if (!won && !failed) {
      double flyTop;
      if (dropping) {
        // Анимация падения от верха к верхушке башни
        final targetTop = _blockTop(tower.length);
        final startTop  = fieldH * 0.05;
        flyTop = startTop + (targetTop - startTop) * dropProgress;
      } else {
        flyTop = fieldH * 0.05;
      }

      final block = _Block(
        x: dropping ? savedFlyX : flyX,
        width: flyWidth,
        color: flyColor,
      );
      _drawJelly(canvas, block, flyTop, 1.0, 1.0, isFlying: true);

      // Тень под летящим блоком
      if (!dropping) {
        final shadowW = flyWidth * fieldW;
        final shadowX = flyX * fieldW;
        final targetY = _blockTop(tower.length);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(shadowX + shadowW / 2, targetY + blockH * 0.85),
            width: shadowW * 0.9,
            height: 10,
          ),
          Paint()..color = flyColor.withOpacity(0.15),
        );
      }
    }
  }

  void _drawJelly(Canvas canvas, _Block b, double top, double scaleX, double scaleY,
      {bool isFlying = false}) {
    final left  = b.x * fieldW;
    final w     = b.width * fieldW;
    final cx    = left + w / 2;
    final cy    = top + blockH / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-cx, -cy);

    final rect = Rect.fromLTWH(left + 2, top + 2, w - 4, blockH - 4);
    final rr   = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // Тело желе
    final gradient = LinearGradient(
      colors: [
        b.color.withOpacity(isFlying ? 0.9 : 0.85),
        b.color.withOpacity(isFlying ? 0.6 : 0.55),
      ],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    );
    canvas.drawRRect(rr, Paint()..shader = gradient.createShader(rect));

    // Полупрозрачный верхний блик
    final shimmerRect = Rect.fromLTWH(left + 6, top + 4, w - 12, blockH * 0.38);
    final shimmerRR   = RRect.fromRectAndRadius(shimmerRect, const Radius.circular(8));
    canvas.drawRRect(shimmerRR,
        Paint()..color = Colors.white.withOpacity(0.22));

    // Обводка
    canvas.drawRRect(rr, Paint()
      ..color = b.color.withOpacity(0.9)
      ..style = PaintingStyle.stroke..strokeWidth = 2);

    // Свечение у летящего
    if (isFlying) {
      canvas.drawRRect(rr.inflate(4), Paint()
        ..color = b.color.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_TowerPainter old) => true;
}

// ─── Фон ─────────────────────────────────────────────────────────────────
class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Градиентный фон
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..shader = const LinearGradient(
          colors: [Color(0xFF0A0F2D), Color(0xFF151A3A)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Линия платформы
    canvas.drawLine(
      Offset(0, size.height - 10),
      Offset(size.width, size.height - 10),
      Paint()..color = Colors.white.withOpacity(0.06)..strokeWidth = 1,
    );

    // Вертикальные направляющие
    for (int i = 1; i <= 3; i++) {
      canvas.drawLine(
        Offset(size.width * i / 4, 0),
        Offset(size.width * i / 4, size.height),
        Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 0.5,
      );
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => false;
}
