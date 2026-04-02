// lib/game/star_drift_game.dart
//
// «Звёздный дрифт» — уклоняйся от астероидов, собирай щиты.
// Квест 5 «Путь к диплому» — финальный забег через весь корпус.
//
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

// ─── Астероид ─────────────────────────────────────────────────────────────
class _Asteroid {
  double x, y;
  final double radius;
  final double speed;
  final double rotSpeed;
  double rotation = 0;
  final int sides;    // количество вершин (3–7)
  final Color color;

  _Asteroid({
    required this.x, required this.y,
    required this.radius, required this.speed,
    required this.rotSpeed, required this.sides,
    required this.color,
  });
}

// ─── Щит / Предмет ────────────────────────────────────────────────────────
class _Pickup {
  double x, y;
  final bool isShield;
  double pulse = 0;
  _Pickup({required this.x, required this.y, required this.isShield});
}

// ─── Частица взрыва ───────────────────────────────────────────────────────
class _Spark {
  double x, y, vx, vy, life;
  final Color color;
  _Spark({required this.x, required this.y,
    required this.vx, required this.vy,
    required this.color}) : life = 1.0;
}

// ─── Главный виджет ───────────────────────────────────────────────────────
class StarDriftGame extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const StarDriftGame({super.key, required this.onSuccess, required this.onFail});

  @override
  State<StarDriftGame> createState() => _StarDriftGameState();
}

class _StarDriftGameState extends State<StarDriftGame> with TickerProviderStateMixin {
  double _w = 0, _h = 0;

  // Игрок
  double _px = 0, _py = 0;
  double _targetPy = 0;

  // Игровые объекты
  final List<_Asteroid> _asteroids = [];
  final List<_Pickup> _pickups = [];
  final List<_Spark> _sparks = [];
  final List<Offset> _trail = [];

  // Состояние
  int _shield = 0;     // секунды щита
  int _score = 0;
  int _timeLeft = 45;
  double _speed = 1.0; // множитель скорости
  bool _won = false, _failed = false;

  final _rng = Random();
  double _spawnAccum = 0;
  double _pickupAccum = 0;
  DateTime? _lastTick;

  late AnimationController _tickCtrl, _winCtrl, _failCtrl;
  late Animation<double> _winScale, _failScale;

