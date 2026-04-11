// lib/screens/legend_screen.dart
//
// Экран общей предыстории — показывается один раз при первом входе в квесты.
// «Система пробудилась. Ты — её последний Администратор.»
//
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/quest_data.dart';
import '../widgets/common_widgets.dart';

class LegendScreen extends StatefulWidget {
  final VoidCallback onDone;
  const LegendScreen({super.key, required this.onDone});

  @override
  State<LegendScreen> createState() => _LegendScreenState();
}

class _LegendScreenState extends State<LegendScreen> with TickerProviderStateMixin {
  int _page = -1; // -1 = системное сообщение, 0..3 = страницы хроники
  bool _showButton = false;

  late AnimationController _fadeCtrl, _typeCtrl, _glowCtrl, _particleCtrl;
  late Animation<double> _fadeAnim, _typeAnim, _glowAnim;

  // Для эффекта печатания
  String _typedText = '';
  static const String _sysMsg = CorpusLegend.systemMessage;
  int _typeIdx = 0;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _typeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _typeAnim = CurvedAnimation(parent: _typeCtrl, curve: Curves.linear);
    _glowAnim = Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Эффект печатания
    _typeCtrl.addListener(() {
      final target = (_typeAnim.value * _sysMsg.length).floor();
      if (target != _typeIdx) {
        setState(() {
          _typeIdx = target;
          _typedText = _sysMsg.substring(0, target);
        });
      }
    });
    _typeCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() { _typedText = _sysMsg; _showButton = true; });
      }
    });

    _fadeCtrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _typeCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose(); _typeCtrl.dispose();
    _glowCtrl.dispose(); _particleCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.selectionClick();
    if (_page < CorpusLegend.pages.length - 1) {
      setState(() {
        _page++;
        _showButton = false;
      });
      _fadeCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _showButton = true);
      });
    } else {
      widget.onDone();
    }
  }

  void _skipToPages() {
    HapticFeedback.mediumImpact();
    _typeCtrl.stop();
    setState(() { _typedText = _sysMsg; _showButton = false; _page = 0; });
    _fadeCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showButton = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Фон — звёздное поле + частицы
        AnimatedBuilder(
          animation: _particleCtrl,
          builder: (_, __) => CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _StarfieldPainter(progress: _particleCtrl.value),
          ),
        ),

        SafeArea(child: FadeTransition(
          opacity: _fadeAnim,
          child: _page == -1 ? _buildSystemMsg() : _buildChronicle(),
        )),
      ]),
    );
  }

  // ─── Системное сообщение (печатается как терминал) ────────────────────────
  Widget _buildSystemMsg() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(children: [
        const SizedBox(height: 20),
        // Лого
        AnimatedBuilder(animation: _glowAnim, builder: (_, __) =>
          ShaderMask(
            shaderCallback: (b) => LinearGradient(
              colors: [kGreen, const Color(0xFF00F5FF)],
            ).createShader(b),
            child: Text(
              'Б-КОРПУС',
              style: TextStyle(
                fontSize: 42, fontWeight: FontWeight.w900,
                color: Colors.white, letterSpacing: 6,
                shadows: [Shadow(color: kGreen.withOpacity(_glowAnim.value * 0.8), blurRadius: 20)],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('СИСТЕМА ПРОБУДИЛАСЬ',
            style: TextStyle(fontSize: 13, letterSpacing: 4, color: kGreen.withOpacity(0.7), fontWeight: FontWeight.w700)),

        const SizedBox(height: 40),

        // Терминальное сообщение
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kGreen.withOpacity(0.3), width: 1.5),
              boxShadow: [BoxShadow(color: kGreen.withOpacity(0.08), blurRadius: 20)],
            ),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: kGreen, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: kGreen, blurRadius: 6)])),
                  const SizedBox(width: 8),
                  Text('СИСТЕМА > СООБЩЕНИЕ',
                      style: TextStyle(color: kGreen.withOpacity(0.5), fontSize: 10, letterSpacing: 2)),
                ]),
                const SizedBox(height: 20),
                // Текст с курсором
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _typedText,
                        style: const TextStyle(
                          color: kGreen, fontSize: 16, height: 1.9,
                          fontFamily: 'monospace', fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!_showButton)
                        WidgetSpan(child: AnimatedBuilder(
                          animation: _glowAnim,
                          builder: (_, __) => Container(
                            width: 10, height: 20, margin: const EdgeInsets.only(left: 2),
                            color: kGreen.withOpacity(_glowAnim.value),
                          ),
                        )),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),

        const SizedBox(height: 24),

        if (_showButton) ...[
          // Кнопка — читать хронику
          GradientButton(
            text: 'Читать хронику корпуса →',
            icon: Icons.history_edu_rounded,
            colors: [kGreen, const Color(0xFF00A080)],
            onTap: _skipToPages,
            height: 56,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: widget.onDone,
            child: Text('Пропустить',
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
          ),
        ] else ...[
          GestureDetector(
            onTap: () {
              _typeCtrl.stop();
              setState(() { _typedText = _sysMsg; _showButton = true; });
            },
            child: Text('Нажми чтобы ускорить',
                style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12)),
          ),
        ],
        const SizedBox(height: 16),
      ]),
    );
  }

  // ─── Страницы хроники (4 эпохи) ──────────────────────────────────────────
  Widget _buildChronicle() {
    final page = CorpusLegend.pages[_page];
    final isLast = _page == CorpusLegend.pages.length - 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        // Прогресс
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ...List.generate(CorpusLegend.pages.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == _page ? 24 : 8, height: 4,
            decoration: BoxDecoration(
              color: i <= _page ? page.color : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
        ]),
        const SizedBox(height: 32),

        // Год
        AnimatedBuilder(animation: _glowAnim, builder: (_, __) =>
          Text(page.year, style: TextStyle(
            fontSize: 72, fontWeight: FontWeight.w900,
            color: page.color.withOpacity(0.15),
            letterSpacing: 4,
            shadows: [Shadow(color: page.color.withOpacity(_glowAnim.value * 0.3), blurRadius: 30)],
          )),
        ),

        const SizedBox(height: 8),

        // Иконка
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: page.color.withOpacity(0.12),
            border: Border.all(color: page.color.withOpacity(0.4), width: 2),
            boxShadow: [BoxShadow(color: page.color.withOpacity(0.2), blurRadius: 24)],
          ),
          child: Center(child: Text(page.icon, style: const TextStyle(fontSize: 44))),
        ),
        const SizedBox(height: 24),

        // Заголовок
        Text(page.title, style: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w900, color: page.color, letterSpacing: 1,
        )),
        const SizedBox(height: 16),

        // Декоративная линия
        Row(children: [
          const Expanded(child: Divider(color: Colors.white12)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(width: 6, height: 6, decoration: BoxDecoration(color: page.color, shape: BoxShape.circle)),
          ),
          const Expanded(child: Divider(color: Colors.white12)),
        ]),
        const SizedBox(height: 20),

        // Текст
        Expanded(
          child: Center(
            child: Text(page.text, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.82), height: 1.75, letterSpacing: 0.3),
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Кнопка
        if (_showButton)
          GradientButton(
            text: isLast ? 'Начать приключение 🚀' : 'Далее →',
            colors: [page.color, Color.lerp(page.color, Colors.white, 0.2)!],
            onTap: _nextPage,
            height: 56,
          ),
        const SizedBox(height: 16),
      ]),
    );
  }
}

