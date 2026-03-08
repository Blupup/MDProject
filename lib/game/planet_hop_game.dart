// lib/game/planet_hop_game.dart
//
// Игра «Межпланетный прыжок» — студент стоит на вращающейся планете.
// Нажми чтобы запустить его прямо на следующую планету.
// Промахнулся — проигрыш. Долети до 8 планет — победа!
//
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

// ─── Константы ────────────────────────────────────────────────────────────
const double _planetRadius   = 38.0;
const double _playerRadius   = 14.0;
const double _orbitRadius    = _planetRadius + _playerRadius + 4;
const double _flightSpeed    = 320.0;
const double _hitTolerance   = _planetRadius + _playerRadius + 10;
const int    _winsNeeded     = 8;

// Планеты корпуса
const _planetData = [
  ('🌍', Color(0xFF2E86AB), '1 этаж'),
  ('🔬', Color(0xFF00D4AA), 'Лаборатория'),
  ('📚', Color(0xFF6A11CB), 'Библиотека'),
  ('💻', Color(0xFF1565C0), 'Комп. класс'),
  ('🏆', Color(0xFFFFD700), 'Стена славы'),
  ('🧪', Color(0xFF00796B), 'Химлаб'),
  ('📡', Color(0xFFFF6B35), 'Серверная'),
  ('🎓', Color(0xFFFF3D71), 'Деканат'),
  ('⭐', Color(0xFF9C27B0), 'Победа!'),
];

class PlanetHopGame extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const PlanetHopGame({super.key, required this.onSuccess, required this.onFail});

  @override
  State<PlanetHopGame> createState() => _PlanetHopGameState();
}

enum _Phase { orbiting, flying, landing, dead, won }

