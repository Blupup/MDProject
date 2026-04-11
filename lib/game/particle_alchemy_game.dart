// lib/game/particle_alchemy_game.dart
//
// 💫 АЛХИМИЯ ЧАСТИЦ — соедини частицы правильными парами!
// На поле летают частицы с символами — тяни от одной к другой,
// чтобы создать элемент. Найди 5 правильных пар чтобы победить.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

// ─── Данные элементов ────────────────────────────────────────────────────────
class _Element {
  final String a, b;
  final String result;
  final String emoji;
  final Color color;
  const _Element(this.a, this.b, this.result, this.emoji, this.color);
}

const _kElements = [
  _Element('🔥', '💧', 'Пар',     '☁️', Color(0xFF00D4AA)),
  _Element('🌍', '🔥', 'Магма',   '🌋', Color(0xFFFF6B35)),
  _Element('💧', '🌍', 'Болото',  '🌿', Color(0xFF4CAF50)),
  _Element('🌬️', '💧', 'Шторм',  '⛈️', Color(0xFF2E86AB)),
  _Element('🌬️', '🔥', 'Молния', '⚡', Color(0xFFFFD700)),
];

class _Particle {
  Offset pos;
  Offset vel;
  final String symbol;
  final int idx;
  double phase; // для анимации дыхания

  _Particle({required this.pos, required this.vel, required this.symbol, required this.idx, required this.phase});
}

enum _AlchemyPhase { playing, success, fail }

class ParticleAlchemyGame extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const ParticleAlchemyGame({super.key, required this.onSuccess, required this.onFail});

  @override
  State<ParticleAlchemyGame> createState() => _ParticleAlchemyGameState();
}

