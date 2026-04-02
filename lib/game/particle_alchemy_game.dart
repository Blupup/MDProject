// lib/game/particle_alchemy_game.dart
//
// «Алхимия частиц» — управляй точкой притяжения чтобы провести поток частиц в чашу.
// Квест 3 «Debug» — отлаживай поток как в коде.
//
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

// ─── Частица ──────────────────────────────────────────────────────────────
class _Particle {
  double x, y, vx, vy;
  final double hue;   // для цвета
  double life;        // 0..1

  _Particle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.hue,
    this.life = 1.0,
  });
}

// ─── Уровень ──────────────────────────────────────────────────────────────
class _LevelConfig {
  final String name;
  final Offset spawnPoint;
  final Offset cupCenter;
  final double cupRadius;
  final List<Rect> walls;
  final int particlesNeeded;

  const _LevelConfig({
    required this.name,
    required this.spawnPoint,
    required this.cupCenter,
    required this.cupRadius,
    required this.walls,
    required this.particlesNeeded,
  });
}

// ─── Главный виджет ───────────────────────────────────────────────────────
class ParticleAlchemyGame extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const ParticleAlchemyGame({super.key, required this.onSuccess, required this.onFail});

  @override
  State<ParticleAlchemyGame> createState() => _ParticleAlchemyGameState();
}