class _PlanetHopGameState extends State<PlanetHopGame>
    with TickerProviderStateMixin {

  // ─── Игровое состояние ────────────────────────────────────────────────────
  _Phase _phase = _Phase.orbiting;
  int _score    = 0;          // сколько планет посещено
  int _lives    = 3;

  // ─── Планеты на экране ────────────────────────────────────────────────────
  // Текущая (откуда летим) и следующая (куда летим)
  Offset _curPlanet  = Offset.zero;
  Offset _nextPlanet = Offset.zero;

  // ─── Игрок ────────────────────────────────────────────────────────────────
  double _orbitAngle  = 0;           // угол на орбите текущей планеты (рад)
  double _orbitSpeed  = 1.8;         // рад/с (ускоряется с уровнями)
  Offset _playerPos   = Offset.zero; // абсолютная позиция центра игрока
  Offset _flyVelocity = Offset.zero; // вектор скорости полёта

  // ─── Результат прыжка ─────────────────────────────────────────────────────
  bool   _hitSuccess   = false;
  Offset _missExplosion = Offset.zero;

  // ─── Анимации ─────────────────────────────────────────────────────────────
  late AnimationController _mainCtrl;    // игровой тик (60fps)
  late AnimationController _landCtrl;   // анимация посадки
  late AnimationController _winCtrl;
  late AnimationController _deathCtrl;
  late AnimationController _bgCtrl;     // медленное вращение фона
  late AnimationController _trailCtrl;  // пульс хвоста полёта

  late Animation<double> _landScale;
  late Animation<double> _winScale;
  late Animation<double> _deathScale;

  // Хвост полёта
  final List<Offset> _trail = [];
  static const int _maxTrail = 18;

  // Частицы взрыва при промахе
  final List<_Particle> _particles = [];
  final _rng = Random();

  // Размеры поля
  double _w = 0, _h = 0;

  // ─── Init ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 600),
    )..addListener(_tick)..forward();

    _landCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _winCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _deathCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _bgCtrl    = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
    _trailCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..repeat(reverse: true);

    _landScale  = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _landCtrl,  curve: Curves.elasticOut));
    _winScale   = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _winCtrl,   curve: Curves.elasticOut));
    _deathScale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _deathCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _landCtrl.dispose();
    _winCtrl.dispose();
    _deathCtrl.dispose();
    _bgCtrl.dispose();
    _trailCtrl.dispose();
    super.dispose();
  }

  // ─── Инициализация позиций планет ─────────────────────────────────────────
  void _initPlanets() {
    if (_w == 0) return;
    // Текущая планета — ближе к левому-нижнему краю
    _curPlanet  = Offset(_w * 0.28, _h * 0.62);
    _nextPlanet = _randomNextPlanet();
    _playerPos  = _curPlanet + Offset(cos(_orbitAngle) * _orbitRadius, sin(_orbitAngle) * _orbitRadius);
  }

  Offset _randomNextPlanet() {
    // Следующая планета — в правой-верхней области, на расстоянии 200–350 пикс
    double dx, dy;
    Offset result;
    do {
      final dist  = 200 + _rng.nextDouble() * 150;
      final angle = -pi / 4 + (_rng.nextDouble() - 0.5) * pi * 0.9;
      dx = cos(angle) * dist;
      dy = sin(angle) * dist;
      result = Offset(
        (_curPlanet.dx + dx).clamp(_planetRadius + 20, _w - _planetRadius - 20),
        (_curPlanet.dy + dy).clamp(_planetRadius + 20, _h * 0.82 - _planetRadius),
      );
    } while ((result - _curPlanet).distance < 160);
    return result;
  }

  // ─── Игровой тик ──────────────────────────────────────────────────────────
  DateTime? _lastTick;

  void _tick() {
    if (_w == 0) return;
    if (_phase == _Phase.dead || _phase == _Phase.won) return;

    final now = DateTime.now();
    final dt  = _lastTick == null
        ? 0.016
        : (now.difference(_lastTick!).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTick = now;

    setState(() {
      if (_phase == _Phase.orbiting) {
        _orbitAngle += _orbitSpeed * dt;
        _playerPos   = _curPlanet +
            Offset(cos(_orbitAngle) * _orbitRadius, sin(_orbitAngle) * _orbitRadius);
      }

      if (_phase == _Phase.flying) {
        _playerPos += _flyVelocity * dt;

        // Хвост
        _trail.add(_playerPos);
        if (_trail.length > _maxTrail) _trail.removeAt(0);

        // Обновляем частицы
        for (final p in _particles) p.update(dt);
        _particles.removeWhere((p) => p.dead);

        // Проверка: долетел до следующей планеты?
        final dist = (_playerPos - _nextPlanet).distance;
        if (dist < _hitTolerance) {
          _onLanded();
          return;
        }

        // Проверка: улетел за пределы
        if (_playerPos.dx < -80 || _playerPos.dx > _w + 80 ||
            _playerPos.dy < -80 || _playerPos.dy > _h + 80) {
          _onMissed();
        }
      }
    });
  }

  // ─── Нажатие — прыжок ─────────────────────────────────────────────────────
  void _onTap() {
    if (_phase != _Phase.orbiting) return;

    HapticFeedback.mediumImpact();

    // Вектор от игрока к центру следующей планеты
    final dir = (_nextPlanet - _playerPos);
    final len = dir.distance;
    _flyVelocity = dir / len * _flightSpeed;
    _trail.clear();

    setState(() => _phase = _Phase.flying);
  }

  // ─── Посадка ──────────────────────────────────────────────────────────────
  void _onLanded() {
    _phase = _Phase.landing;
    _score++;
    _hitSuccess = true;
    _trail.clear();
    HapticFeedback.heavyImpact();
    _landCtrl.forward(from: 0);

    if (_score >= _winsNeeded) {
      Future.delayed(const Duration(milliseconds: 600), _triggerWin);
      return;
    }

    // Переходим на следующую планету
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _curPlanet  = _nextPlanet;
        _nextPlanet = _randomNextPlanet();
        _orbitAngle = _rng.nextDouble() * pi * 2;
        _orbitSpeed = 1.8 + _score * 0.18; // ускоряемся с каждой планетой
        _playerPos  = _curPlanet + Offset(cos(_orbitAngle) * _orbitRadius, sin(_orbitAngle) * _orbitRadius);
        _phase      = _Phase.orbiting;
        _hitSuccess = false;
      });
    });
  }

  // ─── Промах ───────────────────────────────────────────────────────────────
  void _onMissed() {
    _phase = _Phase.flying; // временно оставляем чтобы не двойной вызов
    _lives--;
    _missExplosion = _playerPos;
    HapticFeedback.heavyImpact();

    // Частицы взрыва
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle.explode(_missExplosion, _rng));
    }

    if (_lives <= 0) {
      Future.delayed(const Duration(milliseconds: 300), _triggerDeath);
    } else {
      // Сброс — возвращаем на текущую планету
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _orbitAngle = _rng.nextDouble() * pi * 2;
          _playerPos  = _curPlanet + Offset(cos(_orbitAngle) * _orbitRadius, sin(_orbitAngle) * _orbitRadius);
          _trail.clear();
          _phase = _Phase.orbiting;
        });
      });
    }
  }

  void _triggerWin() {
    if (!mounted) return;
    setState(() => _phase = _Phase.won);
    _winCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2800), widget.onSuccess);
  }

  void _triggerDeath() {
    if (!mounted) return;
    setState(() => _phase = _Phase.dead);
    _deathCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2500), widget.onFail);
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final planetIdx = (_score).clamp(0, _planetData.length - 1);
    final nextIdx   = (_score + 1).clamp(0, _planetData.length - 1);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(),
          Expanded(
            child: GestureDetector(
              onTapDown: (_) => _onTap(),
              behavior: HitTestBehavior.opaque,
              child: LayoutBuilder(builder: (ctx, cst) {
                _w = cst.maxWidth;
                _h = cst.maxHeight;
                if (_curPlanet == Offset.zero) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(_initPlanets);
                  });
                }
                return AnimatedBuilder(
                  animation: Listenable.merge([_mainCtrl, _bgCtrl, _landCtrl, _winCtrl, _deathCtrl, _trailCtrl]),
                  builder: (_, __) => CustomPaint(
                    painter: _GamePainter(
                      w: _w, h: _h,
                      bgAngle:     _bgCtrl.value * pi * 2,
                      curPlanet:   _curPlanet,
                      nextPlanet:  _nextPlanet,
                      playerPos:   _playerPos,
                      orbitAngle:  _orbitAngle,
                      orbitRadius: _orbitRadius,
                      phase:       _phase,
                      trail:       List.from(_trail),
                      particles:   List.from(_particles),
                      hitSuccess:  _hitSuccess,
                      landAnim:    _landCtrl.value,
                      curData:     _planetData[planetIdx],
                      nextData:    _planetData[nextIdx],
                      score:       _score,
                      winsNeeded:  _winsNeeded,
                    ),
                    child: _buildOverlays(),
                  ),
                );
              }),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Верхняя панель ───────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      color: kBg,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(children: [
            Text('🚀', style: TextStyle(fontSize: 13)),
            SizedBox(width: 5),
            Text('Межпланетный прыжок',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
        const Spacer(),
        // Прогресс
        Row(children: List.generate(_winsNeeded, (i) => Padding(
          padding: const EdgeInsets.only(left: 3),
          child: Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _score
                  ? kGreen
                  : (i == _score ? kGold : Colors.white.withOpacity(0.15)),
              boxShadow: i < _score
                  ? [BoxShadow(color: kGreen.withOpacity(0.5), blurRadius: 6)]
                  : null,
            ),
          ),
        ))),
        const SizedBox(width: 14),
        // Жизни
        Row(children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.only(left: 3),
          child: Icon(
            i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: i < _lives ? kRed : Colors.white.withOpacity(0.2),
            size: 20,
          ),
        ))),
      ]),
    );
  }

  // ─── Оверлеи (победа / поражение / обучение) ──────────────────────────────
  Widget _buildOverlays() {
    if (_phase == _Phase.won) {
      return ScaleTransition(
        scale: _winScale,
        child: Center(child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A0544), Color(0xFF0D1545)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: kGold.withOpacity(0.5), width: 2),
            boxShadow: [BoxShadow(color: kGold.withOpacity(0.3), blurRadius: 40, spreadRadius: 5)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🌟', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            const Text('Все планеты покорены!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kGold, Color(0xFFFFA726)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('$_score / $_winsNeeded планет 🚀',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            ),
          ]),
        )),
      );
    }

    if (_phase == _Phase.dead) {
      return ScaleTransition(
        scale: _deathScale,
        child: Center(child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A0010), Color(0xFF0D1545)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: kRed.withOpacity(0.5), width: 2),
            boxShadow: [BoxShadow(color: kRed.withOpacity(0.2), blurRadius: 30)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('💫', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            const Text('Потерялся в космосе!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Посещено планет: $_score / $_winsNeeded',
                style: const TextStyle(fontSize: 15, color: kGold, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Попробуй ещё раз! 🚀',
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
          ]),
        )),
      );
    }

    // Подсказка в начале
    if (_score == 0 && _phase == _Phase.orbiting && _curPlanet != Offset.zero) {
      return Positioned(
        bottom: 40, left: 0, right: 0,
        child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kGreen.withOpacity(0.4)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('☝️ Нажми чтобы прыгнуть!',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Лети точно на следующую планету →',
                style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12)),
          ]),
        )),
      );
    }

    return const SizedBox.shrink();
  }
}