// ─── Звёздное поле ────────────────────────────────────────────────────────
class _StarfieldPainter extends CustomPainter {
  final double progress;
  static final _rng = Random(7);

  _StarfieldPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF030810));

    for (int i = 0; i < 120; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      final r = 0.4 + _rng.nextDouble() * 1.6;
      final twinkle = 0.2 + 0.8 * sin(progress * 2 * pi * (0.5 + _rng.nextDouble()) + i * 0.4);
      canvas.drawCircle(Offset(x, y), r,
          Paint()..color = Colors.white.withOpacity(twinkle * 0.7));
    }

    // Несколько ярких звёзд с крестообразным блеском
    for (int i = 0; i < 5; i++) {
      final x = size.width * (0.1 + i * 0.2);
      final y = size.height * (0.1 + _rng.nextDouble() * 0.4);
      final glow = 0.4 + 0.6 * sin(progress * 2 * pi + i * 1.2);
      canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = Colors.white.withOpacity(glow));
      final linePaint = Paint()..color = Colors.white.withOpacity(glow * 0.3)..strokeWidth = 1;
      canvas.drawLine(Offset(x - 12, y), Offset(x + 12, y), linePaint);
      canvas.drawLine(Offset(x, y - 12), Offset(x, y + 12), linePaint);
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => old.progress != progress;
}