class _ParticleAlchemyGameState extends State<ParticleAlchemyGame>
    with TickerProviderStateMixin {

  static const _levelConfigs = [
    _LevelConfig(
      name: 'Прямой поток',
      spawnPoint: Offset(0.5, 0.08),
      cupCenter: Offset(0.5, 0.88),
      cupRadius: 0.09,
      walls: [],
      particlesNeeded: 15,
    ),
    _LevelConfig(
      name: 'Первый барьер',
      spawnPoint: Offset(0.5, 0.08),
      cupCenter: Offset(0.5, 0.88),
      cupRadius: 0.08,
      walls: [
        Rect.fromLTWH(0.1, 0.4, 0.35, 0.04),
        Rect.fromLTWH(0.55, 0.55, 0.35, 0.04),
      ],
      particlesNeeded: 20,
    ),
    _LevelConfig(
      name: 'Лабиринт',
      spawnPoint: Offset(0.15, 0.08),
      cupCenter: Offset(0.82, 0.88),
      cupRadius: 0.07,
      walls: [
        Rect.fromLTWH(0.1,  0.28, 0.55, 0.04),
        Rect.fromLTWH(0.35, 0.48, 0.55, 0.04),
        Rect.fromLTWH(0.1,  0.68, 0.55, 0.04),
      ],
      particlesNeeded: 25,
    ),
  ];

  int _levelIdx = 0;
  final List<_Particle> _particles = [];
  Offset? _attractorPos;      // позиция «чёрной дыры» (палец)
  int _captured = 0;
  int _timeLeft = 45;
  bool _won = false, _failed = false;

  late AnimationController _tickCtrl, _winCtrl, _failCtrl;
  late Animation<double> _winScale, _failScale;

  DateTime? _lastTick;
  final _rng = Random();
  double _spawnAccum = 0;
  double _w = 0, _h = 0;

  _LevelConfig get _level => _levelConfigs[_levelIdx];

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
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) { _triggerFail(); return false; }
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
      // Спавн частиц
      _spawnAccum += dt * 6;
      while (_spawnAccum >= 1) {
        _spawnAccum -= 1;
        _spawnParticle();
      }

      // Обновление
      for (final p in _particles) {
        _updateParticle(p, dt);
      }

      // Удаление улетевших
      _particles.removeWhere((p) => p.life <= 0 ||
          p.x < -0.1 || p.x > 1.1 || p.y < -0.1 || p.y > 1.1);

      // Проверка захвата
      final cupX = _level.cupCenter.dx * _w;
      final cupY = _level.cupCenter.dy * _h;
      final cupR = _level.cupRadius * min(_w, _h);

      _particles.removeWhere((p) {
        final dx = p.x * _w - cupX;
        final dy = p.y * _h - cupY;
        if (dx * dx + dy * dy < cupR * cupR) {
          _captured++;
          HapticFeedback.selectionClick();
          if (_captured >= _level.particlesNeeded) {
            _triggerWin();
          }
          return true;
        }
        return false;
      });
    });
  }

  void _spawnParticle() {
    final sx = _level.spawnPoint.dx + (_rng.nextDouble() - 0.5) * 0.06;
    final sy = _level.spawnPoint.dy;
    _particles.add(_Particle(
      x: sx, y: sy,
      vx: (_rng.nextDouble() - 0.5) * 0.05,
      vy: 0.02 + _rng.nextDouble() * 0.04,
      hue: 200 + _rng.nextDouble() * 120,
    ));
    if (_particles.length > 300) _particles.removeAt(0);
  }

  void _updateParticle(_Particle p, double dt) {
    // Гравитация к аттрактору
    if (_attractorPos != null) {
      final ax = _attractorPos!.dx / _w;
      final ay = _attractorPos!.dy / _h;
      final dx = ax - p.x;
      final dy = ay - p.y;
      final dist = sqrt(dx * dx + dy * dy).clamp(0.05, 1.0);
      final force = 0.8 / (dist * dist);
      p.vx += dx / dist * force * dt;
      p.vy += dy / dist * force * dt;
    }

    // Естественное падение
    p.vy += 0.15 * dt;

    // Стены — отталкивание
    for (final wall in _level.walls) {
      final wx1 = wall.left, wx2 = wall.right;
      final wy1 = wall.top, wy2 = wall.bottom;
      if (p.x > wx1 && p.x < wx2 && p.y > wy1 - 0.02 && p.y < wy2 + 0.02) {
        if (p.vy > 0 && p.y < wy1 + 0.02) p.vy = -p.vy.abs() * 0.5;
        else if (p.vy < 0 && p.y > wy2 - 0.02) p.vy = p.vy.abs() * 0.5;
        p.vx += (_rng.nextDouble() - 0.5) * 0.1;
      }
    }

    // Ограничение скорости
    final speed = sqrt(p.vx * p.vx + p.vy * p.vy);
    if (speed > 0.8) { p.vx *= 0.8 / speed; p.vy *= 0.8 / speed; }

    p.x += p.vx * dt;
    p.y += p.vy * dt;
    p.life -= dt * 0.15;
  }

  void _triggerWin() {
    if (_won) return;
    setState(() => _won = true);
    _tickCtrl.stop();
    HapticFeedback.heavyImpact();
    _winCtrl.forward();

    if (_levelIdx < _levelConfigs.length - 1) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _levelIdx++;
          _won = false;
          _captured = 0;
          _timeLeft = 45;
          _particles.clear();
        });
        _winCtrl.reset();
        _tickCtrl.forward(from: 0);
        _startTimer();
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
      backgroundColor: const Color(0xFF05001A),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(child: Stack(children: [
            GestureDetector(
              onPanStart:  (d) => setState(() => _attractorPos = d.localPosition),
              onPanUpdate: (d) => setState(() => _attractorPos = d.localPosition),
              onPanEnd:    (_) => setState(() => _attractorPos = null),
              onTapDown:   (d) => setState(() => _attractorPos = d.localPosition),
              onTapUp:     (_) => setState(() => _attractorPos = null),
              child: LayoutBuilder(builder: (ctx, cst) {
                _w = cst.maxWidth; _h = cst.maxHeight;
                return AnimatedBuilder(
                  animation: _tickCtrl,
                  builder: (_, __) => CustomPaint(
                    size: Size(_w, _h),
                    painter: _AlchemyPainter(
                      particles: List.from(_particles),
                      attractorPos: _attractorPos,
                      level: _level,
                      captured: _captured,
                      w: _w, h: _h,
                    ),
                  ),
                );
              }),
            ),
            if (_won && _levelIdx == _levelConfigs.length - 1)
              _buildWinOverlay(),
            if (_failed)
              _buildFailOverlay(),
          ])),
          _buildFooter(),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    final timeColor = _timeLeft > 20 ? const Color(0xFFBB00FF) : (_timeLeft > 8 ? Colors.orange : kRed);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      color: const Color(0xFF05001A),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6600CC), Color(0xFFFF6600)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: const Color(0xFFBB00FF).withOpacity(0.4), blurRadius: 10)],
          ),
          child: const Row(children: [
            Text('💫', style: TextStyle(fontSize: 13)),
            SizedBox(width: 5),
            Text('Алхимия частиц',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
        const Spacer(),
        Text('${_level.name}',
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(width: 10),
        // Прогресс
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFBB00FF).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBB00FF).withOpacity(0.4)),
          ),
          child: Text('$_captured / ${_level.particlesNeeded}',
              style: const TextStyle(color: Color(0xFFBB00FF), fontSize: 12, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      color: const Color(0xFF05001A),
      child: Text(
        _attractorPos != null
            ? '🌀 Аттрактор активен — тяни частицы к чаше'
            : '☝️ Удерживай палец на экране чтобы притягивать частицы',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.35)),
      ),
    );
  }

  Widget _buildWinOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: ScaleTransition(scale: _winScale, child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✨', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text('Поток отлажен!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Text('$_captured частиц собрано',
                style: const TextStyle(color: Color(0xFFBB00FF), fontSize: 14)),
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
            const Text('⏰', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text('Баг не исправлен!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Поймано: $_captured / ${_level.particlesNeeded}',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
          ],
        ))),
      ),
    );
  }
}