  @override
  void initState() {
    super.initState();
    _tickCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 300))
      ..addListener(_tick)..forward();
    _winCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _failCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _winScale  = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _winCtrl,  curve: Curves.elasticOut));
    _failScale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _failCtrl, curve: Curves.easeOut));

    _startTimer();
  }

  @override
  void dispose() {
    _tickCtrl.dispose(); _winCtrl.dispose(); _failCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _won || _failed) return false;
      setState(() {
        _timeLeft--;
        _shield = (_shield - 1).clamp(0, 99);
        _speed  = 1.0 + (45 - _timeLeft) * 0.02; // ускорение с каждой секундой
        _score  += 5;
      });
      if (_timeLeft <= 0) { _triggerWin(); return false; }
      return true;
    });
  }

  void _tick() {
    if (_w == 0 || _won || _failed) return;
    final now = DateTime.now();
    final dt = _lastTick == null
        ? 0.016
        : (now.difference(_lastTick!).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTick = now;

    setState(() {
      // Инициализация позиции
      if (_px == 0) { _px = 80; _py = _h / 2; _targetPy = _py; }

      // Плавное движение игрока к цели
      _py += (_targetPy - _py) * 8 * dt;
      _py = _py.clamp(30, _h - 30);

      // Шлейф
      _trail.add(Offset(_px, _py));
      if (_trail.length > 20) _trail.removeAt(0);

      // Спавн астероидов
      _spawnAccum += dt * (2.5 + _speed * 1.5);
      while (_spawnAccum >= 1) {
        _spawnAccum -= 1;
        _spawnAsteroid();
      }

      // Спавн предметов
      _pickupAccum += dt;
      if (_pickupAccum > 3) {
        _pickupAccum = 0;
        _pickups.add(_Pickup(
          x: _w + 20,
          y: 40 + _rng.nextDouble() * (_h - 80),
          isShield: _rng.nextDouble() < 0.3,
        ));
      }

      // Обновление астероидов
      final baseSpd = 200 * _speed;
      for (final a in _asteroids) {
        a.x -= (baseSpd + a.speed) * dt;
        a.rotation += a.rotSpeed * dt;
      }
      _asteroids.removeWhere((a) => a.x + a.radius < 0);

      // Обновление предметов
      for (final p in _pickups) {
        p.x -= (baseSpd * 0.8) * dt;
        p.pulse += dt * 3;
      }
      _pickups.removeWhere((p) => p.x < -20);

      // Обновление искр
      for (final s in _sparks) {
        s.x += s.vx * dt;
        s.y += s.vy * dt;
        s.vx *= 0.96;
        s.vy *= 0.96;
        s.life -= dt * 2.5;
      }
      _sparks.removeWhere((s) => s.life <= 0);

      // Коллизии: предметы
      _pickups.removeWhere((p) {
        if ((p.x - _px).abs() < 22 && (p.y - _py).abs() < 22) {
          if (p.isShield) { _shield = 5; HapticFeedback.mediumImpact(); }
          else { _score += 20; HapticFeedback.selectionClick(); }
          return true;
        }
        return false;
      });

      // Коллизии: астероиды
      for (final a in _asteroids) {
        final dx = a.x - _px;
        final dy = a.y - _py;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < a.radius + 14) {
          if (_shield > 0) {
            // Щит поглощает
            _shield = 0;
            _explode(a.x, a.y, a.color);
            _asteroids.remove(a);
            HapticFeedback.mediumImpact();
            break;
          } else {
            _triggerFail();
            return;
          }
        }
      }
    });
  }

  void _spawnAsteroid() {
    final colors = [
      const Color(0xFF607D8B),
      const Color(0xFF455A64),
      const Color(0xFF546E7A),
      const Color(0xFF78909C),
    ];
    final r = 14.0 + _rng.nextDouble() * 22;
    _asteroids.add(_Asteroid(
      x: _w + r,
      y: r + _rng.nextDouble() * (_h - r * 2),
      radius: r,
      speed: 40 + _rng.nextDouble() * 80,
      rotSpeed: (_rng.nextDouble() - 0.5) * 3,
      sides: 4 + _rng.nextInt(4),
      color: colors[_rng.nextInt(colors.length)],
    ));
  }

  void _explode(double x, double y, Color color) {
    for (int i = 0; i < 12; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 80 + _rng.nextDouble() * 160;
      _sparks.add(_Spark(
        x: x, y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: color,
      ));
    }
  }

  void _triggerWin() {
    if (_won) return;
    _tickCtrl.stop();
    setState(() => _won = true);
    HapticFeedback.heavyImpact();
    _winCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) widget.onSuccess();
    });
  }

  void _triggerFail() {
    if (_failed) return;
    _tickCtrl.stop();
    _explode(_px, _py, kGreen);
    setState(() => _failed = true);
    _failCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2400), () {
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
              onVerticalDragUpdate: (d) {
                setState(() => _targetPy = (_targetPy + d.delta.dy).clamp(30, _h - 30));
              },
              onPanUpdate: (d) {
                setState(() {
                  _targetPy = (_targetPy + d.delta.dy).clamp(30, _h - 30);
                });
              },
              behavior: HitTestBehavior.opaque,
              child: LayoutBuilder(builder: (ctx, cst) {
                _w = cst.maxWidth; _h = cst.maxHeight;
                return AnimatedBuilder(
                  animation: _tickCtrl,
                  builder: (_, __) => CustomPaint(
                    size: Size(_w, _h),
                    painter: _StarDriftPainter(
                      asteroids: List.from(_asteroids),
                      pickups: List.from(_pickups),
                      sparks: List.from(_sparks),
                      trail: List.from(_trail),
                      px: _px, py: _py,
                      shield: _shield,
                      won: _won, failed: _failed,
                    ),
                  ),
                );
              }),
            ),
            if (_won) _buildWinOverlay(),
            if (_failed) _buildFailOverlay(),
          ])),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    final timeColor = _timeLeft > 20 ? kGreen : (_timeLeft > 8 ? Colors.orange : kRed);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      color: Colors.black,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF00BCD4)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: const Color(0xFF00BCD4).withOpacity(0.4), blurRadius: 10)],
          ),
          child: const Row(children: [
            Text('🚀', style: TextStyle(fontSize: 13)),
            SizedBox(width: 5),
            Text('Звёздный дрифт',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
        const Spacer(),
        if (_shield > 0)
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kBlue.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBlue),
            ),
            child: Row(children: [
              const Text('🛡️', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text('${_shield}s', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        Text('Очки: $_score',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(width: 14),
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: timeColor, width: 2),
            shape: BoxShape.circle,
            color: timeColor.withOpacity(0.1),
          ),
          child: Center(child: Text('$_timeLeft',
              style: TextStyle(color: timeColor, fontSize: 13, fontWeight: FontWeight.w900))),
        ),
      ]),
    );
  }

  Widget _buildWinOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: ScaleTransition(scale: _winScale, child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎓', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text('Диплом получен!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Набрано $_score очков',
                style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 14)),
          ],
        ))),
      ),
    );
  }

  Widget _buildFailOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: ScaleTransition(scale: _failScale, child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💥', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text('Сбит астероидом!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Очков было: $_score',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
          ],
        ))),
      ),
    );
  }
}

class _StarDriftPainter extends CustomPainter {
  final List<_Asteroid> asteroids;
  final List<_Pickup> pickups;
  final List<_Spark> sparks;
  final List<Offset> trail;
  final double px, py;
  final int shield;
  final bool won, failed;

  static final _rng = Random(1);