class _ParticleAlchemyGameState extends State<ParticleAlchemyGame>
    with TickerProviderStateMixin {
  final _rng = Random();
  List<_Particle> _particles = [];
  int? _draggingIdx;
  Offset? _dragPos;
  int? _hoveredIdx;

  List<String> _discovered = [];
  List<_Element> _remaining = List.from(_kElements);
  String? _lastResult;
  bool _showResult = false;
  _AlchemyPhase _phase = _AlchemyPhase.playing;
  int _tries = 0;
  static const int _maxTries = 15;

  late AnimationController _animCtrl;
  late AnimationController _bgCtrl;
  late AnimationController _resultCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _resultScale;
  late Animation<double> _resultFade;
  late AnimationController _flashCtrl;
  late Animation<double> _flashAnim;

  static const _symbols = ['🔥', '💧', '🌍', '🌬️'];

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _animCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 999));
    _animCtrl.addListener(_tick);
    _animCtrl.forward();

    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _resultScale = Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.elasticOut));
    _resultFade  = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);

    _flashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _flashAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut));

    // Инициализируем частицы после первого layout
    WidgetsBinding.instance.addPostFrameCallback((_) => _spawnParticles());
  }

  void _spawnParticles() {
    final size = MediaQuery.of(context).size;
    final fw = size.width;
    final fh = size.height * 0.55;

    _particles = List.generate(8, (i) {
      final sym = _symbols[i % _symbols.length];
      return _Particle(
        pos: Offset(80 + _rng.nextDouble() * (fw - 160), 80 + _rng.nextDouble() * (fh - 160)),
        vel: Offset((_rng.nextDouble() - 0.5) * 1.2, (_rng.nextDouble() - 0.5) * 1.2),
        symbol: sym,
        idx: i,
        phase: _rng.nextDouble() * 2 * pi,
      );
    });
    setState(() {});
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _bgCtrl.dispose();
    _resultCtrl.dispose();
    _flashCtrl.dispose();
    super.dispose();
  }

  void _tick() {
    if (_phase != _AlchemyPhase.playing) return;
    final size = MediaQuery.of(context).size;
    final fw = size.width;
    final fh = size.height * 0.55;

    setState(() {
      for (final p in _particles) {
        if (p.idx == _draggingIdx) continue;
        p.phase += 0.03;
        p.pos += p.vel;

        // Отбой от стен
        if (p.pos.dx < 30 || p.pos.dx > fw - 30) p.vel = Offset(-p.vel.dx, p.vel.dy);
        if (p.pos.dy < 30 || p.pos.dy > fh - 30) p.vel = Offset(p.vel.dx, -p.vel.dy);
        p.pos = Offset(p.pos.dx.clamp(30, fw - 30), p.pos.dy.clamp(30, fh - 30));
      }
    });
  }

  // ─── Попытка слияния ─────────────────────────────────────────────────────
  void _tryMerge(int fromIdx, int toIdx) {
    if (fromIdx == toIdx) return;
    final a = _particles[fromIdx].symbol;
    final b = _particles[toIdx].symbol;
    if (a == b) return;

    _tries++;
    if (_tries >= _maxTries && _remaining.isNotEmpty) {
      _showFail();
      return;
    }

    final match = _kElements.where((e) =>
      (e.a == a && e.b == b) || (e.a == b && e.b == a)).firstOrNull;

    if (match != null && _remaining.contains(match)) {
      HapticFeedback.mediumImpact();
      _remaining.remove(match);
      _discovered.add(match.result);
      _lastResult = '${match.emoji} ${match.result} создан!';
      _showResult = true;
      _flashCtrl.forward(from: 0);
      setState(() {});

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() => _showResult = false);
        if (_remaining.isEmpty) _showSuccess();
      });
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _showSuccess() {
    setState(() => _phase = _AlchemyPhase.success);
    _resultCtrl.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), widget.onSuccess);
  }

  void _showFail() {
    setState(() => _phase = _AlchemyPhase.fail);
    _resultCtrl.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), widget.onFail);
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
            painter: _AlchemyBgPainter(_bgAnim.value),
          ),
        ),

        SafeArea(
          child: Column(children: [
            _buildHeader(),
            _buildStats(),
            const SizedBox(height: 8),
            Expanded(child: _buildField()),
            _buildRecipes(),
            const SizedBox(height: 20),
          ]),
        ),

        if (_showResult)
          _buildResultFlash(),

        if (_phase != _AlchemyPhase.playing)
          _buildEndOverlay(),
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
              colors: [Color(0xFFFF6B35), Color(0xFFFFD700)]).createShader(b),
          child: const Text('АЛХИМИЯ ЧАСТИЦ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: 1.5)),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFFD700)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('${_discovered.length}/${_kElements.length}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(children: [
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: _discovered.length / _kElements.length,
            minHeight: 4,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
          ),
        )),
        const SizedBox(width: 12),
        Text('Попыток: $_tries/$_maxTries',
            style: TextStyle(
                color: _tries > _maxTries * 0.7 ? const Color(0xFFFF6B6B) : Colors.white54,
                fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildField() {
    return LayoutBuilder(builder: (ctx, constraints) {
      return GestureDetector(
        onPanStart: (d) {
          final idx = _hitTest(d.localPosition);
          if (idx != null) {
            setState(() { _draggingIdx = idx; _dragPos = d.localPosition; });
          }
        },
        onPanUpdate: (d) {
          if (_draggingIdx == null) return;
          setState(() {
            _dragPos = d.localPosition;
            _particles[_draggingIdx!].pos = d.localPosition;
            // Проверяем hover
            _hoveredIdx = null;
            for (int i = 0; i < _particles.length; i++) {
              if (i == _draggingIdx) continue;
              if ((_particles[i].pos - d.localPosition).distance < 50) {
                _hoveredIdx = i;
              }
            }
          });
        },
        onPanEnd: (_) {
          if (_draggingIdx != null && _hoveredIdx != null) {
            _tryMerge(_draggingIdx!, _hoveredIdx!);
          }
          setState(() { _draggingIdx = null; _hoveredIdx = null; _dragPos = null; });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            // Линия перетаскивания
            if (_draggingIdx != null && _dragPos != null)
              CustomPaint(
                size: Size(constraints.maxWidth - 32, constraints.maxHeight),
                painter: _LinePainter(
                  from: _particles[_draggingIdx!].pos,
                  to: _dragPos!,
                  color: const Color(0xFFFFD700),
                ),
              ),

            // Частицы
            ..._particles.map((p) {
              final isHovered = _hoveredIdx == p.idx;
              final isDragging = _draggingIdx == p.idx;
              final breathe = sin(p.phase) * 0.08;

              return Positioned(
                left: p.pos.dx - 28,
                top: p.pos.dy - 28,
                child: Transform.scale(
                  scale: (isDragging ? 1.2 : isHovered ? 1.15 : 1.0) + breathe,
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDragging || isHovered)
                          ? const Color(0xFFFFD700).withOpacity(0.2)
                          : Colors.black.withOpacity(0.5),
                      border: Border.all(
                        color: isDragging
                            ? const Color(0xFFFFD700)
                            : isHovered
                                ? const Color(0xFF00D4AA)
                                : Colors.white.withOpacity(0.2),
                        width: isDragging || isHovered ? 2.5 : 1.5,
                      ),
                      boxShadow: isDragging || isHovered ? [
                        BoxShadow(
                          color: (isDragging ? const Color(0xFFFFD700) : const Color(0xFF00D4AA))
                              .withOpacity(0.5),
                          blurRadius: 20,
                        ),
                      ] : null,
                    ),
                    child: Center(
                      child: Text(p.symbol, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ]),
        ),
      );
    });
  }

  int? _hitTest(Offset pos) {
    for (int i = _particles.length - 1; i >= 0; i--) {
      if ((_particles[i].pos - pos).distance < 35) return i;
    }
    return null;
  }

  Widget _buildRecipes() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Рецепты алхимии',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4), letterSpacing: 1)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _kElements.map((e) {
            final done = _discovered.contains(e.result);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: done ? e.color.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: done ? e.color.withOpacity(0.5) : Colors.white.withOpacity(0.07),
                ),
              ),
              child: Column(children: [
                Text(done ? e.emoji : '❓',
                    style: TextStyle(fontSize: 18, color: done ? null : Colors.white.withOpacity(0.3))),
                const SizedBox(height: 2),
                Text(done ? e.result : '???',
                    style: TextStyle(
                        fontSize: 9,
                        color: done ? e.color : Colors.white.withOpacity(0.2),
                        fontWeight: FontWeight.w700)),
              ]),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Center(child: Text('Перетаскивай частицы друг на друга',
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3)))),
      ]),
    );
  }

  Widget _buildResultFlash() {
    return AnimatedBuilder(
      animation: _flashAnim,
      builder: (_, __) => Positioned(
        top: MediaQuery.of(context).size.height * 0.35,
        left: 40, right: 40,
        child: Opacity(
          opacity: (1 - _flashAnim.value).clamp(0, 1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.5), blurRadius: 20)],
            ),
            child: Text(
              _lastResult ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndOverlay() {
    final isSuccess = _phase == _AlchemyPhase.success;
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
                  Text(isSuccess ? '⚗️' : '💨', style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(
                    isSuccess ? 'АЛХИМИК\nМАСТЕР!' : 'ПОПЫТКИ\nИСЧЕРПАНЫ',
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
                        ? 'Создано ${_discovered.length} элементов!'
                        : 'Создано ${_discovered.length} из ${_kElements.length}',
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
class _LinePainter extends CustomPainter {
  final Offset from, to;
  final Color color;
  _LinePainter({required this.from, required this.to, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(from.dx, from.dy)..lineTo(to.dx, to.dy);
    canvas.drawPath(path, paint);

    // Стрелка
    final dir = (to - from);
    final len = dir.distance;
    if (len > 0) {
      final norm = dir / len;
      final arrowTip = to;
      final left  = Offset(arrowTip.dx - norm.dx * 12 + norm.dy * 6, arrowTip.dy - norm.dy * 12 - norm.dx * 6);
      final right = Offset(arrowTip.dx - norm.dx * 12 - norm.dy * 6, arrowTip.dy - norm.dy * 12 + norm.dx * 6);
      canvas.drawLine(arrowTip, left, paint);
      canvas.drawLine(arrowTip, right, paint);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.from != from || old.to != to;
}

class _AlchemyBgPainter extends CustomPainter {
  final double t;
  static final _rng = Random(99);
  _AlchemyBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF080412));

    final blobs = [
      [0.15, 0.25, 180.0, const Color(0xFF6A11CB)],
      [0.85, 0.45, 150.0, const Color(0xFFFF6B35)],
      [0.45, 0.75, 160.0, const Color(0xFFFFD700)],
    ];
    final p = Paint();
    for (final b in blobs) {
      final x = (b[0] as double) * size.width;
      final y = (b[1] as double) * size.height + sin(t * pi * 2) * 15;
      final r = (b[2] as double);
      final c = b[3] as Color;
      p.shader = RadialGradient(colors: [c.withOpacity(0.10), Colors.transparent])
          .createShader(Rect.fromCircle(center: Offset(x, y), radius: r));
      canvas.drawCircle(Offset(x, y), r, p);
    }
  }

  @override
  bool shouldRepaint(_AlchemyBgPainter old) => old.t != t;
}
