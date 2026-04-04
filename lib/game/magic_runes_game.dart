// lib/game/magic_runes_game.dart
//
// «Магические руны» — найди пары рун на каменных табличках.
// Проклятые руны переворачивают другие карточки!
// Квест 1 «Посвящение»
//
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

// ─── Данные руны ──────────────────────────────────────────────────────────
class _Rune {
  final String symbol;
  final Color color;
  final bool isCursed; // проклятая руна

  const _Rune(this.symbol, this.color, {this.isCursed = false});
}

// Набор рун (символы + цвета)
const _runeSet = [
  _Rune('ᚠ', Color(0xFF00D4AA)),
  _Rune('ᚢ', Color(0xFF2E86AB)),
  _Rune('ᚦ', Color(0xFF9C27B0)),
  _Rune('ᚨ', Color(0xFFFF6B35)),
  _Rune('ᚱ', Color(0xFF4CAF50)),
  _Rune('ᚲ', Color(0xFFE91E63)),
  _Rune('ᚷ', Color(0xFF00BCD4)),
  _Rune('ᚹ', Color(0xFFFF9800)),
  // Проклятые
  _Rune('☠', Color(0xFF8B0000), isCursed: true),
  _Rune('⚡', Color(0xFF4A0080), isCursed: true),
];

// ─── Карточка ─────────────────────────────────────────────────────────────
class _Card {
  final int id;         // уникальный ID
  final int pairId;     // ID пары (одинаковый у двух карточек)
  final _Rune rune;
  bool isFlipped   = false;  // лицом вверх
  bool isMatched   = false;  // совпала — убрана
  bool isCursing   = false;  // анимация проклятия
  double flipAngle = 0;      // 0 = рубашка, π = лицо

  _Card({required this.id, required this.pairId, required this.rune});
}

// ─── Главный виджет ───────────────────────────────────────────────────────
class MagicRunesGame extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const MagicRunesGame({super.key, required this.onSuccess, required this.onFail});

  @override
  State<MagicRunesGame> createState() => _MagicRunesGameState();
}

class _MagicRunesGameState extends State<MagicRunesGame> with TickerProviderStateMixin {
  static const _cols = 4;
  static const _rows = 4; // 16 карточек = 6 пар + 2 проклятых пары

  late List<_Card> _cards;
  final List<int> _flipped = []; // индексы перевёрнутых (макс 2)
  bool _locked = false;          // блокировка во время анимации
  int _timeLeft = 60;
  int _lives = 3;
  int _matched = 0;
  bool _won = false, _failed = false;

  // Анимации переворота карточек
  late List<AnimationController> _flipCtrls;
  late List<Animation<double>> _flipAnims;

  // Общие контроллеры
  late AnimationController _winCtrl, _failCtrl, _glowCtrl;
  late Animation<double> _winScale, _failScale, _glowAnim;

  // Частицы золота при совпадении
  final List<_GoldParticle> _particles = [];
  late AnimationController _particleCtrl;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _winCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _failCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _glowCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..addListener(() => setState(() {}));