  _StarDriftPainter({
    required this.asteroids, required this.pickups, required this.sparks,
    required this.trail, required this.px, required this.py,
    required this.shield, required this.won, required this.failed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawStarfield(canvas, size);
    _drawTrail(canvas);
    _drawPickups(canvas);
    _drawAsteroids(canvas);
    _drawSparks(canvas);
    _drawPlayer(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF03060F));

    // Дальние туманности
    for (int i = 0; i < 2; i++) {
      final cx = size.width * (0.3 + i * 0.5);
      final cy = size.height * (0.3 + i * 0.4);
      canvas.drawCircle(Offset(cx, cy), size.width * 0.22,
          Paint()..shader = RadialGradient(
            colors: [const Color(0xFF0D47A1).withOpacity(0.08), Colors.transparent],
          ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.22)));
    }
  }

  void _drawStarfield(Canvas canvas, Size size) {
    final tick = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < 60; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      final twinkle = 0.3 + 0.7 * sin(tick / 1000.0 + i * 1.3);
      canvas.drawCircle(Offset(x, y), 1 + _rng.nextDouble(),
          Paint()..color = Colors.white.withOpacity(0.2 + 0.4 * twinkle));
    }
  }

  void _drawTrail(Canvas canvas) {
    for (int i = 1; i < trail.length; i++) {
      final t = i / trail.length;
      canvas.drawCircle(trail[i], 5 * t,
          Paint()..color = kGreen.withOpacity(t * 0.5)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * t));
    }
  }

  void _drawPickups(Canvas canvas) {
    for (final p in pickups) {
      final pulse = 0.8 + 0.2 * sin(p.pulse);
      final color = p.isShield ? kBlue : kGold;
      canvas.drawCircle(Offset(p.x, p.y), 14 * pulse,
          Paint()..color = color.withOpacity(0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawCircle(Offset(p.x, p.y), 8,
          Paint()..color = color.withOpacity(0.9));
      final tp = TextPainter(
        text: TextSpan(text: p.isShield ? '🛡️' : '⭐', style: const TextStyle(fontSize: 14)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.x - tp.width / 2, p.y - tp.height / 2));
    }
  }

  void _drawAsteroids(Canvas canvas) {
    for (final a in asteroids) {
      canvas.save();
      canvas.translate(a.x, a.y);
      canvas.rotate(a.rotation);

      final path = _buildAsteroidPath(a.radius, a.sides);

      // Свечение
      canvas.drawPath(path,
          Paint()..color = a.color.withOpacity(0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      // Тело
      canvas.drawPath(path, Paint()..color = a.color.withOpacity(0.75));
      // Контур
      canvas.drawPath(path,
          Paint()..color = a.color.withOpacity(0.9)
            ..style = PaintingStyle.stroke..strokeWidth = 1.5);

      canvas.restore();
    }
  }

  Path _buildAsteroidPath(double r, int sides) {
    final path = Path();
    final rng2 = Random(sides);
    for (int i = 0; i < sides; i++) {
      final angle = 2 * pi * i / sides;
      final radius = r * (0.75 + rng2.nextDouble() * 0.35);
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  void _drawSparks(Canvas canvas) {
    for (final s in sparks) {
      canvas.drawCircle(Offset(s.x, s.y), 3 * s.life,
          Paint()..color = s.color.withOpacity(s.life)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
  }

  void _drawPlayer(Canvas canvas, Size size) {
    if (px == 0) return;

    // Щит
    if (shield > 0) {
      final pulse = 0.7 + 0.3 * sin(DateTime.now().millisecondsSinceEpoch / 150.0);
      canvas.drawCircle(Offset(px, py), 24 * pulse,
          Paint()..color = kBlue.withOpacity(0.2 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawCircle(Offset(px, py), 20,
          Paint()..color = kBlue.withOpacity(0.4 * pulse)
            ..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    // Двигатель (огонь сзади)
    final enginePath = Path()
      ..moveTo(px - 18, py - 5)
      ..lineTo(px - 32, py)
      ..lineTo(px - 18, py + 5)
      ..close();
    canvas.drawPath(enginePath,
        Paint()..shader = LinearGradient(
          colors: [Colors.orange.withOpacity(0.9), Colors.transparent],
          begin: Alignment.centerRight, end: Alignment.centerLeft,
        ).createShader(Rect.fromLTWH(px - 32, py - 5, 14, 10)));

    // Корпус ракеты
    final rocketPath = Path()
      ..moveTo(px + 20, py)       // нос
      ..lineTo(px - 12, py - 10)  // верх
      ..lineTo(px - 18, py - 10)  // хвост верх
      ..lineTo(px - 18, py + 10)  // хвост низ
      ..lineTo(px - 12, py + 10)  // низ
      ..close();

    // Свечение
    canvas.drawPath(rocketPath,
        Paint()..color = kGreen.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    // Тело
    canvas.drawPath(rocketPath,
        Paint()..shader = LinearGradient(
          colors: [kGreen, const Color(0xFF00A080)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(px - 18, py - 10, 38, 20)));
    // Контур
    canvas.drawPath(rocketPath,
        Paint()..color = kGreen.withOpacity(0.8)
          ..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Иллюминатор
    canvas.drawCircle(Offset(px + 2, py), 4,
        Paint()..color = const Color(0xFF00F5FF).withOpacity(0.8));
    canvas.drawCircle(Offset(px + 2, py), 2,
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_StarDriftPainter old) => true;
}
