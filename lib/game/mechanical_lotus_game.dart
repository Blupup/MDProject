// lib/game/mechanical_lotus_game.dart
//
// «Механический лотос» — вращай слои шестерёнчатого цветка чтобы совместить пазы.
// Квест 2 «Железо» — разберись в механизмах корпуса.
//
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

// ─── Один слой лотоса ─────────────────────────────────────────────────────
class _Layer {
  double angle;          // текущий угол (рад)
  final double targetAngle; // целевой угол
  final int teeth;          // количество зубьев
  final Color color;
  final double radius;

  _Layer({
    required this.angle,
    required this.targetAngle,
    required this.teeth,
    required this.color,
    required this.radius,
  });

  bool get aligned {
    final diff = ((angle - targetAngle) % (2 * pi)).abs();
    return diff < 0.18 || diff > 2 * pi - 0.18;
  }
}

// ─── Уровни: конфигурации слоёв ───────────────────────────────────────────
List<List<_Layer>> _buildLevels() => [
  // Уровень 1 — 2 слоя
  [
    _Layer(angle: 0.8, targetAngle: 0, teeth: 8,  color: const Color(0xFFB87333), radius: 0.85),
    _Layer(angle: 1.5, targetAngle: 0, teeth: 12, color: const Color(0xFF8B6914), radius: 0.55),
  ],
  // Уровень 2 — 3 слоя
  [
    _Layer(angle: 1.2, targetAngle: 0,       teeth: 8,  color: const Color(0xFFB87333), radius: 0.88),
    _Layer(angle: 0.9, targetAngle: pi / 4,  teeth: 10, color: const Color(0xFF8B6914), radius: 0.62),
    _Layer(angle: 2.1, targetAngle: 0,       teeth: 6,  color: const Color(0xFFCD7F32), radius: 0.38),
  ],
  // Уровень 3 — 3 слоя с разными углами
  [
    _Layer(angle: 2.5,      targetAngle: pi / 6,  teeth: 10, color: const Color(0xFFB87333), radius: 0.88),
    _Layer(angle: 0.3,      targetAngle: pi / 3,  teeth: 8,  color: const Color(0xFF8B6914), radius: 0.62),
    _Layer(angle: 1.8,      targetAngle: pi / 2,  teeth: 6,  color: const Color(0xFFDAA520), radius: 0.38),
  ],
  // Уровень 4 — 4 слоя
  [
    _Layer(angle: 1.0,      targetAngle: 0,       teeth: 12, color: const Color(0xFFB87333), radius: 0.90),
    _Layer(angle: 2.3,      targetAngle: pi / 4,  teeth: 10, color: const Color(0xFF8B6914), radius: 0.68),
    _Layer(angle: 0.7,      targetAngle: pi / 2,  teeth: 8,  color: const Color(0xFFCD7F32), radius: 0.46),
    _Layer(angle: 3.1,      targetAngle: pi,      teeth: 6,  color: const Color(0xFFDAA520), radius: 0.26),
  ],
];

// ─── Главный виджет ───────────────────────────────────────────────────────
class MechanicalLotusGame extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const MechanicalLotusGame({super.key, required this.onSuccess, required this.onFail});

  @override
  State<MechanicalLotusGame> createState() => _MechanicalLotusGameState();
}

