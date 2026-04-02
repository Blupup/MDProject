// lib/game/neon_ray_game.dart
//
// «Неоновый луч» — расставь зеркала так чтобы лазер попал в цель.
// Квест 1 «Посвящение» — найди путь как новичок ищет дорогу в корпусе.
//
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

// ─── Типы объектов на поле ────────────────────────────────────────────────
enum _CellType { empty, mirror45, mirror135, wall, emitter, target }

class _Cell {
  _CellType type;
  _Cell(this.type);
}

// Направление луча
enum _Dir { right, down, left, up }

_Dir _reflect45(_Dir d) => switch (d) {
  _Dir.right => _Dir.up,
  _Dir.down  => _Dir.left,
  _Dir.left  => _Dir.down,
  _Dir.up    => _Dir.right,
};

_Dir _reflect135(_Dir d) => switch (d) {
  _Dir.right => _Dir.down,
  _Dir.down  => _Dir.right,
  _Dir.left  => _Dir.up,
  _Dir.up    => _Dir.left,
};

Offset _dirOffset(_Dir d) => switch (d) {
  _Dir.right => const Offset(1, 0),
  _Dir.down  => const Offset(0, 1),
  _Dir.left  => const Offset(-1, 0),
  _Dir.up    => const Offset(0, -1),
};

// ─── Уровни ───────────────────────────────────────────────────────────────
class _Level {
  final int cols, rows;
  final List<List<_CellType>> grid;   // строки × столбцы
  final Offset emitter;               // позиция источника
  final _Dir emitDir;
  final Offset target;                // позиция цели
  final List<Offset> mirrorSlots;     // куда можно ставить зеркала
  final int mirrorsAvailable;

  const _Level({
    required this.cols, required this.rows,
    required this.grid, required this.emitter,
    required this.emitDir, required this.target,
    required this.mirrorSlots, required this.mirrorsAvailable,
  });
}

// Упрощённый конструктор уровня из строк символов:
// '.' = пусто, '#' = стена, 'E' = источник, 'T' = цель, 'S' = слот для зеркала
_Level _parseLevel(List<String> rows, _Dir emitDir, int mirrors) {
  final grid = <List<_CellType>>[];
  Offset emitter = Offset.zero, target = Offset.zero;
  final slots = <Offset>[];

  for (int r = 0; r < rows.length; r++) {
    final row = <_CellType>[];
    for (int c = 0; c < rows[r].length; c++) {
      switch (rows[r][c]) {
        case '#': row.add(_CellType.wall);
        case 'E': row.add(_CellType.emitter); emitter = Offset(c.toDouble(), r.toDouble());
        case 'T': row.add(_CellType.target);  target  = Offset(c.toDouble(), r.toDouble());
        case 'S': row.add(_CellType.empty);   slots.add(Offset(c.toDouble(), r.toDouble()));
        default:  row.add(_CellType.empty);
      }
    }
    grid.add(row);
  }
  return _Level(
    cols: rows[0].length, rows: rows.length,
    grid: grid, emitter: emitter, emitDir: emitDir,
    target: target, mirrorSlots: slots, mirrorsAvailable: mirrors,
  );
}

final _levels = [
  // Уровень 1 — простой
  _parseLevel([
    '###########',
    '#E.......T#',
    '#.........#',
    '#....S....#',
    '#.........#',
    '###########',
  ], _Dir.right, 0),

  // Уровень 2
  _parseLevel([
    '###########',
    '#E........#',
    '#.........#',
    '#....S....#',
    '#.........T',
    '###########',
  ], _Dir.right, 1),

  // Уровень 3
  _parseLevel([
    '###########',
    '#E........#',
    '#.S.......#',
    '#.........#',
    '#.......S.#',
    '#.........T',
    '###########',
  ], _Dir.right, 2),

  // Уровень 4
  _parseLevel([
    '#####T#####',
    '#.........#',
    'E...S...S.#',
    '#.........#',
    '#.S.......#',
    '#.........#',
    '###########',
  ], _Dir.right, 3),

  // Уровень 5 — финальный
  _parseLevel([
    '###T#######',
    '#.........#',
    '#.S.......#',
    '#.........#',
    'E.....S...#',
    '#.........#',
    '#...S.....#',
    '#.........#',
    '###########',
  ], _Dir.right, 3),
];

