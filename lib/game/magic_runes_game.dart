// lib/game/magic_runes_game.dart
//
// 🔮 МАГИЧЕСКИЕ РУНЫ — игра на память
// Запомни последовательность светящихся рун, затем воспроизведи её.
// Уровни усложняются — длина цепочки растёт с 3 до 6 символов.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

// ─── Данные рун ──────────────────────────────────────────────────────────────
class _Rune {
  final String symbol;
  final String name;
  final Color color;
  final Color glow;
  const _Rune(this.symbol, this.name, this.color, this.glow);
}

const _kRunes = [
  _Rune('ᚠ', 'Феху',   Color(0xFF00D4AA), Color(0xFF00FFD0)),
  _Rune('ᚢ', 'Уруз',   Color(0xFF2E86AB), Color(0xFF5EC8FF)),
  _Rune('ᚦ', 'Турисаз',Color(0xFF6A11CB), Color(0xFFB060FF)),
  _Rune('ᚨ', 'Ансуз',  Color(0xFFFF6B6B), Color(0xFFFF9999)),
  _Rune('ᚱ', 'Райдо',  Color(0xFFFFD700), Color(0xFFFFED80)),
  _Rune('ᚲ', 'Кеназ',  Color(0xFFFF6B35), Color(0xFFFF9060)),
];

enum _Phase { idle, showing, input, success, fail }

class MagicRunesGame extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const MagicRunesGame({super.key, required this.onSuccess, required this.onFail});

  @override
  State<MagicRunesGame> createState() => _MagicRunesGameState();
}

