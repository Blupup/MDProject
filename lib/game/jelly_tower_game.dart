// lib/game/jelly_tower_game.dart
//
// 🏗️ БАШНЯ ИЗ ЖЕЛЕ — укладывай блоки друг на друга!
// Блок движется влево-вправо — нажми вовремя чтобы поставить его точно.
// Точность определяет ширину следующего блока. Построй башню из 7 этажей!

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

enum _JellyPhase { playing, success, fail }

class JellyTowerGame extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const JellyTowerGame({super.key, required this.onSuccess, required this.onFail});

  @override
  State<JellyTowerGame> createState() => _JellyTowerGameState();
}

// ─── Блок в башне ────────────────────────────────────────────────────────────
class _Block {
  double x;       // левый край (0..1 от ширины поля)
  double width;   // ширина (0..1)
  final Color color;
  _Block({required this.x, required this.width, required this.color});
}

class _JellyTowerGameState extends State<JellyTowerGame>
    with TickerProviderStateMixin {
  // ─── Конфиг ─────────────────────────────────────────────────────────────
  static const int _targetBlocks = 7;
  static const double _fieldHeight = 360;
  static const double _blockHeight = 40.0;
  static const double _initWidth = 0.60;

  // ─── Состояние ──────────────────────────────────────────────────────────
  List<_Block> _placed = [];
  double _movingX = 0;
  double _movingWidth = _initWidth;
  double _speed = 0.008;
  int _dir = 1;
  _JellyPhase _phase = _JellyPhase.playing;
  int _perfectCount = 0;
  bool _showPerfect = false;

  // ─── Анимации ───────────────────────────────────────────────────────────
  late AnimationController _gameCtrl;
  late AnimationController _bgCtrl;
  late AnimationController _dropCtrl;
  late AnimationController _resultCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _dropAnim;
  late Animation<double> _resultScale;
  late Animation<double> _resultFade;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  static const _kColors = [
    Color(0xFF00D4AA), Color(0xFF2E86AB), Color(0xFF6A11CB),
    Color(0xFFFF6B6B), Color(0xFFFFD700), Color(0xFFFF6B35), Color(0xFF4CAF50),
  ];

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _dropCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _dropAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _dropCtrl, curve: Curves.bounceOut));

    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _resultScale = Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.elasticOut));
    _resultFade  = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _shakeAnim = Tween(begin: -8.0, end: 8.0).animate(
        CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    // Первый «базовый» блок
    _placed = [_Block(x: 0.5 - _initWidth / 2, width: _initWidth, color: _kColors[0])];

    // Игровой тик
    _gameCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 999));
    _gameCtrl.addListener(_tick);
    _gameCtrl.forward();
  }

  @override
  void dispose() {
    _gameCtrl.dispose();
    _bgCtrl.dispose();
    _dropCtrl.dispose();
    _resultCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ─── Игровой тик ─────────────────────────────────────────────────────────
  void _tick() {
    if (_phase != _JellyPhase.playing) return;
    setState(() {
      _movingX += _speed * _dir;
      if (_movingX + _movingWidth >= 1.0) { _movingX = 1.0 - _movingWidth; _dir = -1; }
      if (_movingX <= 0) { _movingX = 0; _dir = 1; }
    });
  }

  // ─── Нажатие (сброс блока) ───────────────────────────────────────────────
  void _drop() {
    if (_phase != _JellyPhase.playing) return;
    HapticFeedback.mediumImpact();

    final prev = _placed.last;
    // Пересечение
    final overlapLeft  = max(_movingX, prev.x);
    final overlapRight = min(_movingX + _movingWidth, prev.x + prev.width);
    final overlap = overlapRight - overlapLeft;

    if (overlap <= 0) {
      // Промах — упал мимо
      _shakeCtrl.forward(from: 0);
      HapticFeedback.heavyImpact();
      setState(() => _phase = _JellyPhase.fail);
      _resultCtrl.forward(from: 0);
      Future.delayed(const Duration(seconds: 2), widget.onFail);
      return;
    }

    // Точность
    final accuracy = overlap / _movingWidth;
    final isPerfect = accuracy > 0.88;
    if (isPerfect) {
      _perfectCount++;
      setState(() => _showPerfect = true);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _showPerfect = false);
      });
    }

    // Новый блок — чуть сужается если неточно
    final newWidth = isPerfect ? _movingWidth : overlap;
    final newX     = overlapLeft;
    final color    = _kColors[_placed.length % _kColors.length];

    _placed.add(_Block(x: newX, width: newWidth, color: color));
    _dropCtrl.forward(from: 0);
    HapticFeedback.lightImpact();

    // Ускоряем немного
    _speed = min(0.020, _speed + 0.001);
    _movingX = 0;
    _movingWidth = newWidth;

    if (_placed.length > _targetBlocks) {
      setState(() => _phase = _JellyPhase.success);
      _resultCtrl.forward(from: 0);
      Future.delayed(const Duration(seconds: 2), widget.onSuccess);
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
            painter: _JellyBgPainter(_bgAnim.value),
          ),
        ),

        SafeArea(
          child: GestureDetector(
            onTapDown: (_) => _drop(),
            behavior: HitTestBehavior.opaque,
            child: Column(children: [
              _buildHeader(),
              _buildStats(),
              const SizedBox(height: 8),
              Expanded(child: _buildGameField()),
              _buildTapHint(),
              const SizedBox(height: 24),
            ]),
          ),
        ),

        if (_phase != _JellyPhase.playing)
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
              colors: [Color(0xFF2E86AB), Color(0xFF00D4AA)]).createShader(b),
          child: const Text('БАШНЯ ИЗ ЖЕЛЕ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: 1.5)),
        ),
        const Spacer(),
        // Счётчик этажей
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF2E86AB), Color(0xFF00D4AA)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('${_placed.length - 1}/$_targetBlocks',
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
            value: (_placed.length - 1) / _targetBlocks,
            minHeight: 4,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
          ),
        )),
        const SizedBox(width: 12),
        if (_perfectCount > 0)
          Row(children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 14),
            const SizedBox(width: 3),
            Text('$_perfectCount идеально',
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
      ]),
    );
  }

  Widget _buildGameField() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final fieldW = constraints.maxWidth - 40;
      final fieldH = min(_fieldHeight, constraints.maxHeight - 20.0);

      return Center(
        child: Container(
          width: fieldW,
          height: fieldH,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            // Поставленные блоки
            ..._buildPlacedBlocks(fieldW, fieldH),

            // Движущийся блок
            if (_phase == _JellyPhase.playing)
              _buildMovingBlock(fieldW, fieldH),

            // Perfect-флэш
            if (_showPerfect)
              const Center(child: Text('PERFECT! ✨',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                      color: Color(0xFFFFD700), letterSpacing: 1))),

            // Сетка-направляющие
            CustomPaint(size: Size(fieldW, fieldH), painter: _GridPainter()),
          ]),
        ),
      );
    });
  }

  List<Widget> _buildPlacedBlocks(double fw, double fh) {
    return _placed.asMap().entries.map((e) {
      final idx = e.key;
      final b = e.value;
      final bottomY = fh - (idx + 1) * _blockHeight;
      final isTop = idx == _placed.length - 1 && idx > 0;

      return Positioned(
        left: b.x * fw,
        top: bottomY,
        width: b.width * fw,
        height: _blockHeight - 2,
        child: AnimatedBuilder(
          animation: idx == _placed.length - 1 ? _dropAnim : const AlwaysStoppedAnimation(1.0),
          builder: (_, __) {
            final t = idx == _placed.length - 1 ? _dropAnim.value : 1.0;
            return Transform.scale(
              scaleY: 0.7 + t * 0.3,
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: b.color,
                  borderRadius: BorderRadius.circular(8),
                  border: isTop ? Border.all(color: Colors.white.withOpacity(0.4), width: 1.5) : null,
                  boxShadow: [
                    BoxShadow(color: b.color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(b.color, Colors.white, 0.3)!,
                      b.color,
                      Color.lerp(b.color, Colors.black, 0.2)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildMovingBlock(double fw, double fh) {
    return Positioned(
      left: _movingX * fw,
      top: fh - (_placed.length + 1) * _blockHeight,
      width: _movingWidth * fw,
      height: _blockHeight - 2,
      child: Container(
        decoration: BoxDecoration(
          color: _kColors[_placed.length % _kColors.length],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _kColors[_placed.length % _kColors.length].withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: LinearGradient(
            colors: [
              Color.lerp(_kColors[_placed.length % _kColors.length], Colors.white, 0.4)!,
              _kColors[_placed.length % _kColors.length],
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildTapHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.touch_app_rounded, color: Color(0xFF00D4AA), size: 18),
          const SizedBox(width: 10),
          Text(
            _phase == _JellyPhase.playing
                ? 'Нажми КУДА УГОДНО чтобы сбросить блок'
                : _phase == _JellyPhase.success ? '🎉 Башня построена!' : '💥 Башня упала!',
            style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }

  Widget _buildResultOverlay() {
    final isSuccess = _phase == _JellyPhase.success;
    return AnimatedBuilder(
      animation: _resultCtrl,
      builder: (_, __) => FadeTransition(
        opacity: _resultFade,
        child: Container(
          color: Colors.black.withOpacity(0.75),
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
                  Text(isSuccess ? '🏗️' : '💥', style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(
                    isSuccess ? 'БАШНЯ\nПОСТРОЕНА!' : 'БАШНЯ\nРУХНУЛА!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900,
                      color: isSuccess ? const Color(0xFF00D4AA) : const Color(0xFFFF6B6B),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSuccess ? '${_placed.length - 1} этажей!\n$_perfectCount идеальных бросков 🌟' : 'Блок упал мимо башни',
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
class _JellyBgPainter extends CustomPainter {
  final double t;
  _JellyBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF030A18));

    final blobs = [
      [0.2, 0.3, 200.0, const Color(0xFF2E86AB)],
      [0.8, 0.6, 160.0, const Color(0xFF00D4AA)],
      [0.5, 0.1, 180.0, const Color(0xFF6A11CB)],
    ];
    final paint = Paint();
    for (final b in blobs) {
      final x = (b[0] as double) * size.width;
      final y = (b[1] as double) * size.height + sin(t * pi * 2) * 20;
      final r = (b[2] as double);
      final c = b[3] as Color;
      paint.shader = RadialGradient(
        colors: [c.withOpacity(0.10), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: r));
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_JellyBgPainter old) => old.t != t;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
