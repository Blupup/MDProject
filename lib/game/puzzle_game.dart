// lib/game/puzzle_game.dart
//
// ═══════════════════════════════════════════════════════════════════════════
//  ИГРА «ПЯТНАШКИ» — собери картинку из кусочков
// ═══════════════════════════════════════════════════════════════════════════
//
//  📸 КАК ПОМЕНЯТЬ КАРТИНКУ:
//  1. Положи своё фото в папку assets/images/ (например: puzzle_photo.jpg)
//  2. Добавь в pubspec.yaml:
//       flutter:
//         assets:
//           - assets/images/puzzle_photo.jpg
//  3. В файле quest_data.dart в поле miniGameItems задания напиши путь:
//       miniGameItems: ['assets/images/puzzle_photo.jpg'],
//     (первый элемент списка — это путь к картинке)
//
//  Картинка автоматически нарежется на 12 частей (3×4).
//  Пустой слот — нижний правый угол.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

class PuzzleGame extends StatefulWidget {
  final List<String> items;     // items[0] — путь к картинке: 'assets/images/...'
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const PuzzleGame({
    super.key,
    required this.items,
    required this.onSuccess,
    required this.onFail,
  });

  @override
  State<PuzzleGame> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame> with TickerProviderStateMixin {
  // ─── Конфигурация пазла ───────────────────────────────────────────────────
  static const int _cols = 3;
  static const int _rows = 4;
  static const int _total = _cols * _rows;      // 12 частей
  static const int _empty = _total - 1;         // индекс «пустого» слота (12-й = правый нижний)

  // ─── Состояние ────────────────────────────────────────────────────────────
  late List<int> _tiles;        // _tiles[позиция] = оригинальный индекс куска (или -1 = пустой)
  int _moves = 0;
  int _timeLeft = 120;          // 2 минуты
  bool _won = false;
  bool _failed = false;

  // ─── Анимации ─────────────────────────────────────────────────────────────
  late AnimationController _winCtrl;
  late AnimationController _failCtrl;
  late AnimationController _shakeCtrl;
  late Animation<double> _winScale;
  late Animation<double> _failScale;
  late Animation<double> _shakeAnim;

  // Анимация перемещения тайла
  int? _movingTile;
  int? _movingFrom;

  late final String _imagePath;

  @override
  void initState() {
    super.initState();

    // Путь к картинке берётся из первого элемента miniGameItems
    // Если не указан — используем дефолтный цветной пазл
    _imagePath = widget.items.isNotEmpty ? widget.items.first : '';

    _winCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _failCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _winScale  = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _winCtrl, curve: Curves.elasticOut));
    _failScale = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _failCtrl, curve: Curves.easeOut));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);

    _shuffle();
    _startTimer();
  }

  @override
  void dispose() {
    _winCtrl.dispose();
    _failCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ─── Инициализация и перемешивание ────────────────────────────────────────
  void _shuffle() {
    // Создаём решённый порядок: [0, 1, 2, ..., 11, -1]
    _tiles = List.generate(_total - 1, (i) => i)..add(-1);

    // Перемешиваем через случайные ходы (гарантированно решаемо)
    final rng = Random();
    int emptyPos = _total - 1;
    for (int i = 0; i < 200; i++) {
      final neighbors = _getMovable(emptyPos);
      final pick = neighbors[rng.nextInt(neighbors.length)];
      // Меняем местами
      _tiles[emptyPos] = _tiles[pick];
      _tiles[pick] = -1;
      emptyPos = pick;
    }
    // Убеждаемся что не решено сразу
    if (_isSolved()) _shuffle();
  }

  // Получить позиции соседей пустого слота
  List<int> _getMovable(int emptyPos) {
    final row = emptyPos ~/ _cols;
    final col = emptyPos % _cols;
    final moves = <int>[];
    if (row > 0)         moves.add(emptyPos - _cols); // сверху
    if (row < _rows - 1) moves.add(emptyPos + _cols); // снизу
    if (col > 0)         moves.add(emptyPos - 1);     // слева
    if (col < _cols - 1) moves.add(emptyPos + 1);     // справа
    return moves;
  }

  bool _isSolved() {
    for (int i = 0; i < _total - 1; i++) {
      if (_tiles[i] != i) return false;
    }
    return _tiles[_total - 1] == -1;
  }

  // ─── Таймер ───────────────────────────────────────────────────────────────
  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _won || _failed) return false;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        _triggerFail();
        return false;
      }
      return true;
    });
  }

  // ─── Ход игрока ───────────────────────────────────────────────────────────
  void _onTileTap(int tilePos) {
    if (_won || _failed) return;
    final emptyPos = _tiles.indexOf(-1);

    // Проверяем, можно ли сдвинуть этот тайл
    final movable = _getMovable(emptyPos);
    if (!movable.contains(tilePos)) {
      // Нельзя — тряска
      _shakeCtrl.forward(from: 0);
      HapticFeedback.lightImpact();
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _tiles[emptyPos] = _tiles[tilePos];
      _tiles[tilePos] = -1;
      _moves++;
    });

    if (_isSolved()) _triggerWin();
  }

  void _triggerWin() {
    setState(() => _won = true);
    HapticFeedback.heavyImpact();
    _winCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2800), widget.onSuccess);
  }

  void _triggerFail() {
    setState(() => _failed = true);
    _failCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2500), widget.onFail);
  }

  // ─── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Stack(children: [
          const BgCircle(top: -60, left: -40, size: 180, color: kBlue, opacity: 0.18),
          const BgCircle(top: 320, left: 200, size: 150, color: Color(0xFF6A11CB), opacity: 0.12),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (_won)
                Expanded(child: _winScreen())
              else if (_failed)
                Expanded(child: _failScreen())
              else
                Expanded(child: _buildPuzzle()),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    final timeColor = _timeLeft > 60 ? kGreen : (_timeLeft > 30 ? Colors.orange : kRed);
    final mins = _timeLeft ~/ 60;
    final secs = _timeLeft % 60;
    final timeStr = '$mins:${secs.toString().padLeft(2, '0')}';

    return Row(children: [
      // Бейдж игры
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF2E86AB)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: kBlue.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Row(children: [
          Icon(Icons.grid_view_rounded, color: Colors.white, size: 15),
          SizedBox(width: 6),
          Text('Пятнашки', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      ),
      const Spacer(),
      // Ходы
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text('👣 $_moves',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
      const SizedBox(width: 10),
      // Таймер
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: timeColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: timeColor.withOpacity(0.5)),
        ),
        child: Row(children: [
          Icon(Icons.timer_rounded, color: timeColor, size: 14),
          const SizedBox(width: 5),
          Text(timeStr, style: TextStyle(color: timeColor, fontWeight: FontWeight.w900, fontSize: 14)),
        ]),
      ),
    ]);
  }

  Widget _buildPuzzle() {
    return Column(children: [
      // Подсказка
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: kBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBlue.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.touch_app_rounded, color: kGreen, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(
            'Нажимай на кусочек рядом с пустым местом — он сдвинется туда',
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
          )),
        ]),
      ),
      // Сетка пазла
      Expanded(child: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(_shakeAnim.value, 0),
          child: child,
        ),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final tileW = constraints.maxWidth / _cols;
            final tileH = constraints.maxHeight / _rows;

            return Stack(
              children: List.generate(_total, (pos) {
                final tileIndex = _tiles[pos];
                final isEmpty = tileIndex == -1;
                final row = pos ~/ _cols;
                final col = pos % _cols;

                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  left: col * tileW,
                  top: row * tileH,
                  width: tileW,
                  height: tileH,
                  child: GestureDetector(
                    onTap: isEmpty ? null : () => _onTileTap(pos),
                    child: AnimatedOpacity(
                      opacity: isEmpty ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: isEmpty
                          ? _emptySlot(tileW, tileH)
                          : _tile(tileIndex, tileW, tileH),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      )),
    ]);
  }

  Widget _tile(int tileIndex, double w, double h) {
    final origRow = tileIndex ~/ _cols;
    final origCol = tileIndex % _cols;

    // Проверяем стоит ли тайл на своём месте
    final currentPos = _tiles.indexOf(tileIndex);
    final isCorrect = currentPos == tileIndex;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(children: [
          // ── Картинка (кусочек) ──────────────────────────────────────────
          if (_imagePath.isNotEmpty)
            _TileImage(
              imagePath: _imagePath,
              tileCol: origCol,
              tileRow: origRow,
              cols: _cols,
              rows: _rows,
              width: w - 4,
              height: h - 4,
            )
          else
            // Цветной заменитель если картинки нет
            Container(
              width: w - 4, height: h - 4,
              color: HSLColor.fromAHSL(1, (tileIndex / _total) * 240, 0.6, 0.4).toColor(),
              child: Center(child: Text(
                '${tileIndex + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
              )),
            ),

          // ── Рамка правильного положения ─────────────────────────────────
          if (isCorrect)
            Positioned.fill(child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: kGreen, width: 2.5),
                borderRadius: BorderRadius.circular(6),
              ),
            )),

          // ── Номер тайла (маленький) ─────────────────────────────────────
          Positioned(top: 4, left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text('${tileIndex + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _emptySlot(double w, double h) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: kBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBlue.withOpacity(0.3), style: BorderStyle.solid, width: 2),
        ),
        child: Center(child: Icon(
          Icons.arrow_back_rounded,
          color: kBlue.withOpacity(0.3),
          size: 20,
        )),
      ),
    );
  }

  // ─── Экраны результата ────────────────────────────────────────────────────
  Widget _winScreen() {
    return ScaleTransition(
      scale: _winScale,
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 110, height: 110,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kBlue, kGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: kBlue.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 60)),
        const SizedBox(height: 24),
        const Text('Картинка собрана!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kGold, Color(0xFFFFA726)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: kGold.withOpacity(0.4), blurRadius: 16)],
          ),
          child: Text('+${_timeLeft * 2 + 50} очков',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 12),
        Text('За $_moves ходов 🧩', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15)),
      ])),
    );
  }

  Widget _failScreen() {
    return ScaleTransition(
      scale: _failScale,
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 110, height: 110,
          decoration: BoxDecoration(
            color: kRed.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: kRed, width: 3),
            boxShadow: [BoxShadow(color: kRed.withOpacity(0.3), blurRadius: 20)],
          ),
          child: const Icon(Icons.timer_off_rounded, color: kRed, size: 55)),
        const SizedBox(height: 24),
        const Text('Время вышло!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 10),
        Text('Сделано $_moves ходов', style: const TextStyle(fontSize: 16, color: kGreen, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Попробуй ещё раз! 🧩', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14)),
      ])),
    );
  }
}

// ─── Виджет: вырезает нужный кусочек картинки через ClipRect ──────────────
class _TileImage extends StatelessWidget {
  final String imagePath;
  final int tileCol, tileRow, cols, rows;
  final double width, height;

  const _TileImage({
    required this.imagePath,
    required this.tileCol,
    required this.tileRow,
    required this.cols,
    required this.rows,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        maxWidth: width * cols,
        maxHeight: height * rows,
        alignment: Alignment(
          // Выравниваем картинку так чтобы показывался нужный кусочек
          -1 + (tileCol * 2 / (cols - 1)),
          -1 + (tileRow * 2 / (rows - 1)),
        ),
        child: SizedBox(
          width: width * cols,
          height: height * rows,
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: HSLColor.fromAHSL(
                1,
                ((tileRow * cols + tileCol) / (cols * rows)) * 240,
                0.55, 0.38,
              ).toColor(),
              child: Center(child: Text(
                '${tileRow * cols + tileCol + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
              )),
            ),
          ),
        ),
      ),
    );
  }
}
