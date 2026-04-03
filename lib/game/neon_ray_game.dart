// lib/game/neon_ray_game.dart
//
// «Неоновый луч» — направь лазер в цель с помощью зеркал.
// Управление: нажми на слот (S) — поставить зеркало \
//             нажми ещё раз   — повернуть на /
//             нажми ещё раз   — убрать
//
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

enum _Dir { right, down, left, up }

_Dir _reflectSlash(_Dir d) => switch (d) {
  _Dir.right => _Dir.up,
  _Dir.down  => _Dir.left,
  _Dir.left  => _Dir.down,
  _Dir.up    => _Dir.right,
};

_Dir _reflectBackslash(_Dir d) => switch (d) {
  _Dir.right => _Dir.down,
  _Dir.down  => _Dir.right,
  _Dir.left  => _Dir.up,
  _Dir.up    => _Dir.left,
};

Offset _dirOff(_Dir d) => switch (d) {
  _Dir.right => const Offset(1, 0),
  _Dir.down  => const Offset(0, 1),
  _Dir.left  => const Offset(-1, 0),
  _Dir.up    => const Offset(0, -1),
};

enum _Cell { empty, wall, emitter, target, slot }

class _Level {
  final int cols, rows;
  final List<List<_Cell>> grid;
  final Offset emitter;
  final _Dir emitDir;
  final Offset target;
  final List<Offset> slots;
  final int maxMirrors;
  final String hint;
  const _Level({required this.cols, required this.rows, required this.grid,
    required this.emitter, required this.emitDir, required this.target,
    required this.slots, required this.maxMirrors, required this.hint});
}

_Level _parse(List<String> rows, _Dir dir, int mirrors, String hint) {
  final grid = <List<_Cell>>[];
  Offset em = Offset.zero, tg = Offset.zero;
  final slots = <Offset>[];
  for (int r = 0; r < rows.length; r++) {
    final row = <_Cell>[];
    for (int c = 0; c < rows[r].length; c++) {
      switch (rows[r][c]) {
        case '#': row.add(_Cell.wall);
        case 'E': row.add(_Cell.emitter); em = Offset(c.toDouble(), r.toDouble());
        case 'T': row.add(_Cell.target);  tg = Offset(c.toDouble(), r.toDouble());
        case 'S': row.add(_Cell.slot);    slots.add(Offset(c.toDouble(), r.toDouble()));
        default:  row.add(_Cell.empty);
      }
    }
    grid.add(row);
  }
  return _Level(cols: rows[0].length, rows: rows.length, grid: grid,
    emitter: em, emitDir: dir, target: tg,
    slots: slots, maxMirrors: mirrors, hint: hint);
}

final _levels = [
  _parse(['#######','#E...T#','#######'], _Dir.right, 0,
    'Луч летит прямо — цель справа. Наблюдай!'),
  _parse(['#######','#E....#','#.....#','#....T#','#######'],
    _Dir.right, 1, 'Поставь зеркало \\ на любой слот чтобы луч повернул вниз'),
  _parse(['#######','#E....#','#.S...#','#.....#','#T....#','#######'],
    _Dir.right, 1, 'Слот отмечен точкой. Нажми на него → поставь зеркало'),
  _parse(['########','#E.....#','#......#','#.S..S.#','#......#','#......T','########'],
    _Dir.right, 2, 'Два зеркала: первое \\ вниз, второе \\ снова вниз к цели'),
  _parse(['#########','#E......#','#.S.....#','#.......#','#.....S.#','#.......#','#T......#','#########'],
    _Dir.right, 2, 'Два зеркала чтобы добраться до цели внизу слева'),
];

class NeonRayGame extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFail;
  const NeonRayGame({super.key, required this.onSuccess, required this.onFail});
  @override
  State<NeonRayGame> createState() => _NeonRayGameState();
}

