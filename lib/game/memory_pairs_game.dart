// lib/game/memory_pairs_game.dart
//
// Игра «Найди пары» — переворачивай карточки и ищи одинаковые пары.
// Получается очень просто в использовании:
//   MemoryPairsGame(items: task.miniGameItems, onSuccess: ..., onFail: ...)
//
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

class MemoryPairsGame extends StatefulWidget {
  final List<String> items;   // Список уникальных слов (нужно 4–6 штук)
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const MemoryPairsGame({
    super.key,
    required this.items,
    required this.onSuccess,
    required this.onFail,
  });

  @override
  State<MemoryPairsGame> createState() => _MemoryPairsGameState();
}

// ─── Одна карточка на доске ───────────────────────────────────────────────
class _Card {
  final int id;         // уникальный ID (две карточки с одним pairId = пара)
  final int pairId;
  final String label;
  bool isFlipped = false;
  bool isMatched = false;

  _Card({required this.id, required this.pairId, required this.label});
}

class _MemoryPairsGameState extends State<MemoryPairsGame>
    with TickerProviderStateMixin {
  // ─── Доска ────────────────────────────────────────────────────────────────
  late List<_Card> _cards;
  _Card? _firstFlipped;
  bool _checking = false;

  // ─── Состояние игры ───────────────────────────────────────────────────────
  int _moves = 0;
  int _matchesFound = 0;
  int _timeLeft = 60;
  int _lives = 3;
  Timer? _timer;
  bool _gameOver = false;
  bool _gameWon = false;

  // ─── Анимации ─────────────────────────────────────────────────────────────
  late List<AnimationController> _flipCtrls;   // flip per card
  late List<Animation<double>> _flipAnims;
  late AnimationController _successCtrl;
  late AnimationController _failCtrl;
  late Animation<double> _successScale;
  late Animation<double> _failScale;

  @override
  void initState() {
    super.initState();
    _buildBoard();

    // Flip controllers — по одному на каждую карточку
    _flipCtrls = List.generate(
      _cards.length,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 400)),
    );
    _flipAnims = _flipCtrls
        .map((c) => Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _failCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _successScale = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
    _failScale = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _failCtrl, curve: Curves.easeOut));

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _flipCtrls) {
      c.dispose();
    }
    _successCtrl.dispose();
    _failCtrl.dispose();
    super.dispose();
  }

  // ─── Построение доски ────────────────────────────────────────────────────
  void _buildBoard() {
    // Берём максимум 6 слов, создаём по 2 карточки на каждое
    final words = widget.items.take(6).toList();
    final pairs = <_Card>[];
    for (int i = 0; i < words.length; i++) {
      pairs.add(_Card(id: i * 2,     pairId: i, label: words[i]));
      pairs.add(_Card(id: i * 2 + 1, pairId: i, label: words[i]));
    }
    pairs.shuffle(Random());
    _cards = pairs;
  }

  // ─── Таймер ───────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        _triggerFail();
      }
    });
  }

  // ─── Нажатие на карточку ─────────────────────────────────────────────────
  void _onCardTap(int index) {
    if (_checking || _gameOver || _gameWon) return;
    final card = _cards[index];
    if (card.isFlipped || card.isMatched) return;

    HapticFeedback.lightImpact();

    // Переворачиваем карточку анимацией
    _flipCtrls[index].forward();
    setState(() => card.isFlipped = true);

    if (_firstFlipped == null) {
      // Первая выбранная карточка
      _firstFlipped = card;
    } else {
      // Вторая — проверяем совпадение
      _moves++;
      _checking = true;

      if (_firstFlipped!.pairId == card.pairId) {
        // Совпадение!
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _firstFlipped!.isMatched = true;
            card.isMatched = true;
            _matchesFound++;
            _firstFlipped = null;
            _checking = false;
          });
          if (_matchesFound == _cards.length ~/ 2) {
            _triggerWin();
          }
        });
      } else {
        // Не совпадение — переворачиваем обратно
        HapticFeedback.vibrate();
        final firstIndex = _cards.indexOf(_firstFlipped!);
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          _flipCtrls[firstIndex].reverse();
          _flipCtrls[index].reverse();
          setState(() {
            _firstFlipped!.isFlipped = false;
            card.isFlipped = false;
            _firstFlipped = null;
            _checking = false;
          });
          _lives--;
          if (_lives <= 0) _triggerFail();
        });
      }
    }
  }

  void _triggerWin() {
    _timer?.cancel();
    setState(() => _gameWon = true);
    HapticFeedback.heavyImpact();
    _successCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2500), widget.onSuccess);
  }

  void _triggerFail() {
    _timer?.cancel();
    setState(() => _gameOver = true);
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
          const BgCircle(top: -50, left: -30, size: 160, color: kGreen, opacity: 0.15),
          const BgCircle(top: 320, left: 220, size: 130, color: kGold, opacity: 0.1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(children: [
              _buildHeader(),
              const SizedBox(height: 18),
              if (_gameWon)
                Expanded(child: _winScreen())
              else if (_gameOver)
                Expanded(child: _failScreen())
              else ...[
                _buildStatusBar(),
                const SizedBox(height: 18),
                Expanded(child: _buildGrid()),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    final timeColor = _timeLeft > 20 ? kGreen : (_timeLeft > 10 ? Colors.orange : kRed);
    return Row(children: [
      // Бейдж игры
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF00796B), Color(0xFF00D4AA)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: kGreen.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Row(children: [
          Icon(Icons.flip_rounded, color: Colors.white, size: 15),
          SizedBox(width: 6),
          Text('Найди пары', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      ),
      const Spacer(),
      // Жизни
      Row(children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.only(left: 5),
        child: Icon(
          i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: i < _lives ? kRed : Colors.white.withOpacity(0.2),
          size: 22,
        ),
      ))),
      const SizedBox(width: 10),
      // Таймер
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          border: Border.all(color: timeColor, width: 2.5),
          shape: BoxShape.circle,
          color: timeColor.withOpacity(0.1),
        ),
        child: Center(child: Text('$_timeLeft',
            style: TextStyle(color: timeColor, fontSize: 14, fontWeight: FontWeight.w900))),
      ),
    ]);
  }

  Widget _buildStatusBar() {
    return Row(children: [
      _statChip('🎯 Ходы', '$_moves', kBlue),
      const SizedBox(width: 10),
      _statChip('✅ Пары', '$_matchesFound / ${_cards.length ~/ 2}', kGreen),
      const Spacer(),
      // Прогресс-бар пар
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _matchesFound / (_cards.length ~/ 2),
          minHeight: 8,
          backgroundColor: Colors.white.withOpacity(0.08),
          valueColor: const AlwaysStoppedAnimation<Color>(kGreen),
        ),
      )),
    ]);
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text('$label: $value',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildGrid() {
    // 4 колонки если карточек 12, иначе 3
    final crossCount = _cards.length > 8 ? 4 : 3;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: _cards.length,
      itemBuilder: (_, i) => _buildCard(i),
    );
  }

  Widget _buildCard(int index) {
    final card = _cards[index];

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedBuilder(
        animation: _flipAnims[index],
        builder: (_, __) {
          final angle = _flipAnims[index].value * pi;
          final isShowingFront = angle < pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isShowingFront
                ? _cardBack(card.isMatched)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _cardFront(card),
                  ),
          );
        },
      ),
    );
  }

  Widget _cardBack(bool isMatched) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMatched
              ? [const Color(0xFF1B5E20), const Color(0xFF388E3C)]
              : [const Color(0xFF1E3A5F), const Color(0xFF0D1F3C)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMatched ? kGreen.withOpacity(0.7) : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: isMatched
            ? [BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 10)]
            : null,
      ),
      child: Center(
        child: isMatched
            ? const Icon(Icons.check_rounded, color: kGreen, size: 28)
            : Icon(Icons.help_outline_rounded, color: Colors.white.withOpacity(0.2), size: 28),
      ),
    );
  }

  Widget _cardFront(_Card card) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E86AB), Color(0xFF00D4AA)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: kGreen.withOpacity(0.35), blurRadius: 10)],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            card.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // ─── Экраны результата ────────────────────────────────────────────────────
  Widget _winScreen() {
    return ScaleTransition(
      scale: _successScale,
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 110, height: 110,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kGreen, Color(0xFF00A896)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: kGreen.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 60)),
        const SizedBox(height: 24),
        const Text('Все пары найдены!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kGold, Color(0xFFFFA726)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: kGold.withOpacity(0.4), blurRadius: 16)],
          ),
          child: Text('+${_timeLeft * 5 + _matchesFound * 20} очков',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 12),
        Text('За $_moves ходов, $timeDesc',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15)),
      ])),
    );
  }

  String get timeDesc {
    final elapsed = 60 - _timeLeft;
    return elapsed < 60 ? 'за $elapsedс' : '${elapsed ~/ 60}м ${elapsed % 60}с';
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
          child: const Icon(Icons.close_rounded, color: kRed, size: 60)),
        const SizedBox(height: 24),
        const Text('Время вышло!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 10),
        Text('Найдено $_matchesFound из ${_cards.length ~/ 2} пар',
            style: const TextStyle(fontSize: 16, color: kGreen, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Попробуй ещё раз! 💪',
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14)),
      ])),
    );
  }
}