// lib/game/shadow_escape_game.dart
//
// 👾 ПОБЕГ ТЕНИ — уклоняйся от препятствий!
// Персонаж бежит по трём дорожкам — свайпай влево/вправо чтобы переключаться.
// Выживи 30 секунд — и ты победил! Жизней: 3.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

enum _ShadowPhase { countdown, playing, success, fail }

class _Obstacle {
  int lane;
  double y;
  final double speed;
  final Color color;
  _Obstacle({required this.lane, required this.y, required this.speed, required this.color});
}

class ShadowEscapeGame extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const ShadowEscapeGame({super.key, required this.onSuccess, required this.onFail});

  @override
  State<ShadowEscapeGame> createState() => _ShadowEscapeGameState();
}

class _ShadowEscapeGameState extends State<ShadowEscapeGame>
    with TickerProviderStateMixin {
  // ─── Конфиг ─────────────────────────────────────────────────────────────
  static const int _laneCount = 3;
  static const double _playerY = 0.75; // относительно высоты
  static const double _playerSize = 40;
  static const double _obstacleSize = 38;
  static const int _surviveDuration = 30; // секунд

  // ─── Состояние ──────────────────────────────────────────────────────────
  int _lane = 1;           // 0, 1, 2
  int _targetLane = 1;
  double _laneTransition = 0;
  List<_Obstacle> _obstacles = [];
  int _lives = 3;
  int _timeLeft = _surviveDuration;
  int _countdown = 3;
  int _score = 0;
  double _baseSpeed = 0.004;
  _ShadowPhase _phase = _ShadowPhase.countdown;
  bool _isHit = false;

  // ─── Анимации ───────────────────────────────────────────────────────────
  late AnimationController _gameCtrl;
  late AnimationController _bgCtrl;
  late AnimationController _resultCtrl;
  late AnimationController _hitCtrl;
  late AnimationController _playerCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _resultScale;
  late Animation<double> _resultFade;
  late Animation<double> _hitFlash;
  late Animation<double> _playerBob;

  Timer? _countdownTimer;
  Timer? _spawnTimer;
  Timer? _scoreTimer;
  final _rng = Random();

  static const _obstacleColors = [
    Color(0xFFFF6B6B), Color(0xFF6A11CB), Color(0xFF2E86AB),
    Color(0xFFFF6B35), Color(0xFFFFD700),
  ];

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _gameCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 999));
    _gameCtrl.addListener(_gameTick);

    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _resultScale = Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.elasticOut));
    _resultFade  = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);

    _hitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _hitFlash = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _hitCtrl, curve: Curves.easeOut));

    _playerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _playerBob = Tween(begin: -4.0, end: 4.0).animate(CurvedAnimation(parent: _playerCtrl, curve: Curves.easeInOut));

    _startCountdown();
  }

  @override
  void dispose() {
    _gameCtrl.dispose();
    _bgCtrl.dispose();
    _resultCtrl.dispose();
    _hitCtrl.dispose();
    _playerCtrl.dispose();
    _countdownTimer?.cancel();
    _spawnTimer?.cancel();
    _scoreTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        setState(() => _phase = _ShadowPhase.playing);
        _gameCtrl.forward();
        _startSpawning();
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _scoreTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_phase != _ShadowPhase.playing) { t.cancel(); return; }
      setState(() {
        _timeLeft--;
        _score += 10;
        _baseSpeed = 0.004 + (_surviveDuration - _timeLeft) * 0.0003;
      });
      if (_timeLeft <= 0) {
        t.cancel();
        _win();
      }
    });
  }

  void _startSpawning() {
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 1100), (t) {
      if (_phase != _ShadowPhase.playing) { t.cancel(); return; }
      // Спавн 1-2 препятствий
      final lanes = [0, 1, 2]..shuffle(_rng);
      final count = _rng.nextBool() ? 1 : 2;
      for (int i = 0; i < count; i++) {
        _obstacles.add(_Obstacle(
          lane: lanes[i],
          y: -0.1,
          speed: _baseSpeed + _rng.nextDouble() * 0.002,
          color: _obstacleColors[_rng.nextInt(_obstacleColors.length)],
        ));
      }
    });
  }

  // ─── Тик ─────────────────────────────────────────────────────────────────
  void _gameTick() {
    if (_phase != _ShadowPhase.playing) return;
    setState(() {
      // Плавный переход дорожки
      if (_lane != _targetLane) {
        _laneTransition = (_laneTransition + 0.12).clamp(0, 1);
        if (_laneTransition >= 1) {
          _lane = _targetLane;
          _laneTransition = 0;
        }
      }

      // Двигаем препятствия
      _obstacles.removeWhere((o) => o.y > 1.2);
      for (final o in _obstacles) {
        o.y += o.speed;
      }

      // Проверяем коллизию
      if (!_isHit) _checkCollision();
    });
  }

  double _laneX(int lane, double fieldW) {
    return (lane + 0.5) / _laneCount;
  }

  double get _currentX {
    if (_lane == _targetLane) return (_lane + 0.5) / _laneCount;
    final start = (_lane + 0.5) / _laneCount;
    final end   = (_targetLane + 0.5) / _laneCount;
    return start + (end - start) * _laneTransition;
  }

  void _checkCollision() {
    for (final o in _obstacles) {
      final pX = _currentX;
      final oX = (_lane == _targetLane) ? (_targetLane + 0.5) / _laneCount : pX;
      // Только если о находится у игрока по Y
      if ((o.y - _playerY).abs() < 0.07) {
        // Близость по X (в дорожках)
        if (o.lane == _targetLane || ((_lane != _targetLane) && o.lane == _lane)) {
          _hit();
          break;
        }
      }
    }
  }

  void _hit() {
    _isHit = true;
    _lives--;
    HapticFeedback.heavyImpact();
    _hitCtrl.forward(from: 0).then((_) => _hitCtrl.reverse());

    if (_lives <= 0) {
      _fail();
    } else {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _isHit = false);
      });
    }
  }

  void _win() {
    _spawnTimer?.cancel();
    setState(() => _phase = _ShadowPhase.success);
    _resultCtrl.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), widget.onSuccess);
  }

  void _fail() {
    _spawnTimer?.cancel();
    _scoreTimer?.cancel();
    setState(() => _phase = _ShadowPhase.fail);
    _resultCtrl.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), widget.onFail);
  }

  void _swipe(int direction) {
    if (_phase != _ShadowPhase.playing) return;
    final newLane = (_targetLane + direction).clamp(0, _laneCount - 1);
    if (newLane != _targetLane) {
      HapticFeedback.selectionClick();
      setState(() { _targetLane = newLane; _laneTransition = 0; });
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        AnimatedBuilder(
          animation: _bgAnim,
          builder: (_, __) => CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ShadowBgPainter(_bgAnim.value),
          ),
        ),

        // Красная вспышка при ударе
        AnimatedBuilder(
          animation: _hitFlash,
          builder: (_, __) => IgnorePointer(
            child: Container(
              color: const Color(0xFFFF6B6B).withOpacity(_hitFlash.value * 0.25),
            ),
          ),
        ),

        SafeArea(child: Column(children: [
          _buildHeader(),
          Expanded(child: _buildGame()),
          _buildControls(),
          const SizedBox(height: 16),
        ])),

        // Обратный отсчёт
        if (_phase == _ShadowPhase.countdown)
          _buildCountdown(),

        // Результат
        if (_phase == _ShadowPhase.success || _phase == _ShadowPhase.fail)
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
              colors: [Color(0xFF6A11CB), Color(0xFFFF6B6B)]).createShader(b),
          child: const Text('ПОБЕГ ТЕНИ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: 1.5)),
        ),
        const Spacer(),
        // Жизни
        Row(children: [
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Icon(Icons.favorite_rounded, size: 18,
                color: i < _lives ? const Color(0xFFFF6B6B) : Colors.white12),
          )),
          const SizedBox(width: 8),
          // Таймер
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _timeLeft <= 5
                  ? const Color(0xFFFF6B6B).withOpacity(0.2)
                  : Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _timeLeft <= 5 ? const Color(0xFFFF6B6B).withOpacity(0.5) : Colors.white12),
            ),
            child: Text('$_timeLeft с',
                style: TextStyle(
                  color: _timeLeft <= 5 ? const Color(0xFFFF6B6B) : Colors.white70,
                  fontSize: 12, fontWeight: FontWeight.w800,
                )),
          ),
        ]),
      ]),
    );
  }

  Widget _buildGame() {
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity != null) {
          _swipe(d.primaryVelocity! < 0 ? -1 : 1);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(builder: (ctx, constraints) {
        final fw = constraints.maxWidth;
        final fh = constraints.maxHeight;
        final laneW = fw / _laneCount;

        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            // Дорожки
            CustomPaint(
              size: Size(fw - 24, fh),
              painter: _LanesPainter(_laneCount, _targetLane),
            ),

            // Препятствия
            ..._obstacles.map((o) {
              final x = (o.lane + 0.5) / _laneCount * (fw - 24) - _obstacleSize / 2;
              final y = o.y * fh - _obstacleSize / 2;
              return Positioned(
                left: x, top: y,
                child: Container(
                  width: _obstacleSize, height: _obstacleSize,
                  decoration: BoxDecoration(
                    color: o.color.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    boxShadow: [BoxShadow(color: o.color.withOpacity(0.5), blurRadius: 12)],
                  ),
                  child: const Center(child: Text('⚡', style: TextStyle(fontSize: 18))),
                ),
              );
            }).toList(),

            // Игрок
            AnimatedBuilder(
              animation: _playerBob,
              builder: (_, __) {
                final px = _currentX * (fw - 24) - _playerSize / 2;
                final py = _playerY * fh - _playerSize / 2 + _playerBob.value;

                return Positioned(
                  left: px, top: py,
                  child: AnimatedOpacity(
                    opacity: _isHit ? 0.3 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: _playerSize, height: _playerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: [Color(0xFF00D4AA), Color(0xFF2E86AB)]),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF00D4AA).withOpacity(0.6), blurRadius: 16),
                        ],
                      ),
                      child: const Center(child: Text('👾', style: TextStyle(fontSize: 20))),
                    ),
                  ),
                );
              },
            ),
          ]),
        );
      }),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _controlBtn(Icons.arrow_back_rounded, () => _swipe(-1)),
        Column(children: [
          const Icon(Icons.swipe_rounded, color: Colors.white30, size: 16),
          Text('Свайп или кнопки', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.3))),
        ]),
        _controlBtn(Icons.arrow_forward_rounded, () => _swipe(1)),
      ]),
    );
  }

  Widget _controlBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: Container(
        width: 54, height: 54,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Icon(icon, color: Colors.white60, size: 24),
      ),
    );
  }

  Widget _buildCountdown() {
    return Center(
      child: Container(
        width: 120, height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.8),
          border: Border.all(color: const Color(0xFF00D4AA), width: 3),
          boxShadow: [BoxShadow(color: const Color(0xFF00D4AA).withOpacity(0.4), blurRadius: 30)],
        ),
        child: Center(
          child: Text(
            _countdown > 0 ? '$_countdown' : 'GO!',
            style: const TextStyle(
              fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white,
              shadows: [Shadow(color: Color(0xFF00D4AA), blurRadius: 16)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultOverlay() {
    final isSuccess = _phase == _ShadowPhase.success;
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
                    color: isSuccess ? const Color(0xFF00D4AA) : const Color(0xFFFF6B6B),
                    width: 1.5,
                  ),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(isSuccess ? '🏃' : '💀', style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(
                    isSuccess ? 'ПОБЕГ\nУДАЛСЯ!' : 'ТЕНЬ\nПОЙМАНА',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900,
                      color: isSuccess ? const Color(0xFF00D4AA) : const Color(0xFFFF6B6B),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSuccess ? 'Выжил $_surviveDuration секунд!\nОчки: $_score' : 'Слишком много ударов',
                    textAlign: TextAlign.center,
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

// ─── Паинтеры ────────────────────────────────────────────────────────────────
class _LanesPainter extends CustomPainter {
  final int lanes;
  final int activeLane;
  _LanesPainter(this.lanes, this.activeLane);

  @override
  void paint(Canvas canvas, Size size) {
    final laneW = size.width / lanes;
    final divPaint = Paint()..color = Colors.white.withOpacity(0.07)..strokeWidth = 1;
    final activePaint = Paint()
      ..color = const Color(0xFF00D4AA).withOpacity(0.05);

    // Подсветка активной дорожки
    canvas.drawRect(
        Rect.fromLTWH(activeLane * laneW, 0, laneW, size.height), activePaint);

    // Разделители дорожек
    for (int i = 1; i < lanes; i++) {
      canvas.drawLine(Offset(i * laneW, 0), Offset(i * laneW, size.height), divPaint);
    }

    // Горизонтальные разметки
    final markPaint = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), markPaint);
    }
  }

  @override
  bool shouldRepaint(_LanesPainter old) => old.activeLane != activeLane;
}

class _ShadowBgPainter extends CustomPainter {
  final double t;
  _ShadowBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF06020E));

    final p = Paint();
    final blobs = [
      [0.2, 0.2, 200.0, const Color(0xFF6A11CB)],
      [0.8, 0.7, 180.0, const Color(0xFFFF3D71)],
    ];
    for (final b in blobs) {
      final x = (b[0] as double) * size.width;
      final y = (b[1] as double) * size.height;
      final r = (b[2] as double) + sin(t * pi * 2) * 20;
      final c = b[3] as Color;
      p.shader = RadialGradient(colors: [c.withOpacity(0.08), Colors.transparent])
          .createShader(Rect.fromCircle(center: Offset(x, y), radius: r));
      canvas.drawCircle(Offset(x, y), r, p);
    }
  }

  @override
  bool shouldRepaint(_ShadowBgPainter old) => old.t != t;
}