class _MagicRunesGameState extends State<MagicRunesGame>
    with TickerProviderStateMixin {
  // ─── Состояние игры ────────────────────────────────────────────────────────
  int _level = 1;          // уровень 1-4
  int _maxLevels = 4;
  List<int> _sequence = [];
  List<int> _playerInput = [];
  int _showIndex = -1;
  _Phase _phase = _Phase.idle;
  int _lives = 3;
  int _score = 0;

  // ─── Анимации ──────────────────────────────────────────────────────────────
  late AnimationController _bgCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _resultCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _resultScale;
  late Animation<double> _resultFade;

  final List<AnimationController> _runeCtrl = [];
  final List<Animation<double>> _runeGlow = [];
  final List<Animation<double>> _runePulse = [];

  @override
  void initState() {
    super.initState();

    // Фоновая пульсация
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    // Пульс активной руны
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _pulseAnim = Tween(begin: 1.0, end: 1.18).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Результат
    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _resultScale = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.elasticOut));
    _resultFade  = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);

    // Контроллер для каждой руны
    for (int i = 0; i < _kRunes.length; i++) {
      final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
      _runeCtrl.add(c);
      _runeGlow.add(Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)));
      _runePulse.add(Tween(begin: 1.0, end: 1.22).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)));
    }

    Future.delayed(const Duration(milliseconds: 600), _startLevel);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    _resultCtrl.dispose();
    for (final c in _runeCtrl) c.dispose();
    super.dispose();
  }

  // ─── Логика ────────────────────────────────────────────────────────────────
  int get _seqLength => _level + 2; // 3, 4, 5, 6

  void _startLevel() {
    _sequence = List.generate(_seqLength, (_) => Random().nextInt(_kRunes.length));
    _playerInput = [];
    _showIndex = -1;
    setState(() => _phase = _Phase.showing);
    _showSequence();
  }

  Future<void> _showSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    for (int i = 0; i < _sequence.length; i++) {
      if (!mounted) return;
      setState(() => _showIndex = i);
      final runeIdx = _sequence[i];
      _runeCtrl[runeIdx].forward(from: 0);
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 700));
      _runeCtrl[runeIdx].reverse();
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (!mounted) return;
    setState(() { _phase = _Phase.input; _showIndex = -1; });
  }

  void _onRuneTap(int runeIdx) {
    if (_phase != _Phase.input) return;
    HapticFeedback.selectionClick();

    _runeCtrl[runeIdx].forward(from: 0).then((_) {
      if (mounted) _runeCtrl[runeIdx].reverse();
    });

    _playerInput.add(runeIdx);
    final pos = _playerInput.length - 1;

    if (_playerInput[pos] != _sequence[pos]) {
      // Ошибка
      _lives--;
      HapticFeedback.heavyImpact();
      if (_lives <= 0) {
        setState(() => _phase = _Phase.fail);
        _resultCtrl.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), widget.onFail);
      } else {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.close_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('Неверно! Осталось жизней: $_lives', style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          backgroundColor: kRed,
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!mounted) return;
          setState(() => _playerInput = []);
          _showSequence();
        });
      }
      return;
    }

    if (_playerInput.length == _sequence.length) {
      // Уровень пройден
      _score += _level * 10;
      HapticFeedback.mediumImpact();
      if (_level >= _maxLevels) {
        setState(() => _phase = _Phase.success);
        _resultCtrl.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), widget.onSuccess);
      } else {
        setState(() { _level++; _phase = _Phase.idle; });
        Future.delayed(const Duration(milliseconds: 800), _startLevel);
      }
    }
  }

  // ─── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // ── Анимированный фон ───────────────────────────────────────────────
        AnimatedBuilder(
          animation: _bgAnim,
          builder: (_, __) => CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _MysticBgPainter(_bgAnim.value),
          ),
        ),

        SafeArea(child: Column(children: [
          _buildHeader(),
          _buildProgress(),
          const SizedBox(height: 12),
          _buildStatusPanel(),
          const Spacer(),
          _buildRuneGrid(),
          const Spacer(),
          _buildBottomInfo(),
          const SizedBox(height: 28),
        ])),

        // ── Оверлей результата ──────────────────────────────────────────────
        if (_phase == _Phase.success || _phase == _Phase.fail)
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
          shaderCallback: (b) => const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF6A11CB)]).createShader(b),
          child: const Text('МАГИЧЕСКИЕ РУНЫ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
        ),
        const Spacer(),
        // Жизни
        Row(children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(Icons.favorite_rounded,
              size: 20,
              color: i < _lives ? const Color(0xFFFF6B6B) : Colors.white.withOpacity(0.18)),
        ))),
      ]),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Уровень $_level из $_maxLevels',
              style: const TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 1)),
          Text('Очки: $_score',
              style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (_level - 1) / _maxLevels,
            minHeight: 3,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
          ),
        ),
      ]),
    );
  }

  Widget _buildStatusPanel() {
    final String msg = switch (_phase) {
      _Phase.idle    => '✨ Приготовься...',
      _Phase.showing => '👁️ Запоминай последовательность',
      _Phase.input   => '🖐️ Повтори — ${_seqLength - _playerInput.length} осталось',
      _Phase.success => '✅ Мастер рун!',
      _Phase.fail    => '💀 Система закрыта',
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _phase == _Phase.input
            ? const Color(0xFF00D4AA).withOpacity(0.12)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _phase == _Phase.input
              ? const Color(0xFF00D4AA).withOpacity(0.4)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(msg,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _phase == _Phase.input ? const Color(0xFF00D4AA) : Colors.white70,
                letterSpacing: 0.5)),
      ]),
    );
  }

  Widget _buildRuneGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        // Счётчик последовательности
        _buildSequenceIndicator(),
        const SizedBox(height: 28),
        // Сетка 3×2
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          children: List.generate(_kRunes.length, (i) => _buildRuneCell(i)),
        ),
      ]),
    );
  }

  Widget _buildSequenceIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_seqLength, (i) {
        Color color;
        if (i < _playerInput.length) {
          color = const Color(0xFF00D4AA);
        } else if (i == _playerInput.length && _phase == _Phase.input) {
          color = Colors.white.withOpacity(0.7);
        } else if (_phase == _Phase.showing && _showIndex == i) {
          color = _kRunes[_sequence[i]].color;
        } else {
          color = Colors.white.withOpacity(0.18);
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == _playerInput.length && _phase == _Phase.input ? 14 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
            boxShadow: color != Colors.white.withOpacity(0.18)
                ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildRuneCell(int i) {
    final rune = _kRunes[i];
    final isActive = _showIndex >= 0 && _showIndex < _sequence.length && _sequence[_showIndex] == i;
    final isInteractive = _phase == _Phase.input;

    return AnimatedBuilder(
      animation: _runeCtrl[i],
      builder: (_, __) {
        final glow = _runeGlow[i].value;
        final scale = _runePulse[i].value;

        return GestureDetector(
          onTapDown: (_) { if (isInteractive) _onRuneTap(i); },
          child: Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Color.lerp(Colors.white.withOpacity(0.1), rune.color, glow)!,
                  width: 1.5 + glow,
                ),
                boxShadow: [
                  if (glow > 0)
                    BoxShadow(color: rune.glow.withOpacity(glow * 0.6), blurRadius: 24, spreadRadius: 4),
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                ],
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(Colors.white.withOpacity(0.04), rune.color.withOpacity(0.25), glow)!,
                    Colors.black.withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(rune.symbol,
                    style: TextStyle(
                      fontSize: 36,
                      color: Color.lerp(Colors.white.withOpacity(0.5), rune.color, glow),
                      shadows: glow > 0.3 ? [Shadow(color: rune.glow, blurRadius: 16)] : null,
                    )),
                const SizedBox(height: 4),
                Text(rune.name,
                    style: TextStyle(
                      fontSize: 9,
                      color: Color.lerp(Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.8), glow),
                      letterSpacing: 0.5,
                    )),
                if (isInteractive) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 4, height: 4,
                    decoration: BoxDecoration(
                      color: rune.color.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, size: 14, color: Colors.white.withOpacity(0.3)),
        const SizedBox(width: 6),
        Expanded(child: Text(
          _phase == _Phase.showing
              ? 'Запомни порядок появления рун...'
              : _phase == _Phase.input
                  ? 'Повтори последовательность в том же порядке'
                  : 'Дождись начала показа',
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)),
        )),
      ]),
    );
  }

  Widget _buildResultOverlay() {
    final isSuccess = _phase == _Phase.success;
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
                  boxShadow: [
                    BoxShadow(
                      color: (isSuccess ? const Color(0xFF00D4AA) : const Color(0xFFFF6B6B)).withOpacity(0.3),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(isSuccess ? '✨' : '💀', style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(
                    isSuccess ? 'РУНЫ ИЗУЧЕНЫ!' : 'СИСТЕМА\nОТКЛЮЧЕНА',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isSuccess ? const Color(0xFF00D4AA) : const Color(0xFFFF6B6B),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSuccess ? 'Доступ к лестнице открыт' : 'Попробуй снова',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)),
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

// ─── Мистический фон ─────────────────────────────────────────────────────────
class _MysticBgPainter extends CustomPainter {
  final double t;
  static final _rng = Random(42);

  _MysticBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF030510));

    // Туманные круги
    final paint = Paint()..style = PaintingStyle.fill;
    final circles = [
      [0.1, 0.2, 180.0, const Color(0xFF6A11CB)],
      [0.8, 0.1, 140.0, const Color(0xFF2E86AB)],
      [0.5, 0.7, 200.0, const Color(0xFF00D4AA)],
      [0.9, 0.8, 120.0, const Color(0xFF6A11CB)],
    ];

    for (final c in circles) {
      final x = (c[0] as double) * size.width;
      final y = (c[1] as double) * size.height;
      final r = (c[2] as double) + sin(t * pi * 2) * 20;
      final color = c[3] as Color;

      paint.shader = RadialGradient(
        colors: [color.withOpacity(0.12 + t * 0.04), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: r));
      canvas.drawCircle(Offset(x, y), r, paint);
    }

    // Звёзды-частицы
    for (int i = 0; i < 60; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      final r = 0.5 + _rng.nextDouble() * 1.0;
      final flicker = 0.15 + 0.85 * sin(t * pi * 2 * (0.3 + _rng.nextDouble()) + i);
      canvas.drawCircle(Offset(x, y), r,
          Paint()..color = Colors.white.withOpacity(flicker.abs() * 0.5));
    }
  }

  @override
  bool shouldRepaint(_MysticBgPainter old) => old.t != t;
}