class _NeonRayGameState extends State<NeonRayGame> with TickerProviderStateMixin {
  int _lvlIdx = 0;
  // ключ = "col,row", значение = true → '/' , false → '\'
  final Map<String, bool> _mirrors = {};
  bool _won = false, _failed = false;
  int _timeLeft = 90, _moves = 0;

  late AnimationController _glowCtrl, _winCtrl, _failCtrl;
  late Animation<double> _glow, _winScale, _failScale;

  _Level get _lv => _levels[_lvlIdx];
  String _mk(Offset o) => '${o.dx.toInt()},${o.dy.toInt()}';

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _winCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _failCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _glow      = Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _winScale  = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _winCtrl,  curve: Curves.elasticOut));
    _failScale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _failCtrl, curve: Curves.easeOut));
    _startTimer();
  }

  @override
  void dispose() { _glowCtrl.dispose(); _winCtrl.dispose(); _failCtrl.dispose(); super.dispose(); }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _won || _failed) return false;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) { _triggerFail(); return false; }
      return true;
    });
  }

  List<Offset> _trace() {
    final path = <Offset>[];
    var pos = _lv.emitter;
    var dir = _lv.emitDir;
    final visited = <String>{};
    path.add(pos);
    for (int i = 0; i < 300; i++) {
      final vk = '${pos.dx},${pos.dy},$dir';
      if (visited.contains(vk)) break;
      visited.add(vk);
      final next = pos + _dirOff(dir);
      final nx = next.dx.toInt(), ny = next.dy.toInt();
      if (ny < 0 || ny >= _lv.rows || nx < 0 || nx >= _lv.cols) break;
      final cell = _lv.grid[ny][nx];
      path.add(next);
      if (cell == _Cell.wall) break;
      if (cell == _Cell.target) break;
      final mk = '${nx},${ny}';
      if (_mirrors.containsKey(mk)) {
        dir = _mirrors[mk]! ? _reflectSlash(dir) : _reflectBackslash(dir);
      }
      pos = next;
    }
    return path;
  }

  bool _checkWin() => _trace().isNotEmpty && _trace().last == _lv.target;

  void _tapSlot(Offset slot) {
    if (_won || _failed) return;
    final mk = _mk(slot);
    setState(() {
      if (!_mirrors.containsKey(mk)) {
        if (_lv.maxMirrors == 0 || _mirrors.length < _lv.maxMirrors) {
          _mirrors[mk] = false; // '\' первым
          _moves++;
        }
      } else if (_mirrors[mk] == false) {
        _mirrors[mk] = true; // '/'
        _moves++;
      } else {
        _mirrors.remove(mk);
        _moves++;
      }
    });
    HapticFeedback.selectionClick();
    if (_checkWin()) _triggerWin();
  }

  void _triggerWin() {
    if (_won) return;
    setState(() => _won = true);
    HapticFeedback.heavyImpact();
    _winCtrl.forward();
    if (_lvlIdx < _levels.length - 1) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() { _lvlIdx++; _won = false; _mirrors.clear(); _timeLeft = 90; });
        _winCtrl.reset();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 2200), () { if (mounted) widget.onSuccess(); });
    }
  }

  void _triggerFail() {
    if (_failed) return;
    setState(() => _failed = true);
    _failCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () { if (mounted) widget.onFail(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Column(children: [
        _buildHeader(),
        Expanded(child: Stack(children: [
          Padding(padding: const EdgeInsets.all(16), child: _buildGrid()),
          if (_won && _lvlIdx == _levels.length - 1) _buildOverlay(true),
          if (_failed) _buildOverlay(false),
        ])),
        _buildLegend(),
      ])),
    );
  }

  Widget _buildHeader() {
    final tc = _timeLeft > 40 ? kGreen : (_timeLeft > 15 ? Colors.orange : kRed);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      color: Colors.black,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0066FF), Color(0xFF00F5FF)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: const Color(0xFF00F5FF).withOpacity(0.4), blurRadius: 10)],
          ),
          child: const Row(children: [
            Text('🔦', style: TextStyle(fontSize: 13)),
            SizedBox(width: 5),
            Text('Неоновый луч', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
        const Spacer(),
        Text('Уровень ${_lvlIdx + 1}/${_levels.length}',
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(width: 12),
        AnimatedBuilder(animation: _glow, builder: (_, __) =>
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              border: Border.all(color: tc.withOpacity(_glow.value), width: 2),
              shape: BoxShape.circle, color: tc.withOpacity(0.1),
            ),
            child: Center(child: Text('$_timeLeft',
                style: TextStyle(color: tc, fontSize: 13, fontWeight: FontWeight.w900))),
          ),
        ),
      ]),
    );
  }

  Widget _buildGrid() {
    final ray = _trace();
    return LayoutBuilder(builder: (ctx, cst) {
      final cs = min(cst.maxWidth / _lv.cols, cst.maxHeight / _lv.rows);
      final tw = cs * _lv.cols, th = cs * _lv.rows;
      return Center(child: SizedBox(width: tw, height: th,
        child: AnimatedBuilder(animation: _glowCtrl, builder: (_, __) =>
          CustomPaint(
            size: Size(tw, th),
            painter: _RayPainter(lv: _lv, mirrors: Map.from(_mirrors), ray: ray, glow: _glow.value, cs: cs, won: _won),
            child: Stack(children: [
              for (final slot in _lv.slots)
                Positioned(
                  left: slot.dx * cs, top: slot.dy * cs, width: cs, height: cs,
                  child: GestureDetector(
                    onTap: () => _tapSlot(slot),
                    child: Container(color: Colors.transparent),
                  ),
                ),
            ]),
          ),
        ),
      ));
    });
  }

  Widget _buildLegend() {
    final left = (_lv.maxMirrors - _mirrors.length).clamp(0, 99);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      color: Colors.black,
      child: Column(children: [
        Text(_lv.hint, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (_lv.maxMirrors > 0) ...[
            _chip('🪞 ×$left', 'осталось', const Color(0xFF00F5FF)),
            const SizedBox(width: 16),
          ],
          _chip('1×→ \\', 'поставить', Colors.white54),
          const SizedBox(width: 10),
          _chip('2×→ /', 'повернуть', Colors.white54),
          const SizedBox(width: 10),
          _chip('3×→ ✕', 'убрать', Colors.white38),
        ]),
      ]),
    );
  }

  Widget _chip(String val, String label, Color c) => Column(children: [
    Text(val, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
    Text(label, style: TextStyle(color: c.withOpacity(0.5), fontSize: 9)),
  ]);

  Widget _buildOverlay(bool win) {
    return Positioned.fill(child: Container(
      color: Colors.black.withOpacity(0.75),
      child: ScaleTransition(scale: win ? _winScale : _failScale,
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(win ? '✨' : '⏰', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 14),
          Text(win ? 'Путь найден!' : 'Время вышло!',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          Text(win ? '$_moves ходов' : 'Пройдено: $_lvlIdx уровней',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
        ])),
      ),
    ));
  }
}