class _AlchemyPainter extends CustomPainter {
  final List<_Particle> particles;
  final Offset? attractorPos;
  final _LevelConfig level;
  final int captured;
  final double w, h;

  _AlchemyPainter({
    required this.particles, required this.attractorPos,
    required this.level, required this.captured,
    required this.w, required this.h,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawWalls(canvas);
    _drawSpawn(canvas);
    _drawCup(canvas);
    _drawParticles(canvas);
    if (attractorPos != null) _drawAttractor(canvas);
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFF05001A));

    // Туманность
    for (int i = 0; i < 3; i++) {
      final cx = w * (0.2 + i * 0.3);
      final cy = h * 0.5;
      canvas.drawCircle(Offset(cx, cy), w * 0.25,
          Paint()..shader = RadialGradient(
            colors: [
              const Color(0xFF6600CC).withOpacity(0.06),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.25)));
    }
  }

  void _drawWalls(Canvas canvas) {
    for (final wall in level.walls) {
      final rect = Rect.fromLTWH(wall.left * w, wall.top * h,
          (wall.right - wall.left) * w, (wall.bottom - wall.top) * h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = const Color(0xFF2E1A5A).withOpacity(0.8),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = const Color(0xFF6600CC).withOpacity(0.5)
          ..style = PaintingStyle.stroke..strokeWidth = 1.5,
      );
      // Свечение
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(3), const Radius.circular(6)),
        Paint()..color = const Color(0xFF6600CC).withOpacity(0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  void _drawSpawn(Canvas canvas) {
    final cx = level.spawnPoint.dx * w;
    final cy = level.spawnPoint.dy * h;
    canvas.drawCircle(Offset(cx, cy), 14,
        Paint()..color = const Color(0xFF00AAFF).withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(Offset(cx, cy), 6,
        Paint()..color = const Color(0xFF00AAFF).withOpacity(0.8));

    final tp = TextPainter(
      text: const TextSpan(text: '⬇', style: TextStyle(color: Color(0xFF00AAFF), fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy + 8));
  }

  void _drawCup(Canvas canvas) {
    final cx = level.cupCenter.dx * w;
    final cy = level.cupCenter.dy * h;
    final r = level.cupRadius * min(w, h);
    final progress = (captured / level.particlesNeeded).clamp(0.0, 1.0);

    // Чаша (внешнее кольцо)
    canvas.drawCircle(Offset(cx, cy), r + 8,
        Paint()..color = kGold.withOpacity(0.1 + 0.2 * progress)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = kGold.withOpacity(0.15));
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = kGold.withOpacity(0.6 + 0.4 * progress)
          ..style = PaintingStyle.stroke..strokeWidth = 2.5);

    // Заполнение
    if (progress > 0) {
      canvas.drawCircle(Offset(cx, cy), r * progress * 0.85,
          Paint()..color = kGold.withOpacity(0.3 * progress)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }

    final tp = TextPainter(
      text: const TextSpan(text: '🏆', style: TextStyle(fontSize: 18)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      final px = p.x * w;
      final py = p.y * h;
      final color = HSVColor.fromAHSV(1, p.hue % 360, 0.8, 1.0).toColor();

      canvas.drawCircle(Offset(px, py), 3,
          Paint()..color = color.withOpacity(p.life * 0.9)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawCircle(Offset(px, py), 1.5,
          Paint()..color = color.withOpacity(p.life));
    }
  }

  void _drawAttractor(Canvas canvas) {
    final pos = attractorPos!;
    final pulse = sin(DateTime.now().millisecondsSinceEpoch / 200.0) * 0.3 + 0.7;

    canvas.drawCircle(pos, 30 * pulse,
        Paint()..color = Colors.white.withOpacity(0.04 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    canvas.drawCircle(pos, 14,
        Paint()..color = Colors.black.withOpacity(0.6));
    canvas.drawCircle(pos, 14,
        Paint()..color = const Color(0xFFBB00FF).withOpacity(0.7 * pulse)
          ..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(pos, 4,
        Paint()..color = const Color(0xFFBB00FF).withOpacity(pulse));
  }

  @override
  bool shouldRepaint(_AlchemyPainter old) => true;
}