    _winScale  = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _winCtrl,  curve: Curves.elasticOut));
    _failScale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _failCtrl, curve: Curves.easeOut));
    _glowAnim  = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _buildDeck();
    _startTimer();
  }

  @override
  void dispose() {
    for (final c in _flipCtrls) c.dispose();
    _winCtrl.dispose(); _failCtrl.dispose();
    _glowCtrl.dispose(); _particleCtrl.dispose();
    super.dispose();
  }

  void _buildDeck() {
    // 6 обычных пар + 2 проклятые пары = 16 карточек
    final List<_Rune> runes = [];
    for (int i = 0; i < 6; i++) runes.add(_runeSet[i]);
    runes.add(_runeSet[8]); // проклятая
    runes.add(_runeSet[9]); // проклятая

    final List<_Card> deck = [];
    int id = 0;
    for (int p = 0; p < runes.length; p++) {
      deck.add(_Card(id: id++, pairId: p, rune: runes[p]));
      deck.add(_Card(id: id++, pairId: p, rune: runes[p]));
    }
    deck.shuffle(_rng);
    _cards = deck;

    // Контроллеры переворота
    _flipCtrls = List.generate(_cards.length, (_) =>
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400)));
    _flipAnims = _flipCtrls.map((c) =>
        Tween(begin: 0.0, end: pi).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))
    ).toList();
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

  // ─── Тап по карточке ──────────────────────────────────────────────────────
  void _onTap(int idx) {
    if (_locked || _won || _failed) return;
    final card = _cards[idx];
    if (card.isFlipped || card.isMatched) return;

    HapticFeedback.selectionClick();

    setState(() => card.isFlipped = true);
    _flipCtrls[idx].forward();
    _flipped.add(idx);

    if (_flipped.length == 2) {
      _locked = true;
      _checkMatch();
    }
  }

  Future<void> _checkMatch() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final a = _cards[_flipped[0]];
    final b = _cards[_flipped[1]];

    if (a.pairId == b.pairId) {
      // Совпадение!
      HapticFeedback.heavyImpact();
      setState(() { a.isMatched = true; b.isMatched = true; _matched += 2; });
      _spawnGold(_flipped[0]);
      _spawnGold(_flipped[1]);
      _particleCtrl.forward(from: 0);

      if (_matched == _cards.length) _triggerWin();
    } else {
      // Не совпало
      // Проверяем — открыта ли проклятая руна?
      if (a.rune.isCursed || b.rune.isCursed) {
        _triggerCurse();
      }
      setState(() {
        _lives--;
        a.isFlipped = false;
        b.isFlipped = false;
      });
      _flipCtrls[_flipped[0]].reverse();
      _flipCtrls[_flipped[1]].reverse();
      if (_lives <= 0) { _triggerFail(); }
    }

    _flipped.clear();
    if (mounted) setState(() => _locked = false);
  }

  // Проклятие — переворачивает 2 случайные совпавшие карты обратно
  void _triggerCurse() {
    HapticFeedback.mediumImpact();
    final matched = _cards.where((c) => c.isMatched).toList();
    if (matched.length < 2) return;
    matched.shuffle(_rng);
    final victims = matched.take(2).toList();
    setState(() {
      for (final v in victims) {
        v.isMatched = false;
        v.isFlipped = false;
        v.isCursing = true;
        _matched -= 1;
      }
    });
    for (final v in victims) {
      final idx = _cards.indexOf(v);
      _flipCtrls[idx].reverse();
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => v.isCursing = false);
      });
    }
  }

  void _spawnGold(int idx) {
    // Позиция карточки (приблизительная) — заполним при первой отрисовке
    for (int i = 0; i < 18; i++) {
      _particles.add(_GoldParticle(
        col: idx % _cols,
        row: idx ~/ _cols,
        vx: (_rng.nextDouble() - 0.5) * 4,
        vy: -2 - _rng.nextDouble() * 3,
      ));
    }
  }

  void _triggerWin() {
    if (_won) return;
    setState(() => _won = true);
    HapticFeedback.heavyImpact();
    _winCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2400), () { if (mounted) widget.onSuccess(); });
  }

  void _triggerFail() {
    if (_failed) return;
    setState(() => _failed = true);
    _failCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2400), () { if (mounted) widget.onFail(); });
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0A1A),
      body: SafeArea(child: Column(children: [
        _buildHeader(),
        Expanded(child: Stack(children: [
          Padding(padding: const EdgeInsets.all(12), child: _buildGrid()),
          _buildParticles(),
          if (_won)  _buildOverlay(true),
          if (_failed) _buildOverlay(false),
        ])),
      ])),
    );
  }

  Widget _buildHeader() {
    final tc = _timeLeft > 30 ? const Color(0xFF00D4AA) : (_timeLeft > 10 ? Colors.orange : kRed);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A0A30), const Color(0xFF0D0A1A)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: Row(children: [
        // Бейдж
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6A0DAD), Color(0xFFAA00FF)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: const Color(0xFFAA00FF).withOpacity(0.5), blurRadius: 12)],
          ),
          child: const Row(children: [
            Text('🔮', style: TextStyle(fontSize: 13)),
            SizedBox(width: 5),
            Text('Магические руны',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
        const Spacer(),
        // Жизни
        Row(children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(
            i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: i < _lives ? kRed : Colors.white12, size: 20,
          ),
        ))),
        const SizedBox(width: 12),
        // Прогресс
        Text('${_matched ~/ 2}/${_cards.length ~/ 2}',
            style: const TextStyle(color: Color(0xFFDAA520), fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(width: 12),
        // Таймер
        AnimatedBuilder(animation: _glowAnim, builder: (_, __) =>
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              border: Border.all(color: tc.withOpacity(_glowAnim.value), width: 2),
              shape: BoxShape.circle,
              color: tc.withOpacity(0.1),
            ),
            child: Center(child: Text('$_timeLeft',
                style: TextStyle(color: tc, fontSize: 13, fontWeight: FontWeight.w900))),
          ),
        ),
      ]),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _cols,
        crossAxisSpacing: 8, mainAxisSpacing: 8,
      ),
      itemCount: _cards.length,
      itemBuilder: (_, i) => _buildCard(i),
    );
  }

  Widget _buildCard(int idx) {
    final card = _cards[idx];

    return GestureDetector(
      onTap: () => _onTap(idx),
      child: AnimatedBuilder(
        animation: _flipAnims[idx],
        builder: (_, __) {
          final angle = _flipAnims[idx].value;
          final showFace = angle > pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showFace
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildFace(card),
                  )
                : _buildBack(card),
          );
        },
      ),
    );
  }

  Widget _buildBack(_Card card) {
    final isCursing = card.isCursing;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCursing
              ? [const Color(0xFF8B0000), const Color(0xFF4A0000)]
              : [const Color(0xFF2A1A4A), const Color(0xFF1A0D30)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCursing
              ? kRed.withOpacity(0.8)
              : const Color(0xFF6A0DAD).withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: isCursing
            ? [BoxShadow(color: kRed.withOpacity(0.4), blurRadius: 12)]
            : [],
      ),
      child: Center(child: Text(
        isCursing ? '💀' : '᛭',
        style: TextStyle(
          fontSize: isCursing ? 22 : 26,
          color: isCursing ? kRed : const Color(0xFF6A0DAD).withOpacity(0.6),
        ),
      )),
    );
  }

  Widget _buildFace(_Card card) {
    final isMatched = card.isMatched;
    final color = card.rune.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMatched
              ? [kGold.withOpacity(0.4), const Color(0xFF8B6914).withOpacity(0.3)]
              : [color.withOpacity(0.2), const Color(0xFF1A0D30)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMatched ? kGold : color.withOpacity(0.8),
          width: isMatched ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isMatched ? kGold : color).withOpacity(isMatched ? 0.6 : 0.3),
            blurRadius: isMatched ? 20 : 8,
          ),
        ],
      ),
      child: Stack(children: [
        // Каменная текстура
        CustomPaint(painter: _StonePainter(color: color, matched: isMatched)),
        // Символ руны
        Center(child: Text(
          card.rune.symbol,
          style: TextStyle(
            fontSize: 28,
            color: isMatched ? kGold : color,
            shadows: [Shadow(color: (isMatched ? kGold : color).withOpacity(0.8), blurRadius: 12)],
          ),
        )),
        // Метка проклятой
        if (card.rune.isCursed && !isMatched)
          Positioned(top: 4, right: 4,
            child: Text('⚠️', style: TextStyle(fontSize: 10, color: kRed.withOpacity(0.7)))),
      ]),
    );
  }

  Widget _buildParticles() {
    return LayoutBuilder(builder: (ctx, cst) {
      final cellW = (cst.maxWidth - 12 * 5) / _cols;
      final cellH = (cst.maxHeight - 12 * 5) / _rows;

      return CustomPaint(
        size: Size(cst.maxWidth, cst.maxHeight),
        painter: _ParticlePainter(
          particles: _particles,
          progress: _particleCtrl.value,
          cellW: cellW, cellH: cellH,
        ),
      );
    });
  }

  Widget _buildOverlay(bool win) {
    return Positioned.fill(child: Container(
      color: Colors.black.withOpacity(0.75),
      child: ScaleTransition(
        scale: win ? _winScale : _failScale,
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(win ? '✨' : '💀', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 14),
          Text(win ? 'Руны раскрыты!' : 'Магия угасла!',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          Text(win ? 'Все пары найдены 🔮' : 'Попробуй ещё раз',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
        ])),
      ),
    ));
  }
}