// ─── Главный виджет ───────────────────────────────────────────────────────
class NeonRayGame extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const NeonRayGame({super.key, required this.onSuccess, required this.onFail});

  @override
  State<NeonRayGame> createState() => _NeonRayGameState();
}

class _NeonRayGameState extends State<NeonRayGame> with TickerProviderStateMixin {
  int _levelIdx = 0;
  late List<List<_Cell>> _cells;
  late Map<Offset, bool> _mirrors; // offset → true=45°, false=135°
  bool _won = false, _failed = false;
  int _moves = 0;
  int _timeLeft = 60;

  late AnimationController _winCtrl, _failCtrl, _glowCtrl, _entryCtrl;
  late Animation<double> _winScale, _failScale, _glowAnim, _entryAnim;

  @override
  void initState() {
    super.initState();
    _winCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _failCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();

    _winScale  = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _winCtrl,  curve: Curves.elasticOut));
    _failScale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _failCtrl, curve: Curves.easeOut));
    _glowAnim  = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _loadLevel();
    _startTimer();
  }

  @override
  void dispose() {
    _winCtrl.dispose(); _failCtrl.dispose();
    _glowCtrl.dispose(); _entryCtrl.dispose();
    super.dispose();
  }

  void _loadLevel() {
    final lv = _levels[_levelIdx];
    _cells = List.generate(lv.rows, (r) =>
        List.generate(lv.cols, (c) => _Cell(lv.grid[r][c])));
    _mirrors = {};
    _moves = 0;
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

  // ─── Трассировка луча ────────────────────────────────────────────────────
  List<Offset> _traceRay() {
    final lv = _levels[_levelIdx];
    final path = <Offset>[];
    var pos = lv.emitter;
    var dir = lv.emitDir;
    final visited = <String>{};

    path.add(pos);

    for (int step = 0; step < 200; step++) {
      final key = '${pos.dx},${pos.dy},$dir';
      if (visited.contains(key)) break;
      visited.add(key);

      final next = pos + _dirOffset(dir);
      final nx = next.dx.toInt(), ny = next.dy.toInt();
      if (ny < 0 || ny >= lv.rows || nx < 0 || nx >= lv.cols) break;

      final cell = _cells[ny][nx];
      path.add(next);

      if (cell.type == _CellType.wall) break;
      if (cell.type == _CellType.target) break;

      // Зеркало в этой ячейке
      final mirrorKey = Offset(nx.toDouble(), ny.toDouble());
      if (_mirrors.containsKey(mirrorKey)) {
        dir = _mirrors[mirrorKey]! ? _reflect45(dir) : _reflect135(dir);
      }

      pos = next;
    }
    return path;
  }

  bool _checkWin() {
    final lv = _levels[_levelIdx];
    final path = _traceRay();
    return path.isNotEmpty && path.last == lv.target;
  }

  // ─── Тап по слоту — поставить/убрать/повернуть зеркало ───────────────────
  void _onSlotTap(Offset slot) {
    if (_won || _failed) return;
    final lv = _levels[_levelIdx];
    if (!lv.mirrorSlots.contains(slot)) return;

    setState(() {
      if (!_mirrors.containsKey(slot)) {
        // Поставить 45°
        if (_mirrors.length < lv.mirrorsAvailable) {
          _mirrors[slot] = true;
          _moves++;
        }
      } else if (_mirrors[slot] == true) {
        // Повернуть на 135°
        _mirrors[slot] = false;
        _moves++;
      } else {
        // Убрать
        _mirrors.remove(slot);
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

    if (_levelIdx < _levels.length - 1) {
      // Следующий уровень
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _levelIdx++;
          _won = false;
          _timeLeft = 60;
          _loadLevel();
          _entryCtrl.forward(from: 0);
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

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: FadeTransition(
                  opacity: _entryAnim,
                  child: _buildGrid(),
                ),
              ),
              if (_won && _levelIdx == _levels.length - 1)
                _buildWinOverlay(),
              if (_failed)
                _buildFailOverlay(),
            ]),
          ),
          _buildControls(),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    final timeColor = _timeLeft > 30 ? kGreen : (_timeLeft > 10 ? Colors.orange : kRed);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      color: Colors.black,
      child: Row(children: [
        // Бейдж
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00F5FF), Color(0xFF0066FF)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: const Color(0xFF00F5FF).withOpacity(0.4), blurRadius: 10)],
          ),
          child: const Row(children: [
            Text('🔦', style: TextStyle(fontSize: 13)),
            SizedBox(width: 5),
            Text('Неоновый луч',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
        const Spacer(),
        // Уровень
        Text('Уровень ${_levelIdx + 1}/${_levels.length}',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(width: 14),
        // Ходы
        Text('Ходов: $_moves',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(width: 14),
        // Таймер
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: timeColor.withOpacity(_glowAnim.value), width: 2),
              shape: BoxShape.circle,
              color: timeColor.withOpacity(0.1),
            ),
            child: Center(child: Text('$_timeLeft',
                style: TextStyle(color: timeColor, fontSize: 13, fontWeight: FontWeight.w900))),
          ),
        ),
      ]),
    );
  }

  Widget _buildGrid() {
    final lv = _levels[_levelIdx];
    final rayPath = _traceRay();
    final raySet = <String>{};
    for (int i = 0; i < rayPath.length - 1; i++) {
      raySet.add('${rayPath[i].dx},${rayPath[i].dy}');
    }
    if (rayPath.isNotEmpty) raySet.add('${rayPath.last.dx},${rayPath.last.dy}');

    return LayoutBuilder(builder: (ctx, cst) {
      final cellSize = min(cst.maxWidth / lv.cols, cst.maxHeight / lv.rows);
      return Center(
        child: SizedBox(
          width: cellSize * lv.cols,
          height: cellSize * lv.rows,
          child: AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) => CustomPaint(
              painter: _GridPainter(
                cells: _cells,
                mirrors: _mirrors,
                rayPath: rayPath,
                glowValue: _glowAnim.value,
                cellSize: cellSize,
                mirrorSlots: lv.mirrorSlots,
                won: _won,
              ),
              child: Stack(
                children: lv.mirrorSlots.map((slot) => Positioned(
                  left: slot.dx * cellSize,
                  top: slot.dy * cellSize,
                  width: cellSize,
                  height: cellSize,
                  child: GestureDetector(
                    onTap: () => _onSlotTap(slot),
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                )).toList(),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildControls() {
    final lv = _levels[_levelIdx];
    final remaining = lv.mirrorsAvailable - _mirrors.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      color: Colors.black,
      child: Row(children: [
        // Иконка зеркала
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF00F5FF).withOpacity(0.4)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Text('🪞', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('×$remaining',
                style: const TextStyle(color: Color(0xFF00F5FF), fontSize: 14, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(
          remaining > 0
              ? 'Нажми на слот чтобы поставить зеркало\nНажми ещё раз — повернуть, ещё раз — убрать'
              : 'Все зеркала расставлены',
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4), height: 1.4),
        )),
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
            const Text('✨', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text('Путь найден!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Text('$_moves ходов • уровень ${_levelIdx + 1}',
                style: const TextStyle(color: Color(0xFF00F5FF), fontSize: 14)),
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
            const Text('Время вышло!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Пройдено уровней: $_levelIdx',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
          ],
        ))),
      ),
    );
  }
}

// ─── Painter для сетки ────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final List<List<_Cell>> cells;
  final Map<Offset, bool> mirrors;
  final List<Offset> rayPath;
  final double glowValue;
  final double cellSize;
  final List<Offset> mirrorSlots;
  final bool won;

  _GridPainter({
    required this.cells, required this.mirrors, required this.rayPath,
    required this.glowValue, required this.cellSize, required this.mirrorSlots,
    required this.won,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawCells(canvas);
    _drawRay(canvas);
    _drawMirrors(canvas);
    _drawSlotHints(canvas);
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF050A1E),
    );
    // Тонкая сетка
    final gridPaint = Paint()
      ..color = const Color(0xFF00F5FF).withOpacity(0.05)
      ..strokeWidth = 0.5;
    for (int r = 0; r < cells.length; r++) {
      for (int c = 0; c < cells[0].length; c++) {
        canvas.drawRect(
          Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
          gridPaint,
        );
      }
    }
  }

  void _drawCells(Canvas canvas) {
    for (int r = 0; r < cells.length; r++) {
      for (int c = 0; c < cells[r].length; c++) {
        final cell = cells[r][c];
        final rect = Rect.fromLTWH(c * cellSize + 2, r * cellSize + 2, cellSize - 4, cellSize - 4);

        switch (cell.type) {
          case _CellType.wall:
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, const Radius.circular(4)),
              Paint()..color = const Color(0xFF1A2040),
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, const Radius.circular(4)),
              Paint()..color = const Color(0xFF2E86AB).withOpacity(0.4)
                ..style = PaintingStyle.stroke..strokeWidth = 1,
            );

          case _CellType.emitter:
            // Источник — синий круг со свечением
            final center = Offset(c * cellSize + cellSize / 2, r * cellSize + cellSize / 2);
            canvas.drawCircle(center, cellSize * 0.3,
                Paint()..color = const Color(0xFF00F5FF).withOpacity(0.2 * glowValue)
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
            canvas.drawCircle(center, cellSize * 0.28,
                Paint()..color = const Color(0xFF00F5FF));
            final tp = TextPainter(
              text: const TextSpan(text: '⚡', style: TextStyle(fontSize: 14)),
              textDirection: TextDirection.ltr,
            )..layout();
            tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

          case _CellType.target:
            // Цель — золотой квадрат с пульсацией
            final center = Offset(c * cellSize + cellSize / 2, r * cellSize + cellSize / 2);
            final r2 = cellSize * 0.32 * glowValue;
            canvas.drawCircle(center, r2 + 6,
                Paint()..color = kGold.withOpacity(0.25)
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
            canvas.drawCircle(center, cellSize * 0.28,
                Paint()..color = kGold);
            final tp = TextPainter(
              text: const TextSpan(text: '🎯', style: TextStyle(fontSize: 14)),
              textDirection: TextDirection.ltr,
            )..layout();
            tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

          default: break;
        }
      }
    }
  }

  void _drawRay(Canvas canvas) {
    if (rayPath.length < 2) return;

    final rayColor = won ? kGold : const Color(0xFF00F5FF);

    for (int i = 0; i < rayPath.length - 1; i++) {
      final a = Offset(
        rayPath[i].dx * cellSize + cellSize / 2,
        rayPath[i].dy * cellSize + cellSize / 2,
      );
      final b = Offset(
        rayPath[i + 1].dx * cellSize + cellSize / 2,
        rayPath[i + 1].dy * cellSize + cellSize / 2,
      );

      // Свечение
      canvas.drawLine(a, b,
          Paint()..color = rayColor.withOpacity(0.25 * glowValue)
            ..strokeWidth = 12
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      // Основная линия
      canvas.drawLine(a, b,
          Paint()..color = rayColor.withOpacity(0.9)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round);
    }
  }

  void _drawMirrors(Canvas canvas) {
    mirrors.forEach((slot, is45) {
      final cx = slot.dx * cellSize + cellSize / 2;
      final cy = slot.dy * cellSize + cellSize / 2;
      final half = cellSize * 0.35;

      final paint = Paint()
        ..color = const Color(0xFFADD8FF)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      final glow = Paint()
        ..color = const Color(0xFF00F5FF).withOpacity(0.4)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      if (is45) {
        // \ зеркало
        canvas.drawLine(Offset(cx - half, cy + half), Offset(cx + half, cy - half), glow);
        canvas.drawLine(Offset(cx - half, cy + half), Offset(cx + half, cy - half), paint);
      } else {
        // / зеркало
        canvas.drawLine(Offset(cx - half, cy - half), Offset(cx + half, cy + half), glow);
        canvas.drawLine(Offset(cx - half, cy - half), Offset(cx + half, cy + half), paint);
      }
    });
  }

  void _drawSlotHints(Canvas canvas) {
    for (final slot in mirrorSlots) {
      if (mirrors.containsKey(slot)) continue;
      final cx = slot.dx * cellSize + cellSize / 2;
      final cy = slot.dy * cellSize + cellSize / 2;
      canvas.drawCircle(Offset(cx, cy), 4,
          Paint()..color = const Color(0xFF00F5FF).withOpacity(0.25));
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => true;
}
