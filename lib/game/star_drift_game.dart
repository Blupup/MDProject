// lib/game/star_drift_game.dart
//
// 🚀 ЗВЁЗДНЫЙ ДРИФТ — собирай звёзды на корабле!
// Управляй кораблём касанием: держи палец — летишь вверх, отпусти — вниз.
// Собери 10 звёзд и не врезайся в астероиды. Жизней: 3.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

enum _StarPhase { playing, success, fail }

class _FloatingObj {
  double x;     // 0..1
  double y;     // 0..1
  final double speed;
  final bool isStar;
  final Color color;
  double scale;
  bool collected;

  _FloatingObj({
    required this.x, required this.y, required this.speed,
    required this.isStar, required this.color,
    this.scale = 1.0, this.collected = false,
  });
}

class StarDriftGame extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const StarDriftGame({super.key, required this.onSuccess, required this.onFail});

  @override
  State<StarDriftGame> createState() => _StarDriftGameState();
}

class _StarDriftGameState extends State<StarDriftGame>
    with TickerProviderStateMixin {
  // ─── Конфиг ─────────────────────────────────────────────────────────────
  static const int _targetStars = 10;
  static const double _gravity = 0.0015;
  static const double _thrust  = 0.004;
  static const double _shipSize = 38;
  static const double _objSize  = 32;

  // ─── Состояние ──────────────────────────────────────────────────────────
  double _shipY = 0.5;
  double _velY  = 0.0;
  bool _pressing = false;
  List<_FloatingObj> _objects = [];
  int _starsCollected = 0;
  int _lives = 3;
  _StarPhase _phase = _StarPhase.playing;
  double _gameSpeed = 0.003;
  bool _isHit = false;
  double _shipTilt = 0;
  double _bgOffset = 0;
  int _frameCount = 0;

  // ─── Анимации ───────────────────────────────────────────────────────────
  late AnimationController _gameCtrl;
  late AnimationController _bgCtrl;
  late AnimationController _resultCtrl;
  late AnimationController _hitCtrl;
  late Animation<double> _resultScale;
  late Animation<double> _resultFade;
  late Animation<double> _hitFlash;

  final _rng = Random();

  static const _starColors = [
    Color(0xFFFFD700), Color(0xFF00D4AA), Color(0xFFFF6B35), Color(0xFFFF6B6B),
  ];

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 999))..forward();

    _gameCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 999));
    _gameCtrl.addListener(_tick);
    _gameCtrl.forward();

    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _resultScale = Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.elasticOut));
    _resultFade  = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);

    _hitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _hitFlash = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _hitCtrl, curve: Curves.easeOut));

    // Начальные объекты
    _spawnInitial();
  }

  void _spawnInitial() {
    for (int i = 0; i < 6; i++) {
      _objects.add(_makeObj(1.0 + i * 0.25));
    }
  }

  _FloatingObj _makeObj(double startX) {
    final isStar = _rng.nextDouble() > 0.4;
    return _FloatingObj(
      x: startX,
      y: 0.1 + _rng.nextDouble() * 0.8,
      speed: _gameSpeed + _rng.nextDouble() * 0.002,
      isStar: isStar,
      color: isStar ? _starColors[_rng.nextInt(_starColors.length)] : const Color(0xFF8B6914),
    );
  }

  @override
  void dispose() {
    _gameCtrl.dispose();
    _bgCtrl.dispose();
    _resultCtrl.dispose();
    _hitCtrl.dispose();
    super.dispose();
  }

  // ─── Тик ─────────────────────────────────────────────────────────────────
  void _tick() {
    if (_phase != _StarPhase.playing) return;
    setState(() {
      _frameCount++;
      _bgOffset += 0.5;

      // Физика корабля
      _velY += _pressing ? -_thrust : _gravity;
      _velY = _velY.clamp(-0.018, 0.018);
      _shipY = (_shipY + _velY).clamp(0.05, 0.95);
      _shipTilt = (_velY * -40).clamp(-30, 30);

      // Спавн новых объектов
      if (_frameCount % 60 == 0) {
        _objects.add(_makeObj(1.05));
        _gameSpeed = min(0.008, _gameSpeed + 0.0001);
      }

      // Двигаем объекты
      for (final o in _objects) {
        o.x -= o.speed;
        o.scale = o.collected ? max(0, o.scale - 0.15) : 1.0;
      }
      _objects.removeWhere((o) => o.x < -0.15 || (o.collected && o.scale <= 0));

      // Коллизии
      if (!_isHit) _checkCollisions();
    });
  }

  void _checkCollisions() {
    for (final o in _objects) {
      if (o.collected) continue;
      final dx = (o.x - 0.12).abs();
      final dy = (o.y - _shipY).abs();
      if (dx < 0.06 && dy < 0.06) {
        if (o.isStar) {
          o.collected = true;
          _starsCollected++;
          HapticFeedback.lightImpact();
          if (_starsCollected >= _targetStars) {
            _win();
          }
        } else {
          _lives--;
          _isHit = true;
          HapticFeedback.heavyImpact();
          _hitCtrl.forward(from: 0).then((_) => _hitCtrl.reverse());
          if (_lives <= 0) {
            _lose();
          } else {
            Future.delayed(const Duration(milliseconds: 700), () {
              if (mounted) setState(() => _isHit = false);
            });
          }
          break;
        }
      }
    }
  }

  void _win() {
    setState(() => _phase = _StarPhase.success);
    _resultCtrl.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), widget.onSuccess);
  }

  void _lose() {
    setState(() => _phase = _StarPhase.fail);
    _resultCtrl.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), widget.onFail);
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Фон — звёзды
        AnimatedBuilder(
          animation: _bgCtrl,
          builder: (_, __) => CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _SpaceBgPainter(_bgOffset),
          ),
        ),

        // Вспышка при ударе
        AnimatedBuilder(
          animation: _hitFlash,
          builder: (_, __) => IgnorePointer(
            child: Container(
                color: const Color(0xFFFF6B6B).withOpacity(_hitFlash.value * 0.3)),
          ),
        ),

        SafeArea(
          child: Column(children: [
            _buildHeader(),
            Expanded(child: _buildGameArea()),
            _buildHint(),
            const SizedBox(height: 20),
          ]),
        ),

        if (_phase != _StarPhase.playing)
          _buildResultOverlay(),
      ]),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFFF3D71), Color(0xFFFF6B35)]).createShader(b),
          child: const Text('ЗВЁЗДНЫЙ ДРИФТ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: 1.5)),
        ),
        const Spacer(),
        // Жизни
        Row(children: [
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Icon(Icons.favorite_rounded, size: 16,
                color: i < _lives ? const Color(0xFFFF6B6B) : Colors.white12),
          )),
          const SizedBox(width: 8),
          // Звёзды
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF8E53), Color(0xFFFFD700)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Text('⭐', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              Text('$_starsCollected/$_targetStars',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _buildGameArea() {
    return GestureDetector(
      onTapDown:  (_) { setState(() => _pressing = true);  HapticFeedback.selectionClick(); },
      onTapUp:    (_) { setState(() => _pressing = false); },
      onTapCancel:()  { setState(() => _pressing = false); },
      onPanStart: (_) { setState(() => _pressing = true);  },
      onPanEnd:   (_) { setState(() => _pressing = false); },
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(builder: (ctx, constraints) {
        final fw = constraints.maxWidth;
        final fh = constraints.maxHeight;

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            // Объекты
            ..._objects.map((o) {
              final x = o.x * fw - _objSize / 2;
              final y = o.y * fh - _objSize / 2;
              return Positioned(
                left: x, top: y,
                child: Transform.scale(
                  scale: o.scale,
                  child: Container(
                    width: _objSize, height: _objSize,
                    decoration: o.isStar ? BoxDecoration(
                      shape: BoxShape.circle,
                      color: o.color.withOpacity(0.15),
                      border: Border.all(color: o.color.withOpacity(0.8), width: 1.5),
                      boxShadow: [BoxShadow(color: o.color.withOpacity(0.4), blurRadius: 10)],
                    ) : BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: o.color.withOpacity(0.8),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(o.isStar ? '⭐' : '☄️',
                          style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              );
            }).toList(),

            // Корабль
            Positioned(
              left: 0.12 * fw - _shipSize / 2,
              top: _shipY * fh - _shipSize / 2,
              child: Transform.rotate(
                angle: _shipTilt * pi / 180,
                child: AnimatedOpacity(
                  opacity: _isHit ? 0.3 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    width: _shipSize, height: _shipSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _pressing
                            ? [const Color(0xFFFFD700), const Color(0xFFFF6B35)]
                            : [const Color(0xFF2E86AB), const Color(0xFF00D4AA)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_pressing ? const Color(0xFFFFD700) : const Color(0xFF00D4AA)).withOpacity(0.6),
                          blurRadius: _pressing ? 20 : 12,
                        ),
                      ],
                    ),
                    child: const Center(child: Text('🚀', style: TextStyle(fontSize: 20))),
                  ),
                ),
              ),
            ),

            // Тяга двигателя (частицы)
            if (_pressing)
              Positioned(
                left: 0.12 * fw - 30,
                top: _shipY * fh - 4,
                child: Container(
                  width: 24, height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [Colors.transparent, Color(0xFFFF6B35)],
                    ),
                  ),
                ),
              ),
          ]),
        );
      }),
    );
  }

  Widget _buildHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
          _pressing ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: _pressing ? const Color(0xFFFFD700) : Colors.white30,
          size: 14,
        ),
        const SizedBox(width: 8),
        Text(
          _pressing ? 'Тяга включена ↑' : 'Держи экран — лети вверх',
          style: TextStyle(
            fontSize: 12,
            color: _pressing ? const Color(0xFFFFD700) : Colors.white30,
            fontWeight: _pressing ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ]),
    );
  }

  Widget _buildResultOverlay() {
    final isSuccess = _phase == _StarPhase.success;
    return AnimatedBuilder(
      animation: _resultCtrl,
      builder: (_, __) => FadeTransition(
        opacity: _resultFade,
        child: Container(
          color: Colors.black.withOpacity(0.78),
          child: Center(
            child: ScaleTransition(
              scale: _resultScale,
              child: Container(
                margin: const EdgeInsets.all(40),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0F2D),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isSuccess ? const Color(0xFFFFD700) : const Color(0xFFFF6B6B),
                    width: 1.5,
                  ),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(isSuccess ? '🚀' : '💥', style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(
                    isSuccess ? 'МИССИЯ\nВЫПОЛНЕНА!' : 'КОРАБЛЬ\nУНИЧТОЖЕН',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900,
                      color: isSuccess ? const Color(0xFFFFD700) : const Color(0xFFFF6B6B),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSuccess
                        ? '$_starsCollected звёзд собрано! 🌟'
                        : 'Собрано: $_starsCollected из $_targetStars',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Фон — звёздное поле ─────────────────────────────────────────────────────
class _SpaceBgPainter extends CustomPainter {
  final double offset;
  static final _rng = Random(2024);
  static late List<_Star> _stars;
  static bool _initialized = false;

  _SpaceBgPainter(this.offset) {
    if (!_initialized) {
      _initialized = true;
      _stars = List.generate(120, (i) => _Star(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        r: 0.5 + _rng.nextDouble() * 1.5,
        speed: 0.1 + _rng.nextDouble() * 0.5,
        twinkleFreq: 0.3 + _rng.nextDouble() * 1.0,
        twinkleOffset: _rng.nextDouble() * 6.28,
      ));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF020B1A));

    // Туманность
    final nebula = Paint();
    nebula.shader = RadialGradient(
      colors: [const Color(0xFF0D1B4B).withOpacity(0.6), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.7, size.height * 0.3), radius: 200));
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.3), 200, nebula);

    nebula.shader = RadialGradient(
      colors: [const Color(0xFF1A0B3B).withOpacity(0.4), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.2, size.height * 0.7), radius: 160));
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.7), 160, nebula);

    // Звёзды
    for (final s in _stars) {
      final dx = (s.x * size.width - (offset * s.speed * 0.5) % size.width + size.width) % size.width;
      final twinkle = 0.2 + 0.8 * (0.5 + 0.5 * sin(offset * 0.03 * s.twinkleFreq + s.twinkleOffset));
      canvas.drawCircle(Offset(dx, s.y * size.height), s.r,
          Paint()..color = Colors.white.withOpacity(twinkle * 0.7));
    }
  }

  @override
  bool shouldRepaint(_SpaceBgPainter old) => old.offset != offset;
}

class _Star {
  final double x, y, r, speed, twinkleFreq, twinkleOffset;
  _Star({required this.x, required this.y, required this.r,
      required this.speed, required this.twinkleFreq, required this.twinkleOffset});
}