// ─── Каменная текстура ────────────────────────────────────────────────────
class _StonePainter extends CustomPainter {
  final Color color;
  final bool matched;
  _StonePainter({required this.color, required this.matched});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(color.value);
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        paint,
      );
    }
    if (matched) {
      final shimmer = Paint()
        ..shader = RadialGradient(
          colors: [kGold.withOpacity(0.15), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), shimmer);
    }
  }

  @override
  bool shouldRepaint(_StonePainter old) => old.matched != matched;
}

// ─── Золотые частицы ──────────────────────────────────────────────────────
class _GoldParticle {
  final int col, row;
  double vx, vy;
  double x = 0, y = 0;
  bool initialized = false;
  _GoldParticle({required this.col, required this.row, required this.vx, required this.vy});
}

class _ParticlePainter extends CustomPainter {
  final List<_GoldParticle> particles;
  final double progress;
  final double cellW, cellH;

  _ParticlePainter({required this.particles, required this.progress, required this.cellW, required this.cellH});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    for (final p in particles) {
      if (!p.initialized) {
        p.x = (p.col + 0.5) * (cellW + 8) + 12;
        p.y = (p.row + 0.5) * (cellH + 8) + 12;
        p.initialized = true;
      }
      final t = progress;
      final px = p.x + p.vx * t * 60;
      final py = p.y + p.vy * t * 60 + 80 * t * t;
      final opacity = (1 - t).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(px, py), 3 * (1 - t * 0.5),
          Paint()..color = kGold.withOpacity(opacity * 0.9)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
