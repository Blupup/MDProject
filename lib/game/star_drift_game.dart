// lib/game/star_drift_game.dart
//
// 🚀 ЗВЁЗДНЫЙ ШТУРМ — прорвись через вражеский строй!
// Корабль летит вперёд и стреляет автоматически.
// Управляй вертикально, уничтожай врагов и дойди до конца маршрута.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

enum _StarPhase { playing, success, fail }

class _Enemy {
  double x;
  double y;
  double drift;
  final double speed;
  int hp;
  int damageTicks;

  _Enemy({
    required this.x,
    required this.y,
    required this.drift,
    required this.speed,
    this.hp = 2,
    this.damageTicks = 0,
  });
}

class _Bullet {
  double x;
  double y;
  final double speed;

  _Bullet({required this.x, required this.y, required this.speed});
}

class _EnemyBullet {
  double x;
  double y;
  final double speed;

  _EnemyBullet({required this.x, required this.y, required this.speed});
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
  static const int _distanceTarget = 140;
  static const int _targetKills = 44;
  static const double _shipSize = 54;
  static const double _enemySize = 46;
  static const double _bulletSize = 10;

  // ─── Состояние ──────────────────────────────────────────────────────────
  double _shipY = 0.5;
  bool _dragging = false;
  int _distance = 0;
  int _kills = 0;
  List<_Enemy> _enemies = [];
  List<_Bullet> _bullets = [];
  List<_EnemyBullet> _enemyBullets = [];
  int _lives = 2;
  _StarPhase _phase = _StarPhase.playing;
  bool _isHit = false;
  double _shipTilt = 0.0;
  double _bgOffset = 0;
  int _frameCount = 0;
  int _shotCooldown = 0;
  int _enemyShotCooldown = 0;

  double get _pathProgress => (_distance / _distanceTarget).clamp(0.0, 1.0);
  int get _pathPercent => (_pathProgress * 100).round();

  // ─── Анимации ───────────────────────────────────────────────────────────
  late AnimationController _gameCtrl;
  late AnimationController _bgCtrl;
  late AnimationController _resultCtrl;
  late AnimationController _hitCtrl;
  late Animation<double> _resultScale;
  late Animation<double> _resultFade;
  late Animation<double> _hitFlash;

  final _rng = Random();

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

