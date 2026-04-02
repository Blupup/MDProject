// lib/game/shadow_escape_game.dart
//
// «Побег тени» — минималистичный платформер. Чёрный силуэт, один акцент — неон.
// Квест 4 «Cyber Life» — беги по скрытым уровням корпуса.
//
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

// ─── Платформа ────────────────────────────────────────────────────────────
class _Platform {
  double x, y;
  final double width;
  final bool isMoving;
  double moveDir;
  final double moveRange;
  double moveOrigin;

  _Platform({
    required this.x, required this.y, required this.width,
    this.isMoving = false, this.moveDir = 1.0, this.moveRange = 0,
  }) : moveOrigin = x;

  Rect get rect => Rect.fromLTWH(x, y, width, 14);

  void update(double dt) {
    if (!isMoving) return;
    x += moveDir * 120 * dt;
    if ((x - moveOrigin).abs() > moveRange) {
      moveDir *= -1;
    }
  }
}

// ─── Монета ───────────────────────────────────────────────────────────────
class _Coin {
  final double x, y;
  bool collected = false;
  _Coin(this.x, this.y);
  Rect get rect => Rect.fromLTWH(x - 8, y - 8, 16, 16);
}

// ─── Уровень ──────────────────────────────────────────────────────────────
class _LevelData {
  final String name;
  final List<_Platform> platforms;
  final List<_Coin> coins;
  final Offset goal;

  const _LevelData({
    required this.name,
    required this.platforms,
    required this.coins,
    required this.goal,
  });
}

List<_LevelData> _buildLevels(double w, double h) => [
  _LevelData(
    name: 'Подвал',
    goal: Offset(w - 60, h * 0.12),
    coins: [
      _Coin(w * 0.35, h * 0.72),
      _Coin(w * 0.55, h * 0.52),
      _Coin(w * 0.7,  h * 0.32),
    ],
    platforms: [
      _Platform(x: 0,          y: h * 0.85, width: w),           // пол
      _Platform(x: w * 0.2,    y: h * 0.68, width: w * 0.25),
      _Platform(x: w * 0.5,    y: h * 0.5,  width: w * 0.22),
      _Platform(x: w * 0.65,   y: h * 0.32, width: w * 0.25),
      _Platform(x: w * 0.72,   y: h * 0.15, width: w * 0.28),    // финальная
    ],
  ),
  _LevelData(
    name: 'Игровая',
    goal: Offset(w * 0.88, h * 0.1),
    coins: [
      _Coin(w * 0.3,  h * 0.6),
      _Coin(w * 0.5,  h * 0.42),
      _Coin(w * 0.72, h * 0.22),
    ],
    platforms: [
      _Platform(x: 0, y: h * 0.85, width: w),
      _Platform(x: w * 0.15, y: h * 0.65, width: w * 0.2,
          isMoving: true, moveDir: 1, moveRange: 80),
      _Platform(x: w * 0.45, y: h * 0.45, width: w * 0.18),
      _Platform(x: w * 0.62, y: h * 0.28, width: w * 0.2,
          isMoving: true, moveDir: -1, moveRange: 60),
      _Platform(x: w * 0.72, y: h * 0.12, width: w * 0.28),
    ],
  ),
  _LevelData(
    name: 'Медиа-студия',
    goal: Offset(w * 0.86, h * 0.07),
    coins: [
      _Coin(w * 0.22, h * 0.56),
      _Coin(w * 0.44, h * 0.38),
      _Coin(w * 0.66, h * 0.2),
    ],
    platforms: [
      _Platform(x: 0, y: h * 0.85, width: w),
      _Platform(x: w * 0.1, y: h * 0.65, width: w * 0.18),
      _Platform(x: w * 0.3, y: h * 0.5,  width: w * 0.15,
          isMoving: true, moveDir: 1, moveRange: 70),
      _Platform(x: w * 0.5, y: h * 0.36, width: w * 0.18),
      _Platform(x: w * 0.65, y: h * 0.22, width: w * 0.16,
          isMoving: true, moveDir: -1, moveRange: 50),
      _Platform(x: w * 0.72, y: h * 0.08, width: w * 0.28),
    ],
  ),
];

// ─── Главный виджет ───────────────────────────────────────────────────────
class ShadowEscapeGame extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const ShadowEscapeGame({super.key, required this.onSuccess, required this.onFail});

  @override
  State<ShadowEscapeGame> createState() => _ShadowEscapeGameState();
}