class _MechanicalLotusGameState extends State<MechanicalLotusGame>
    with TickerProviderStateMixin {

  late List<List<_Layer>> _levels;
  int _levelIdx = 0;
  int _timeLeft = 90;

  bool _won = false, _failed = false;

  // Для вращения пальцем
  int? _draggingLayer;
  double _dragStartAngle = 0;
  double _layerStartAngle = 0;

  late AnimationController _winCtrl, _failCtrl, _bloomCtrl, _steamCtrl;
  late Animation<double> _winScale, _failScale, _bloomAnim, _steamAnim;

  @override
  void initState() {
    super.initState();
    _levels = _buildLevels();

    _winCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _failCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _bloomCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _steamCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

    _winScale  = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _winCtrl,  curve: Curves.elasticOut));
    _failScale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _failCtrl, curve: Curves.easeOut));
    _bloomAnim = Tween(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _bloomCtrl, curve: Curves.easeInOut));
    _steamAnim = CurvedAnimation(parent: _steamCtrl, curve: Curves.linear);

    _startTimer();
  }

  @override
  void dispose() {
    _winCtrl.dispose(); _failCtrl.dispose();
    _bloomCtrl.dispose(); _steamCtrl.dispose();
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

  List<_Layer> get _currentLayers => _levels[_levelIdx];

  void _checkWin() {
    if (_currentLayers.every((l) => l.aligned)) {
      _triggerWin();
    }
  }

  void _triggerWin() {
    if (_won) return;
    setState(() => _won = true);
    HapticFeedback.heavyImpact();
    _winCtrl.forward();

    if (_levelIdx < _levels.length - 1) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _levelIdx++;
          _won = false;
          _timeLeft = 90;
        });
        _winCtrl.reset();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted) widget.onSuccess();
      });
    }
  }

  void _triggerFail() {
    if (_failed) return;
    setState(() => _failed = true);
    _failCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) widget.onFail();
    });
  }

  // ─── Вычисляем угол от центра виджета ────────────────────────────────────
  double _angleFrom(Offset center, Offset point) {
    return atan2(point.dy - center.dy, point.dx - center.dx);
  }

  int _layerAtRadius(Offset center, Offset point) {
    final dist = (point - center).distance;
    final maxR = center.dx * 0.9; // ~90% half-width
    final ratio = dist / maxR;

    for (int i = _currentLayers.length - 1; i >= 0; i--) {
      if (ratio <= _currentLayers[i].radius + 0.08) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0F05),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: _buildLotus(),
              ),
              if (_won && _levelIdx == _levels.length - 1)
                _buildWinOverlay(),
              if (_failed)
                _buildFailOverlay(),
            ]),
          ),
          _buildInstruction(),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    final timeColor = _timeLeft > 45 ? const Color(0xFFDAA520) : (_timeLeft > 15 ? Colors.orange : kRed);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      color: const Color(0xFF1A0F05),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFB87333), Color(0xFFDAA520)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: const Color(0xFFDAA520).withOpacity(0.4), blurRadius: 10)],
          ),
          child: const Row(children: [
            Text('⚙️', style: TextStyle(fontSize: 13)),
            SizedBox(width: 5),
            Text('Механический лотос',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
        const Spacer(),
        Text('Уровень ${_levelIdx + 1}/${_levels.length}',
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
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

  Widget _buildLotus() {
    return LayoutBuilder(builder: (ctx, cst) {
      final size = min(cst.maxWidth, cst.maxHeight);
      final center = Offset(size / 2, size / 2);

      return GestureDetector(
        onPanStart: (d) {
          final local = d.localPosition;
          _draggingLayer = _layerAtRadius(center, local);
          if (_draggingLayer != null && _draggingLayer! >= 0) {
            _dragStartAngle = _angleFrom(center, local);
            _layerStartAngle = _currentLayers[_draggingLayer!].angle;
          }
        },
        onPanUpdate: (d) {
          if (_draggingLayer == null || _draggingLayer! < 0) return;
          final local = d.localPosition;
          final currentAngle = _angleFrom(center, local);
          final delta = currentAngle - _dragStartAngle;
          setState(() {
            _currentLayers[_draggingLayer!].angle = _layerStartAngle + delta;
          });
        },
        onPanEnd: (_) {
          if (_draggingLayer != null && _draggingLayer! >= 0) {
            // Snap: сначала проверяем близость к targetAngle, иначе — сетка π/12
            final layer = _currentLayers[_draggingLayer!];
            double snapped;
            // Нормализуем разницу с targetAngle
            double diff = (layer.angle - layer.targetAngle) % (2 * pi);
            if (diff < 0) diff += 2 * pi;
            if (diff > pi) diff = diff - 2 * pi; // -π..π
            if (diff.abs() < 0.35) {
              // Близко к цели — прилипаем точно
              snapped = layer.targetAngle;
            } else {
              // Иначе snap к мелкой сетке π/12 (15°)
              snapped = (layer.angle / (pi / 12)).round() * (pi / 12);
            }
            setState(() => layer.angle = snapped);
            HapticFeedback.selectionClick();
            _checkWin();
          }
          _draggingLayer = null;
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_bloomCtrl, _steamCtrl]),
          builder: (_, __) => CustomPaint(
            size: Size(size, size),
            painter: _LotusPainter(
              layers: _currentLayers,
              bloomValue: _bloomAnim.value,
              steamValue: _steamAnim.value,
              won: _won,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildInstruction() {
    final aligned = _currentLayers.where((l) => l.aligned).length;
    // Проверяем «почти совмещено» для каждого слоя
    bool isNear(int i) {
      final layer = _currentLayers[i];
      double diff = (layer.angle - layer.targetAngle) % (2 * pi);
      if (diff < 0) diff += 2 * pi;
      if (diff > pi) diff = 2 * pi - diff;
      return diff < 0.5 && !layer.aligned;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: const Color(0xFF1A0F05),
      child: Column(children: [
        // Прогресс слоёв
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ...List.generate(_currentLayers.length, (i) {
            final ok = _currentLayers[i].aligned;
            final near = isNear(i);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: ok   ? const Color(0xFFDAA520).withOpacity(0.25)
                       : near ? Colors.orange.withOpacity(0.15)
                              : Colors.white.withOpacity(0.04),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ok   ? const Color(0xFFDAA520)
                         : near ? Colors.orange.withOpacity(0.7)
                                : Colors.white.withOpacity(0.12),
                    width: 1.8,
                  ),
                  boxShadow: ok ? [BoxShadow(color: const Color(0xFFDAA520).withOpacity(0.4), blurRadius: 10)] : [],
                ),
                child: Center(child: Text(
                  ok ? '✓' : (near ? '~' : '${i + 1}'),
                  style: TextStyle(
                    color: ok ? const Color(0xFFDAA520) : (near ? Colors.orange : Colors.white30),
                    fontSize: 13, fontWeight: FontWeight.w900,
                  ),
                )),
              ),
            );
          }),
        ]),
        const SizedBox(height: 8),
        Text(
          aligned == _currentLayers.length
              ? '🌸 Все слои совмещены!'
              : '↺ Крути слои пальцем — совмести метки с линией сверху',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: aligned == _currentLayers.length
                ? const Color(0xFFDAA520)
                : Colors.white.withOpacity(0.38),
          ),
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
            const Text('🌸', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text('Лотос раскрылся!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Механизм разгадан',
                style: TextStyle(color: Color(0xFFDAA520), fontSize: 14)),
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
            const Text('💨', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text('Механизм заклинило!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Уровень ${_levelIdx + 1} не пройден',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
          ],
        ))),
      ),
    );
  }
}

// ─── CustomPainter ────────────────────────────────────────────────────────
class _LotusPainter extends CustomPainter {
  final List<_Layer> layers;
  final double bloomValue, steamValue;
  final bool won;

  _LotusPainter({
    required this.layers, required this.bloomValue,
    required this.steamValue, required this.won,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final maxR = cx;

    _drawBackground(canvas, size, center);
    _drawSteam(canvas, size, center, maxR);

    // Рисуем слои от большего к меньшему
    for (int i = 0; i < layers.length; i++) {
      _drawLayer(canvas, center, maxR, layers[i], i);
    }

    _drawCenterHub(canvas, center, maxR * 0.12);
    _drawAlignmentGuide(canvas, center, maxR);
  }

  void _drawBackground(Canvas canvas, Size size, Offset center) {
    // Радиальный фон
    canvas.drawCircle(center, size.width / 2,
        Paint()..shader = RadialGradient(
          colors: [
            const Color(0xFF2A1505),
            const Color(0xFF0D0702),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: size.width / 2)));

    // Декоративные кольца
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, size.width / 2 * i / 4,
          Paint()
            ..color = const Color(0xFFB87333).withOpacity(0.06)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5);
    }
  }

  void _drawSteam(Canvas canvas, Size size, Offset center, double maxR) {
    final rng = Random(42);
    for (int i = 0; i < 8; i++) {
      final x = center.dx + (rng.nextDouble() - 0.5) * maxR * 1.4;
      final baseY = center.dy + maxR * 0.3;
      final progress = (steamValue + i / 8) % 1.0;
      final y = baseY - progress * maxR * 0.8;
      final opacity = (1 - progress) * 0.08;
      canvas.drawCircle(Offset(x, y), 6 + progress * 12,
          Paint()..color = const Color(0xFFDAA520).withOpacity(opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
  }

  void _drawLayer(Canvas canvas, Offset center, double maxR, _Layer layer, int idx) {
    final r = maxR * layer.radius;
    final isAligned = layer.aligned;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(layer.angle);

    // Основное кольцо
    final baseColor = isAligned
        ? Color.lerp(layer.color, const Color(0xFFFFD700), 0.5 * bloomValue)!
        : layer.color;

    // Тело шестерни
    final gearPath = _buildGearPath(r, layer.teeth, r * 0.15);
    canvas.drawPath(gearPath, Paint()..color = baseColor.withOpacity(0.35));
    canvas.drawPath(gearPath, Paint()
      ..color = baseColor.withOpacity(isAligned ? 0.9 : 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isAligned ? 2.5 : 1.5);

    // Свечение при совмещении
    if (isAligned) {
      canvas.drawPath(gearPath, Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.2 * bloomValue)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    }

    // Паз (метка совмещения) — треугольник сверху
    final notchPath = Path()
      ..moveTo(0, -r + r * 0.18)
      ..lineTo(-r * 0.06, -r + r * 0.05)
      ..lineTo(r * 0.06, -r + r * 0.05)
      ..close();
    canvas.drawPath(notchPath,
        Paint()..color = isAligned ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.4));

    // Внутреннее кольцо
    canvas.drawCircle(Offset.zero, r * 0.65,
        Paint()..color = baseColor.withOpacity(0.1));
    canvas.drawCircle(Offset.zero, r * 0.65,
        Paint()..color = baseColor.withOpacity(0.4)
          ..style = PaintingStyle.stroke..strokeWidth = 1);

    // Болтики
    for (int b = 0; b < 4; b++) {
      final ba = b * pi / 2;
      final bx = cos(ba) * r * 0.5;
      final by = sin(ba) * r * 0.5;
      canvas.drawCircle(Offset(bx, by), r * 0.04,
          Paint()..color = baseColor.withOpacity(0.8));
    }

    canvas.restore();
  }

  Path _buildGearPath(double r, int teeth, double toothH) {
    final path = Path();
    final innerR = r - toothH;
    final step = 2 * pi / teeth;

    for (int t = 0; t < teeth; t++) {
      final a1 = t * step - step * 0.3;
      final a2 = t * step + step * 0.3;
      final a3 = t * step + step * 0.7;
      final a4 = (t + 1) * step - step * 0.3;

      final p1 = Offset(cos(a1) * innerR, sin(a1) * innerR);
      final p2 = Offset(cos(a2) * r,      sin(a2) * r);
      final p3 = Offset(cos(a3) * r,      sin(a3) * r);
      final p4 = Offset(cos(a4) * innerR, sin(a4) * innerR);

      if (t == 0) path.moveTo(p1.dx, p1.dy);
      else path.lineTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(p3.dx, p3.dy);
      path.lineTo(p4.dx, p4.dy);
    }
    path.close();
    return path;
  }

  void _drawCenterHub(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(center, r * 1.8,
        Paint()..color = const Color(0xFF3D2010)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(center, r * 1.6,
        Paint()..color = const Color(0xFFB87333));
    canvas.drawCircle(center, r * 1.6,
        Paint()..color = const Color(0xFFDAA520)
          ..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(center, r * 0.8,
        Paint()..color = const Color(0xFF3D2010));

    // Крест в центре
    final linePaint = Paint()
      ..color = const Color(0xFFDAA520).withOpacity(0.6)
      ..strokeWidth = 1.5;
    canvas.drawLine(center - Offset(r, 0), center + Offset(r, 0), linePaint);
    canvas.drawLine(center - Offset(0, r), center + Offset(0, r), linePaint);
  }

  void _drawAlignmentGuide(Canvas canvas, Offset center, double maxR) {
    // Вертикальная линия — индикатор совмещения
    canvas.drawLine(
      Offset(center.dx, center.dy - maxR * 0.95),
      Offset(center.dx, center.dy - maxR * 0.75),
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.3)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - maxR * 0.97),
      4,
      Paint()..color = const Color(0xFFFFD700).withOpacity(0.5),
    );
  }

  @override
  bool shouldRepaint(_LotusPainter old) => true;
}