    _spawnInitialEnemies();
  }

  void _spawnInitialEnemies() {
    for (int i = 0; i < 5; i++) {
      _enemies.add(_makeEnemy(1.0 + i * 0.28));
    }
  }

  _Enemy _makeEnemy(double startX) {
    return _Enemy(
      x: startX,
      y: 0.12 + _rng.nextDouble() * 0.76,
      drift: (_rng.nextDouble() - 0.5) * 0.0028,
      speed: 0.0053 + _rng.nextDouble() * 0.0024,
      hp: _rng.nextDouble() > 0.72 ? 3 : 2,
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

      if (_frameCount % 12 == 0) {
        _distance = min(_distanceTarget, _distance + 1);
      }

      // Авто-стрельба
      if (_shotCooldown <= 0) {
        _bullets.add(_Bullet(x: 0.17, y: _shipY, speed: 0.012));
        _shotCooldown = 10;
      } else {
        _shotCooldown--;
      }

      // Спавн врагов
      if (_frameCount % 20 == 0 && _enemies.length < 12) {
        _enemies.add(_makeEnemy(1.06));
      }

      // Вражеская стрельба
      if (_enemyShotCooldown <= 0 && _enemies.isNotEmpty) {
        final shooter = _enemies[_rng.nextInt(_enemies.length)];
        _enemyBullets.add(
          _EnemyBullet(
            x: shooter.x - 0.03,
            y: shooter.y,
            speed: 0.0085 + (_distance / _distanceTarget) * 0.004,
          ),
        );
        _enemyShotCooldown = max(12, 34 - (_distance ~/ 8));
      } else {
        _enemyShotCooldown--;
      }

      // Движение врагов/снарядов
      for (final e in _enemies) {
        e.x -= e.speed + (_distance / _distanceTarget) * 0.0022;
        e.y = (e.y + e.drift).clamp(0.08, 0.92);
        if (e.y <= 0.09 || e.y >= 0.91) e.drift *= -1;
        if (e.damageTicks > 0) e.damageTicks--;
      }
      for (final b in _bullets) {
        b.x += b.speed;
      }
      for (final b in _enemyBullets) {
        b.x -= b.speed;
      }
      _bullets.removeWhere((b) => b.x > 1.2);
      _enemyBullets.removeWhere((b) => b.x < -0.15);
      _enemies.removeWhere((e) => e.x < -0.15);

      // Коллизии
      _checkBulletHits();
      if (!_isHit) {
        _checkShipHits();
        _checkEnemyBulletHits();
      }

      if (_distance >= _distanceTarget) {
        _win();
      }
    });
  }

  void _checkBulletHits() {
    final bulletsToRemove = <_Bullet>{};
    for (final b in _bullets) {
      for (final e in _enemies) {
        final dx = (b.x - e.x).abs();
        final dy = (b.y - e.y).abs();
        if (dx < 0.04 && dy < 0.05) {
          bulletsToRemove.add(b);
          e.damageTicks = 4;
          e.hp--;
          if (e.hp <= 0) {
            _kills++;
            HapticFeedback.mediumImpact();
          } else {
            HapticFeedback.selectionClick();
          }
          break;
        }
      }
    }
    _bullets.removeWhere(bulletsToRemove.contains);
    _enemies.removeWhere((e) => e.hp <= 0);
  }

  void _checkShipHits() {
    for (final e in _enemies) {
      final dx = (e.x - 0.12).abs();
      final dy = (e.y - _shipY).abs();
      if (dx < 0.065 && dy < 0.07) {
        _lives--;
        _isHit = true;
        HapticFeedback.heavyImpact();
        _hitCtrl.forward(from: 0).then((_) => _hitCtrl.reverse());
        if (_lives <= 0) {
          _lose();
        } else {
          Future.delayed(const Duration(milliseconds: 650), () {
            if (mounted) setState(() => _isHit = false);
          });
        }
        break;
      }
    }
  }

  void _checkEnemyBulletHits() {
    final bulletsToRemove = <_EnemyBullet>{};
    for (final b in _enemyBullets) {
      final dx = (b.x - 0.12).abs();
      final dy = (b.y - _shipY).abs();
      if (dx < 0.05 && dy < 0.06) {
        bulletsToRemove.add(b);
        _lives--;
        _isHit = true;
        HapticFeedback.heavyImpact();
        _hitCtrl.forward(from: 0).then((_) => _hitCtrl.reverse());
        if (_lives <= 0) {
          _lose();
        } else {
          Future.delayed(const Duration(milliseconds: 520), () {
            if (mounted) setState(() => _isHit = false);
          });
        }
      }
    }
    _enemyBullets.removeWhere(bulletsToRemove.contains);
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
      child: Column(
        children: [
          Row(children: [
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
                  colors: [Color(0xFFFF5C4D), Color(0xFFFFA14D)]).createShader(b),
              child: const Text('ЗВЁЗДНЫЙ ШТУРМ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: 1.5)),
            ),
            const Spacer(),
            Row(children: [
              ...List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Icon(Icons.favorite_rounded, size: 16,
                    color: i < _lives ? const Color(0xFFFF6B6B) : Colors.white12),
              )),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0891B2), Color(0xFF22D3EE)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Text('🎯', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Text('$_kills/$_targetKills',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Путь: $_pathPercent%',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ]),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _pathProgress,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return GestureDetector(
      onPanStart: (_) => setState(() => _dragging = true),
      onPanEnd: (_) => setState(() => _dragging = false),
      onPanCancel: () => setState(() => _dragging = false),
      onPanUpdate: (d) {
        setState(() {
          final h = MediaQuery.of(context).size.height;
          final delta = d.delta.dy / h;
          _shipY = (_shipY + delta).clamp(0.08, 0.92);
          _shipTilt = (d.delta.dy * 0.9).clamp(-16, 16);
        });
      },
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
            // Враги
            ..._enemies.map((e) {
              final x = e.x * fw - _enemySize / 2;
              final y = e.y * fh - _enemySize / 2;
              return Positioned(
                left: x, top: y,
                child: Transform.scale(
                  scale: e.damageTicks > 0 ? 0.9 : 1.0,
                  child: SizedBox(
                    width: _enemySize,
                    height: _enemySize,
                    child: CustomPaint(painter: _EnemyShipPainter(hit: e.damageTicks > 0)),
                  ),
                ),
              );
            }).toList(),

            // Пули
            ..._bullets.map((b) {
              return Positioned(
                left: b.x * fw - _bulletSize / 2,
                top: b.y * fh - _bulletSize / 2,
                child: Container(
                  width: _bulletSize,
                  height: _bulletSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF1A8), Color(0xFFFF6B35)],
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFFFF8A3D), blurRadius: 10),
                    ],
                  ),
                ),
              );
            }).toList(),

            // Вражеские пули
            ..._enemyBullets.map((b) {
              return Positioned(
                left: b.x * fw - 5,
                top: b.y * fh - 5,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFCA5A5), Color(0xFFEF4444)],
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFFEF4444), blurRadius: 8),
                    ],
                  ),
                ),
              );
            }).toList(),

            // Корабль
            Positioned(
              left: 0.12 * fw - _shipSize / 2,
              top: _shipY * fh - _shipSize / 2,
              child: Transform.rotate(
                angle: (pi / 2) + (_shipTilt * pi / 180),
                child: AnimatedOpacity(
                  opacity: _isHit ? 0.3 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: SizedBox(
                    width: _shipSize, height: _shipSize,
                    child: CustomPaint(painter: _PlayerShipPainter(enginesOn: true)),
                  ),
                ),
              ),
            ),

            // Пламя двигателя
            Positioned(
              left: 0.12 * fw - 34,
              top: _shipY * fh - 6,
              child: Container(
                width: 30, height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Colors.transparent, Color(0xFF60A5FA), Color(0xFF22D3EE)],
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
        const Icon(Icons.swipe_up_alt_rounded, color: Colors.white54, size: 15),
        const SizedBox(width: 8),
        Text(
          _dragging ? 'Веди пальцем по экрану: уклоняйся и расчищай путь' : 'Тяни вверх/вниз, корабль стреляет автоматически',
          style: TextStyle(
            fontSize: 12,
            color: _dragging ? const Color(0xFF67E8F9) : Colors.white38,
            fontWeight: _dragging ? FontWeight.w700 : FontWeight.w400,
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
                        ? 'Маршрут пройден: $_pathPercent%, целей сбито: $_kills'
                        : 'Путь: $_pathPercent%, целей сбито: $_kills',
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

class _PlayerShipPainter extends CustomPainter {
  final bool enginesOn;
  _PlayerShipPainter({required this.enginesOn});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    final px = size.width / 16;
    void block(int gx, int gy, Color c, [int w = 1, int h = 1]) {
      p.color = c;
      canvas.drawRect(Rect.fromLTWH(gx * px, gy * px, w * px, h * px), p);
    }

    const blue = Color(0xFF3F51B5);
    const blueDark = Color(0xFF2C3E9D);
    const steel = Color(0xFF9AA0A6);
    const cyan = Color(0xFF40E0E0);
    const cyanDark = Color(0xFF0F9D9A);
    const black = Color(0xFF000000);

    // Нос
    block(7, 0, cyan, 2, 1);
    block(7, 1, blue, 2, 2);
    block(6, 3, blue, 1, 2);
    block(9, 3, blue, 1, 2);
    block(7, 3, steel, 2, 3);
    block(7, 5, cyan, 1, 2);
    block(8, 5, cyan, 1, 2);

    // Центральный корпус
    block(5, 5, blue, 1, 2);
    block(10, 5, blue, 1, 2);
    block(6, 7, blue, 1, 2);
    block(9, 7, blue, 1, 2);
    block(5, 9, blue, 1, 2);
    block(10, 9, blue, 1, 2);
    block(6, 9, steel, 4, 5);

    // Кабина
    block(6, 10, black, 4, 4);
    block(7, 10, const Color(0xFF7BB7EA), 2, 1);
    block(7, 11, const Color(0xFF7BB7EA), 2, 2);
    block(7, 11, cyanDark, 2, 1);
    block(7, 12, cyan, 2, 2);

    // Крылья
    block(4, 12, blue, 1, 3);
    block(11, 12, blue, 1, 3);
    block(3, 13, blue, 1, 2);
    block(12, 13, blue, 1, 2);
    block(2, 14, blueDark, 1, 2);
    block(13, 14, blueDark, 1, 2);
    block(3, 12, steel, 1, 2);
    block(12, 12, steel, 1, 2);
    block(3, 13, cyan, 1, 1);
    block(12, 13, cyan, 1, 1);
    block(2, 15, black, 1, 1);
    block(13, 15, black, 1, 1);

    if (enginesOn) {
      block(7, 14, const Color(0xFF3B82F6), 2, 1);
      block(7, 15, const Color(0xFFFF8A00), 2, 1);
    }
  }

  @override
  bool shouldRepaint(_PlayerShipPainter old) => old.enginesOn != enginesOn;
}

class _EnemyShipPainter extends CustomPainter {
  final bool hit;
  _EnemyShipPainter({required this.hit});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    final px = size.width / 14;
    final c1 = hit ? const Color(0xFFF97316) : const Color(0xFF34D399);
    final c2 = hit ? const Color(0xFF9A3412) : const Color(0xFF047857);
    void block(int gx, int gy, Color c, [int w = 1, int h = 1]) {
      p.color = c;
      canvas.drawRect(Rect.fromLTWH(gx * px, gy * px, w * px, h * px), p);
    }

    block(6, 1, c1, 2, 1);
    block(5, 2, c2, 4, 2);
    block(4, 4, c2, 6, 2);
    block(3, 5, c1, 2, 2);
    block(9, 5, c1, 2, 2);
    block(5, 6, c2, 4, 3);
    block(6, 7, const Color(0xFFFDE047), 2, 1);
    block(6, 9, c1, 2, 1);
  }

  @override
  bool shouldRepaint(_EnemyShipPainter old) => old.hit != hit;
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