class _ShadowEscapeGameState extends State<ShadowEscapeGame> with TickerProviderStateMixin {
  // Размеры поля
  double _w = 0, _h = 0;
  List<_LevelData>? _levels;

  int _levelIdx = 0;
  int _lives = 3;
  int _score = 0;
  bool _won = false, _failed = false;

  // Игрок
  double _px = 0, _py = 0;
  double _pvx = 0, _pvy = 0;
  bool _onGround = false;
  bool _jumpPressed = false;
  bool _facingRight = true;
  double _playerW = 28, _playerH = 42;
  int _jumpsLeft = 2;

  // Анимация
  late AnimationController _tickCtrl, _winCtrl, _failCtrl;
  late Animation<double> _winScale, _failScale;
  DateTime? _lastTick;

  // Шлейф
  final List<Offset> _trail = [];

  @override
  void initState() {
    super.initState();
    _tickCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 600))
      ..addListener(_tick)..forward();
    _winCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _failCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _winScale  = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _winCtrl,  curve: Curves.elasticOut));
    _failScale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _failCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _tickCtrl.dispose(); _winCtrl.dispose(); _failCtrl.dispose();
    super.dispose();
  }

  void _initLevel() {
    if (_levels == null) return;
    final lv = _levels![_levelIdx];
    _px = 60;
    _py = _h * 0.75;
    _pvx = 0; _pvy = 0;
    _onGround = false;
    _trail.clear();
    for (final p in lv.platforms) { p.x = p.moveOrigin; }
    for (final c in lv.coins) { c.collected = false; }
  }

  void _tick() {
    if (_w == 0 || _levels == null || _won || _failed) return;
    final now = DateTime.now();
    final dt = _lastTick == null
        ? 0.016
        : (now.difference(_lastTick!).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTick = now;

    setState(() {
      final lv = _levels![_levelIdx];

      // Обновление платформ
      for (final p in lv.platforms) p.update(dt);

      // Движение игрока
      const gravity = 900.0;
      _pvy += gravity * dt;

      // Авто-движение вправо
      _pvx = 130;
      if (_facingRight) _pvx = 130; else _pvx = -130;

      _px += _pvx * dt;
      _py += _pvy * dt;

      // Шлейф
      _trail.add(Offset(_px + _playerW / 2, _py + _playerH / 2));
      if (_trail.length > 12) _trail.removeAt(0);

      // Коллизии с платформами
      _onGround = false;
      final playerRect = Rect.fromLTWH(_px, _py, _playerW, _playerH);
      for (final p in lv.platforms) {
        final pRect = p.rect;
        if (playerRect.overlaps(pRect)) {
          final overlapBottom = playerRect.bottom - pRect.top;
          final overlapTop    = pRect.bottom - playerRect.top;
          final overlapLeft   = playerRect.right - pRect.left;
          final overlapRight  = pRect.right - playerRect.left;
          final minOverlap = [overlapBottom, overlapTop, overlapLeft, overlapRight].reduce(min);

          if (minOverlap == overlapBottom && _pvy >= 0) {
            _py = pRect.top - _playerH;
            _pvy = 0;
            _onGround = true;
            _jumpsLeft = 2;
          } else if (minOverlap == overlapTop && _pvy < 0) {
            _py = pRect.bottom;
            _pvy = 0;
          } else if (minOverlap == overlapLeft) {
            _px = pRect.left - _playerW;
            _facingRight = false;
          } else {
            _px = pRect.right;
            _facingRight = true;
          }
        }
      }

      // Стены экрана
      if (_px < 0) { _px = 0; _facingRight = true; }
      if (_px + _playerW > _w) { _px = _w - _playerW; _facingRight = false; }

      // Упал вниз
      if (_py > _h + 60) {
        _lives--;
        if (_lives <= 0) { _triggerFail(); return; }
        _initLevel();
        return;
      }

      // Монеты
      final pr = Rect.fromLTWH(_px, _py, _playerW, _playerH);
      for (final c in lv.coins) {
        if (!c.collected && pr.overlaps(c.rect)) {
          c.collected = true;
          _score += 10;
          HapticFeedback.selectionClick();
        }
      }

      // Цель
      final goalRect = Rect.fromLTWH(lv.goal.dx - 20, lv.goal.dy - 20, 40, 40);
      if (pr.overlaps(goalRect)) {
        _triggerWin();
      }
    });
  }

  void _onJump() {
    if (_won || _failed) return;
    if (_jumpsLeft > 0) {
      setState(() {
        _pvy = -580;
        _jumpsLeft--;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _triggerWin() {
    if (_won) return;
    setState(() => _won = true);
    _tickCtrl.stop();
    HapticFeedback.heavyImpact();
    _winCtrl.forward();

    if (_levelIdx < _levels!.length - 1) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _levelIdx++;
          _won = false;
          _lives = 3;
        });
        _winCtrl.reset();
        _tickCtrl.forward(from: 0);
        _lastTick = null;
        _initLevel();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted) widget.onSuccess();
      });
    }
  }

  void _triggerFail() {
    if (_failed) return;
    _tickCtrl.stop();
    setState(() => _failed = true);
    _failCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) widget.onFail();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(child: Stack(children: [
            GestureDetector(
              onTapDown: (_) => _onJump(),
              behavior: HitTestBehavior.opaque,
              child: LayoutBuilder(builder: (ctx, cst) {
                _w = cst.maxWidth; _h = cst.maxHeight;
                if (_levels == null) {
                  _levels = _buildLevels(_w, _h);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(_initLevel);
                  });
                }
                return AnimatedBuilder(
                  animation: _tickCtrl,
                  builder: (_, __) => CustomPaint(
                    size: Size(_w, _h),
                    painter: _ShadowPainter(
                      levels: _levels,
                      levelIdx: _levelIdx,
                      px: _px, py: _py,
                      playerW: _playerW, playerH: _playerH,
                      trail: List.from(_trail),
                      won: _won,
                      onGround: _onGround,
                      facingRight: _facingRight,
                    ),
                  ),
                );
              }),
            ),
            if (_won && _levelIdx == (_levels?.length ?? 1) - 1)
              _buildWinOverlay(),
            if (_failed)
              _buildFailOverlay(),
            // Кнопка прыжка
            Positioned(
              bottom: 20, right: 20,
              child: GestureDetector(
                onTapDown: (_) => _onJump(),
                child: Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
                  ),
                  child: const Icon(Icons.keyboard_arrow_up_rounded,
                      color: Colors.white54, size: 36),
                ),
              ),
            ),
          ])),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      color: Colors.black,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.grey.shade800, Colors.grey.shade600]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(children: [
            Text('👾', style: TextStyle(fontSize: 13)),
            SizedBox(width: 5),
            Text('Побег тени',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
        const Spacer(),
        if (_levels != null)
          Text('${_levels![_levelIdx].name}',
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(width: 10),
        Text('Очки: $_score',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(width: 10),
        Row(children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.only(left: 3),
          child: Icon(
            i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: i < _lives ? kRed : Colors.white12,
            size: 18,
          ),
        ))),
      ]),
    );
  }

  Widget _buildWinOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: ScaleTransition(scale: _winScale, child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌟', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text('Уровень пройден!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Очков: $_score',
                style: const TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ))),
      ),
    );
  }

  Widget _buildFailOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: ScaleTransition(scale: _failScale, child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💀', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text('Тень поглотила!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Очков набрано: $_score',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
          ],
        ))),
      ),
    );
  }
}

