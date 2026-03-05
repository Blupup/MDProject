// lib/game/memory_pairs_game.dart
// ═══════════════════════════════════════════════════════════════════════════

//  ИГРА «НАЙДИ ПАРЫ» — переворачивай карточки с фотографиями

// ═══════════════════════════════════════════════════════════════════════════

//

//  📸 КАК ДОБАВИТЬ СВОИ ФОТОГРАФИИ:

//  1. Положи фото в папку assets/images/

//     Нужно чётное кол-во: 4, 6 или 8 фото.

//     Каждое фото = одна пара (две одинаковые карточки).

//  2. Добавь в pubspec.yaml:

//       flutter:

//         assets:

//           - assets/images/pairs_photo1.jpg

//           - assets/images/pairs_photo2.jpg

//           ...

//  3. В quest_data.dart в поле miniGameItems укажи пути к фото:

//       miniGameItems: [

//         'assets/images/pairs_photo1.jpg',

//         'assets/images/pairs_photo2.jpg',

//         'assets/images/pairs_photo3.jpg',

//         'assets/images/pairs_photo4.jpg',

//       ],

//

//  Игра автоматически сделает по 2 карточки для каждого фото.

//  Если фото не найдено — карточка покажет цветной прямоугольник

//  с номером (это нормально для тестирования).

// ═══════════════════════════════════════════════════════════════════════════
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

class MemoryPairsGame extends StatefulWidget {
  final List<String> items;   // Пути к фото: ['assets/images/photo1.jpg', ...]
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
  final int id;
  final int pairId;
  final String imagePath;   // путь к фото
  bool isFlipped = false;
  bool isMatched = false;

  _Card({required this.id, required this.pairId, required this.imagePath});
}