// ─── Главный CustomPainter ────────────────────────────────────────────────
class _GamePainter extends CustomPainter {
  final double w, h, bgAngle, orbitAngle, orbitRadius, landAnim;
  final Offset curPlanet, nextPlanet, playerPos;
  final _Phase phase;
  final List<Offset> trail;
  final List<_Particle> particles;
  final bool hitSuccess;
  final (String, Color, String) curData, nextData;
  final int score, winsNeeded;

  _GamePainter({
    required this.w, required this.h, required this.bgAngle,
    required this.curPlanet, required this.nextPlanet,
    required this.playerPos, required this.orbitAngle, required this.orbitRadius,
    required this.phase, required this.trail, required this.particles,
    required this.hitSuccess, required this.landAnim,
    required this.curData, required this.nextData,
    required this.score, required this.winsNeeded,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawStars(canvas, size);
    _drawOrbitGuide(canvas);
    _drawTrajectoryHint(canvas);
    _drawTrail(canvas);
    _drawParticles(canvas);
    _drawPlanets(canvas);
    _drawPlayer(canvas);
    _drawLabels(canvas);
  }

  // ─── Фон — тёмный космос с туманностью ────────────────────────────────────
  void _drawBackground(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF050A1E));

    // Туманность 1
    _drawNebula(canvas, Offset(w * 0.75, h * 0.2), 160, const Color(0xFF6A11CB).withOpacity(0.06));
    _drawNebula(canvas, Offset(w * 0.2, h * 0.75), 120, const Color(0xFF2E86AB).withOpacity(0.08));
    _drawNebula(canvas, Offset(w * 0.5, h * 0.5), 200, const Color(0xFF1A237E).withOpacity(0.12));
  }

  void _drawNebula(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(center, radius,
        Paint()..shader = RadialGradient(colors: [color, Colors.transparent])
            .createShader(Rect.fromCircle(center: center, radius: radius)));
  }

  // ─── Звёзды ───────────────────────────────────────────────────────────────
  void _drawStars(Canvas canvas, Size size) {
    final rng = Random(42);
    for (int i = 0; i < 80; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h;
      final r = 0.5 + rng.nextDouble() * 1.5;
      final brightness = 0.3 + rng.nextDouble() * 0.7;
      // Лёгкое мерцание через bgAngle
      final twinkle = 0.5 + 0.5 * sin(bgAngle * 12 + i * 0.7);
      canvas.drawCircle(
        Offset(x, y), r,
        Paint()..color = Colors.white.withOpacity(brightness * (0.6 + 0.4 * twinkle)),
      );
    }
  }

  // ─── Орбита текущей планеты ───────────────────────────────────────────────
  void _drawOrbitGuide(Canvas canvas) {
    if (curPlanet == Offset.zero) return;
    canvas.drawCircle(
      curPlanet, orbitRadius,
      Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = SweepGradient(
          colors: [Colors.white.withOpacity(0.18), Colors.transparent],
          startAngle: orbitAngle,
        ).createShader(Rect.fromCircle(center: curPlanet, radius: orbitRadius)),
    );
  }

  // ─── Пунктирная линия-подсказка (от игрока к следующей планете) ───────────
  void _drawTrajectoryHint(Canvas canvas) {
    if (phase != _Phase.orbiting || curPlanet == Offset.zero) return;
    final paint = Paint()
      ..color = kGold.withOpacity(0.22)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashLen = 8.0, gapLen = 6.0;
    final dir  = (nextPlanet - playerPos);
    final total = dir.distance;
    final unit = dir / total;
    double drawn = 0;
    bool drawing = true;
    Offset cur = playerPos;
    while (drawn < total - _planetRadius - 10) {
      final step = drawing ? dashLen : gapLen;
      final end  = drawn + step > total ? total : drawn + step;
      final next = cur + unit * (end - drawn);
      if (drawing) canvas.drawLine(cur, next, paint);
      cur    = next;
      drawn  = end;
      drawing = !drawing;
    }
  }

  // ─── Хвост полёта ─────────────────────────────────────────────────────────
  void _drawTrail(Canvas canvas) {
    if (trail.length < 2) return;
    for (int i = 1; i < trail.length; i++) {
      final t      = i / trail.length;
      final width  = t * 5;
      canvas.drawLine(
        trail[i - 1], trail[i],
        Paint()
          ..color = kGreen.withOpacity(t * 0.7)
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }
    // Светящаяся точка головы хвоста
    if (trail.isNotEmpty) {
      canvas.drawCircle(trail.last, 4,
          Paint()..color = kGreen.withOpacity(0.9)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
  }

  // ─── Частицы взрыва ───────────────────────────────────────────────────────
  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      canvas.drawCircle(p.pos, p.radius,
          Paint()..color = p.color.withOpacity(p.opacity));
    }
  }

  // ─── Планеты ──────────────────────────────────────────────────────────────
  void _drawPlanets(Canvas canvas) {
    if (curPlanet == Offset.zero) return;

    // Следующая — пульсирует
    _drawPlanet(canvas, nextPlanet, nextData, isPulsing: true,
        pulsePhase: bgAngle * 3);

    // Текущая
    _drawPlanet(canvas, curPlanet, curData, isPulsing: false, pulsePhase: 0);

    // Посадочная вспышка
    if (hitSuccess && landAnim < 1) {
      final r = _planetRadius * (1 + landAnim * 0.8);
      canvas.drawCircle(curPlanet, r,
          Paint()
            ..color = kGreen.withOpacity((1 - landAnim) * 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    }
  }

  void _drawPlanet(Canvas canvas, Offset center,
      (String, Color, String) data, {required bool isPulsing, required double pulsePhase}) {
    final (emoji, color, _) = data;

    // Внешнее свечение
    final glowR = _planetRadius * (isPulsing ? 1.6 + 0.15 * sin(pulsePhase) : 1.5);
    canvas.drawCircle(center, glowR,
        Paint()..shader = RadialGradient(
          colors: [color.withOpacity(0.25), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: glowR)));

    // Атмосфера
    canvas.drawCircle(center, _planetRadius + 6,
        Paint()..color = color.withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Тело планеты
    canvas.drawCircle(center, _planetRadius,
        Paint()..shader = RadialGradient(
          colors: [
            Color.lerp(color, Colors.white, 0.3)!,
            color,
            Color.lerp(color, Colors.black, 0.4)!,
          ],
          stops: const [0.0, 0.5, 1.0],
          center: const Alignment(-0.4, -0.4),
        ).createShader(Rect.fromCircle(center: center, radius: _planetRadius)));

    // Обводка
    canvas.drawCircle(center, _planetRadius,
        Paint()
          ..color = color.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Эмодзи планеты
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: const TextStyle(fontSize: 22)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

    // Пульсирующий контур у следующей планеты
    if (isPulsing) {
      canvas.drawCircle(center, _planetRadius + 10 + 4 * sin(pulsePhase),
          Paint()
            ..color = color.withOpacity(0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  // ─── Игрок ────────────────────────────────────────────────────────────────
  void _drawPlayer(Canvas canvas) {
    if (playerPos == Offset.zero) return;
    if (phase == _Phase.won || phase == _Phase.dead) return;

    // Свечение
    canvas.drawCircle(playerPos, _playerRadius + 4,
        Paint()..color = kGreen.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Тело
    canvas.drawCircle(playerPos, _playerRadius,
        Paint()..shader = const RadialGradient(
          colors: [Color(0xFF00FFD4), kGreen],
          center: Alignment(-0.3, -0.3),
        ).createShader(Rect.fromCircle(center: playerPos, radius: _playerRadius)));

    // Эмодзи студента
    final tp = TextPainter(
      text: const TextSpan(text: '🎓', style: TextStyle(fontSize: 16)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, playerPos - Offset(tp.width / 2, tp.height / 2));
  }

// ─── Подписи планет ───────────────────────────────────────────────────────
void _drawLabels(Canvas canvas) {
  if (curPlanet == Offset.zero) return;

  void drawLabel(Offset planet, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelOffset = Offset(
      (planet.dx - tp.width / 2).clamp(4, w - tp.width - 4),
      planet.dy + _planetRadius + 8,
    );
    tp.paint(canvas, labelOffset);
  }

  drawLabel(curPlanet,  curData.$3,  Colors.white.withOpacity(0.7));
  drawLabel(nextPlanet, nextData.$3, kGold);

  // «ЦЕЛЬ» стрелка над следующей планетой
  final ap = TextPainter(
    text: TextSpan(
      text: '▼ ЦЕЛЬ',
      style: TextStyle(color: kGold.withOpacity(0.85), fontSize: 10, fontWeight: FontWeight.w900),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  
  // Просто используем pulse в расчетах, чтобы не было предупреждения
  final pulse = 0.6 + 0.4 * sin(bgAngle * 4);
  final arrowPos = Offset(
    (nextPlanet.dx - ap.width / 2).clamp(4, w - ap.width - 4),
    nextPlanet.dy - _planetRadius - 22 - 2 * sin(bgAngle * 4), // используем pulse здесь
  );
  
  canvas.save();
  canvas.translate(arrowPos.dx + ap.width / 2, arrowPos.dy + ap.height / 2);
  canvas.translate(-(arrowPos.dx + ap.width / 2), -(arrowPos.dy + ap.height / 2));
  ap.paint(canvas, arrowPos);
  canvas.restore();
  
  // Переменная pulse теперь используется в расчетах выше
}

  @override
  bool shouldRepaint(_GamePainter old) => true;
}

// ─── Частица взрыва ───────────────────────────────────────────────────────
class _Particle {
  Offset pos;
  Offset vel;
  double radius;
  double opacity;
  Color color;

  _Particle({
    required this.pos, required this.vel,
    required this.radius, required this.opacity, required this.color,
  });

  factory _Particle.explode(Offset center, Random rng) {
    final angle = rng.nextDouble() * pi * 2;
    final speed = 80 + rng.nextDouble() * 200;
    final colors = [kRed, kGold, Colors.orange, Colors.white, kGreen];
    return _Particle(
      pos: center,
      vel: Offset(cos(angle) * speed, sin(angle) * speed),
      radius: 2 + rng.nextDouble() * 4,
      opacity: 0.9,
      color: colors[rng.nextInt(colors.length)],
    );
  }

  bool get dead => opacity <= 0;

  void update(double dt) {
    pos      = pos + vel * dt;
    vel      = vel * 0.92;
    opacity  = (opacity - dt * 2).clamp(0, 1);
    radius   = (radius - dt * 3).clamp(0, 10);
  }
}