class _ShadowPainter extends CustomPainter {
  final List<_LevelData>? levels;
  final int levelIdx;
  final double px, py, playerW, playerH;
  final List<Offset> trail;
  final bool won, onGround, facingRight;

  _ShadowPainter({
    required this.levels, required this.levelIdx,
    required this.px, required this.py,
    required this.playerW, required this.playerH,
    required this.trail, required this.won,
    required this.onGround, required this.facingRight,
  });

  // Акцентный цвет — неоново-красный
  static const _accent = Color(0xFFFF2244);

  @override
  void paint(Canvas canvas, Size size) {
    if (levels == null) return;
    final lv = levels![levelIdx];

    _drawBackground(canvas, size);
    _drawPlatforms(canvas, lv);
    _drawCoins(canvas, lv);
    _drawGoal(canvas, lv);
    _drawTrail(canvas);
    _drawPlayer(canvas);
  }

  void _drawBackground(Canvas canvas, Size size) {
    // Чёрный фон
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF080808));

    // Силуэтные облака на фоне
    for (int i = 0; i < 5; i++) {
      final cx = size.width * (0.1 + i * 0.2);
      final cy = size.height * 0.25;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: 120, height: 30),
        Paint()..color = const Color(0xFF111111),
      );
    }

    // Туман снизу
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.2),
      Paint()..shader = LinearGradient(
        colors: [Colors.transparent, _accent.withOpacity(0.04)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.2)),
    );
  }

  void _drawPlatforms(Canvas canvas, _LevelData lv) {
    for (final p in lv.platforms) {
      final r = p.rect;
      // Тело
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(4)),
        Paint()..color = const Color(0xFF1A1A1A),
      );
      // Акцентная верхняя грань
      canvas.drawLine(
        Offset(r.left + 4, r.top + 2),
        Offset(r.right - 4, r.top + 2),
        Paint()..color = _accent.withOpacity(0.7)..strokeWidth = 2..strokeCap = StrokeCap.round,
      );
      // Свечение
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(2), const Radius.circular(5)),
        Paint()..color = _accent.withOpacity(0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  void _drawCoins(Canvas canvas, _LevelData lv) {
    for (final c in lv.coins) {
      if (c.collected) continue;
      canvas.drawCircle(Offset(c.x, c.y), 8,
          Paint()..color = _accent.withOpacity(0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawCircle(Offset(c.x, c.y), 5,
          Paint()..color = _accent.withOpacity(0.8));
      canvas.drawCircle(Offset(c.x, c.y), 5,
          Paint()..color = _accent
            ..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  void _drawGoal(Canvas canvas, _LevelData lv) {
    final pulse = 0.7 + 0.3 * sin(DateTime.now().millisecondsSinceEpoch / 400.0);
    canvas.drawCircle(lv.goal, 22 * pulse,
        Paint()..color = Colors.white.withOpacity(0.06 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    canvas.drawCircle(lv.goal, 14,
        Paint()..color = Colors.white.withOpacity(0.9));
    canvas.drawCircle(lv.goal, 14,
        Paint()..color = Colors.white
          ..style = PaintingStyle.stroke..strokeWidth = 2);

    final tp = TextPainter(
      text: const TextSpan(text: '🚪', style: TextStyle(fontSize: 16)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, lv.goal - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawTrail(Canvas canvas) {
    for (int i = 1; i < trail.length; i++) {
      final t = i / trail.length;
      canvas.drawCircle(trail[i], 3 * t,
          Paint()..color = _accent.withOpacity(t * 0.35));
    }
  }

  void _drawPlayer(Canvas canvas) {
    if (px == 0 && py == 0) return;
    final center = Offset(px + playerW / 2, py + playerH / 2);

    // Тень под игроком
    if (onGround) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, py + playerH + 2), width: playerW * 0.8, height: 5),
        Paint()..color = _accent.withOpacity(0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Свечение
    canvas.drawRect(
      Rect.fromLTWH(px - 4, py - 4, playerW + 8, playerH + 8),
      Paint()..color = _accent.withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Тело — чёрный силуэт
    canvas.save();
    if (!facingRight) {
      canvas.translate(px + playerW / 2, 0);
      canvas.scale(-1, 1);
      canvas.translate(-(px + playerW / 2), 0);
    }

    // Голова
    canvas.drawOval(
      Rect.fromLTWH(px + 4, py, playerW - 8, playerH * 0.42),
      Paint()..color = Colors.black,
    );
    // Тело
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(px + 2, py + playerH * 0.38, playerW - 4, playerH * 0.42),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.black,
    );
    // Ноги
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(px + 2, py + playerH * 0.76, (playerW - 6) / 2, playerH * 0.24),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.black,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(px + (playerW) / 2 + 1, py + playerH * 0.76, (playerW - 6) / 2, playerH * 0.24),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.black,
    );

    // Контур — акцентный
    final outlinePaint = Paint()
      ..color = _accent.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawOval(Rect.fromLTWH(px + 4, py, playerW - 8, playerH * 0.42), outlinePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(px + 2, py + playerH * 0.38, playerW - 4, playerH * 0.42),
        const Radius.circular(3),
      ),
      outlinePaint,
    );

    // Глаза — белые точки
    canvas.drawCircle(Offset(px + playerW * 0.55, py + playerH * 0.18), 3,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(px + playerW * 0.55, py + playerH * 0.18), 1.5,
        Paint()..color = Colors.black);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShadowPainter old) => true;
}