class _MemoryPairsGameState extends State<MemoryPairsGame>
    with TickerProviderStateMixin {
  late List<_Card> _cards;
  _Card? _firstFlipped;
  bool _checking = false;

  int _moves = 0;
  int _matchesFound = 0;
  int _timeLeft = 180;  
  Timer? _timer;
  bool _gameOver = false;
  bool _gameWon  = false;

  late List<AnimationController> _flipCtrls;
  late List<Animation<double>> _flipAnims;
  late AnimationController _successCtrl;
  late AnimationController _failCtrl;
  late Animation<double> _successScale;
  late Animation<double> _failScale;

  @override
  void initState() {
    super.initState();
    _buildBoard();

    _flipCtrls = List.generate(
      _cards.length,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 450)),
    );
    _flipAnims = _flipCtrls.map((c) =>
      Tween<double>(begin: 0, end: 1)
          .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))
    ).toList();

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

  void _buildBoard() {
    final photos = widget.items.take(6).toList();
    if (photos.isEmpty) {
      final fakePhotos = List.generate(4, (i) => 'placeholder_$i');
      _buildFromList(fakePhotos);
    } else {
      _buildFromList(photos);
    }
  }

  void _buildFromList(List<String> photos) {
    final pairs = <_Card>[];
    for (int i = 0; i < photos.length; i++) {
      pairs.add(_Card(id: i * 2,     pairId: i, imagePath: photos[i]));
      pairs.add(_Card(id: i * 2 + 1, pairId: i, imagePath: photos[i]));
    }
    pairs.shuffle(Random());
    _cards = pairs;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) { t.cancel(); _triggerFail(); }
    });
  }

  void _onCardTap(int index) {
    if (_checking || _gameOver || _gameWon) return;
    final card = _cards[index];
    if (card.isFlipped || card.isMatched) return;

    HapticFeedback.lightImpact();
    _flipCtrls[index].forward();
    setState(() => card.isFlipped = true);

    if (_firstFlipped == null) {
      _firstFlipped = card;
    } else {
      _moves++;
      _checking = true;

      if (_firstFlipped!.pairId == card.pairId) {
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() {
            _firstFlipped!.isMatched = true;
            card.isMatched = true;
            _matchesFound++;
            _firstFlipped = null;
            _checking = false;
          });
          if (_matchesFound == _cards.length ~/ 2) _triggerWin();
        });
      } else {
        HapticFeedback.vibrate();
        final firstIdx = _cards.indexOf(_firstFlipped!);
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!mounted) return;
          _flipCtrls[firstIdx].reverse();
          _flipCtrls[index].reverse();
          setState(() {
            _firstFlipped!.isFlipped = false;
            card.isFlipped = false;
            _firstFlipped = null;
            _checking = false;
            // Убрали уменьшение жизней (_lives--)
          });
          // Убрали проверку на проигрыш по жизням
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
              const SizedBox(height: 16),
              if (_gameWon)
                Expanded(child: _winScreen())
              else if (_gameOver)
                Expanded(child: _failScreen())
              else ...[
                _buildStatusBar(),
                const SizedBox(height: 16),
                Expanded(child: _buildGrid()),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    final timeColor = _timeLeft > 30 ? kGreen : (_timeLeft > 15 ? Colors.orange : kRed);
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF00796B), Color(0xFF00D4AA)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: kGreen.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Row(children: [
          Icon(Icons.photo_library_rounded, color: Colors.white, size: 15),
          SizedBox(width: 6),
          Text('Найди пары', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      ),
      const Spacer(),
      // Убрали отрисовку сердечек (жизней)
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
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
      _statChip('✅ Пары', '$_matchesFound/${_cards.length ~/ 2}', kGreen),
      const SizedBox(width: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text('$label: $value',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildGrid() {
    final crossCount = _cards.length > 8 ? 4 : 3;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: _cards.length,
      itemBuilder: (_, i) => _buildCard(i),
    );
  }

  Widget _buildCard(int index) {
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedBuilder(
        animation: _flipAnims[index],
        builder: (_, __) {
          final angle = _flipAnims[index].value * pi;
          final showFront = angle > pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _cardFront(_cards[index]),
                  )
                : _cardBack(_cards[index].isMatched),
          );
        },
      ),
    );
  }

  Widget _cardBack(bool matched) {
    return Container(
      decoration: BoxDecoration(
        gradient: matched
            ? const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : const LinearGradient(colors: [Color(0xFF1E3A5F), Color(0xFF0D1F3C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: matched ? kGreen.withOpacity(0.7) : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: matched
            ? [BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 10)]
            : null,
      ),
      child: Center(child: matched
          ? const Icon(Icons.check_rounded, color: kGreen, size: 32)
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.photo_rounded, color: Colors.white.withOpacity(0.15), size: 28),
              const SizedBox(height: 4),
              Text('?', style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 18, fontWeight: FontWeight.w900)),
            ]),
      ),
    );
  }

  Widget _cardFront(_Card card) {
    final isPlaceholder = card.imagePath.startsWith('placeholder_');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGreen.withOpacity(0.6), width: 2),
        boxShadow: [BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 12)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: isPlaceholder
            ? Container(
                color: HSLColor.fromAHSL(1, (card.pairId / 8) * 280, 0.55, 0.38).toColor(),
                child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(['🌟', '🎯', '🔑', '💎', '🏆', '🎪'][card.pairId % 6],
                      style: const TextStyle(fontSize: 30)),
                  const SizedBox(height: 4),
                  Text('Фото ${card.pairId + 1}',
                      style: const TextStyle(color: Colors.white60, fontSize: 10)),
                ])),
              )
            : Image.asset(
                card.imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: HSLColor.fromAHSL(1, (card.pairId / 8) * 280, 0.55, 0.38).toColor(),
                  child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.broken_image_rounded, color: Colors.white38, size: 28),
                    const SizedBox(height: 4),
                    Text('Фото\n${card.pairId + 1}',
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                        textAlign: TextAlign.center),
                  ])),
                ),
              ),
      ),
    );
  }

  Widget _winScreen() {
    return ScaleTransition(
      scale: _successScale,
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 110, height: 110,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kGreen, Color(0xFF00A896)]),
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
        Text('За $_moves ходов 🃏', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15)),
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
          child: const Icon(Icons.close_rounded, color: kRed, size: 60)),
        const SizedBox(height: 24),
        const Text('Не получилось!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
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