class _RayPainter extends CustomPainter {
  final _Level lv;
  final Map<String, bool> mirrors;
  final List<Offset> ray;
  final double glow, cs;
  final bool won;

  static const _cyan = Color(0xFF00F5FF);

  _RayPainter({required this.lv, required this.mirrors, required this.ray,
    required this.glow, required this.cs, required this.won});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF030810));

    for (int r = 0; r < lv.rows; r++) {
      for (int c = 0; c < lv.cols; c++) {
        _drawCell(canvas, c, r, lv.grid[r][c]);
      }
    }
    _drawRay(canvas);
    mirrors.forEach((k, isSlash) {
      final parts = k.split(',');
      _drawMirror(canvas, int.parse(parts[0]), int.parse(parts[1]), isSlash);
    });
  }

  void _drawCell(Canvas canvas, int c, int r, _Cell cell) {
    final rect = Rect.fromLTWH(c * cs + 1, r * cs + 1, cs - 2, cs - 2);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(5));
    final cx = (c + 0.5) * cs, cy = (r + 0.5) * cs;

    switch (cell) {
      case _Cell.wall:
        canvas.drawRRect(rr, Paint()..color = const Color(0xFF1A2040));
        canvas.drawRRect(rr, Paint()..color = const Color(0xFF2E86AB).withOpacity(0.3)
          ..style = PaintingStyle.stroke..strokeWidth = 1);

      case _Cell.emitter:
        canvas.drawRRect(rr, Paint()..color = _cyan.withOpacity(0.08));
        canvas.drawCircle(Offset(cx, cy), cs * 0.28, Paint()..color = _cyan);
        // Стрелка вправо
        final s = cs * 0.15;
        final p = Paint()..color = Colors.black..strokeWidth = 2..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx - s, cy), Offset(cx + s, cy), p);
        canvas.drawLine(Offset(cx, cy - s * 0.6), Offset(cx + s, cy), p);
        canvas.drawLine(Offset(cx, cy + s * 0.6), Offset(cx + s, cy), p);

      case _Cell.target:
        canvas.drawCircle(Offset(cx, cy), cs * 0.3 * glow + 4,
            Paint()..color = kGold.withOpacity(0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
        canvas.drawCircle(Offset(cx, cy), cs * 0.28,
            Paint()..color = won ? kGold : kGold.withOpacity(0.7));
        final tp = TextPainter(text: const TextSpan(text: '🎯', style: TextStyle(fontSize: 18)),
            textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

      case _Cell.slot:
        canvas.drawRRect(rr, Paint()..color = const Color(0xFF080E1A));
        canvas.drawRRect(rr, Paint()..color = _cyan.withOpacity(0.18)
          ..style = PaintingStyle.stroke..strokeWidth = 1.5);
        // Крестик-подсказка
        canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = _cyan.withOpacity(0.35));

      case _Cell.empty: break;
    }
  }

  void _drawRay(Canvas canvas) {
    if (ray.length < 2) return;
    final color = won ? kGold : _cyan;
    for (int i = 0; i < ray.length - 1; i++) {
      final a = Offset((ray[i].dx + 0.5) * cs, (ray[i].dy + 0.5) * cs);
      final b = Offset((ray[i+1].dx + 0.5) * cs, (ray[i+1].dy + 0.5) * cs);
      canvas.drawLine(a, b, Paint()..color = color.withOpacity(0.18 * glow)
        ..strokeWidth = cs * 0.45..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawLine(a, b, Paint()..color = color
        ..strokeWidth = 3..strokeCap = StrokeCap.round);
    }
  }

  void _drawMirror(Canvas canvas, int c, int r, bool isSlash) {
    final cx = (c + 0.5) * cs, cy = (r + 0.5) * cs;
    final h = cs * 0.38;
    final rect = Rect.fromLTWH(c * cs + 1, r * cs + 1, cs - 2, cs - 2);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()..color = const Color(0xFF0D1A2E));

    final Offset p1, p2;
    if (isSlash) {
      p1 = Offset(cx - h, cy + h); p2 = Offset(cx + h, cy - h);
    } else {
      p1 = Offset(cx - h, cy - h); p2 = Offset(cx + h, cy + h);
    }

    canvas.drawLine(p1, p2, Paint()..color = const Color(0xFF00F5FF).withOpacity(0.35)
      ..strokeWidth = cs * 0.2..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawLine(p1, p2, Paint()..color = const Color(0xFFE0F0FF)
      ..strokeWidth = 3.5..strokeCap = StrokeCap.round);

    // Метка
    final tp = TextPainter(
      text: TextSpan(text: isSlash ? '/' : '\\',
        style: TextStyle(color: _cyan.withOpacity(0.5), fontSize: cs * 0.22, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c * cs + 3, r * cs + 2));
  }

  @override
  bool shouldRepaint(_RayPainter old) => true;
}
