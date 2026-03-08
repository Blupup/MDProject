// lib/game/disappeared_game.dart
//
// Игра «Найди исчезнувшее» — показывает карточки с картинками (или словами),
// одна исчезает, нужно угадать какая.
//
// Если items содержат пути 'assets/...' — показываются фото.
// Если обычные слова — показываются текстовые карточки (как раньше).
//
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

enum _Phase { memorize, flash, reveal, guess, success, fail }

class DisappearedGame extends StatefulWidget {
  final List<String> items;
  final VoidCallback onSuccess;
  final VoidCallback onFail;
  const DisappearedGame({
    super.key,
    required this.items,
    required this.onSuccess,
    required this.onFail,
  });
  @override
  State<DisappearedGame> createState() => _DisappearedGameState();
}

class _DisappearedGameState extends State<DisappearedGame>
    with TickerProviderStateMixin {

  late List<String> _shuffled;
  late List<String> _remaining;
  String? _removed;
  _Phase _phase = _Phase.memorize;
  int _timeLeft = 6;
  int _lives = 3;
  int _score = 0;
  bool _btnEnabled = true;
  String? _wrongGuess;
  Timer? _timer;

  // Режим картинок: true если items[0] начинается с 'assets/'
  bool get _photoMode => widget.items.isNotEmpty && widget.items.first.startsWith('assets/');

  late AnimationController _pulseCtrl;
  late AnimationController _successCtrl;
  late AnimationController _failCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _flashCtrl;
  late AnimationController _countdownCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _successScaleAnim;
  late Animation<double> _failScaleAnim;
  late Animation<double> _shakeAnim;
  late Animation<double> _flashAnim;
  late List<AnimationController> _cardCtrls;
  late List<Animation<double>> _cardAnims;

  @override
  void initState() {
    super.initState();
    _shuffled  = [...widget.items]..shuffle(Random());
    _remaining = [..._shuffled];

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _successScaleAnim = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));

    _failCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _failScaleAnim = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _failCtrl, curve: Curves.easeOut));

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0,  end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0,  end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0,   end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0,    end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);

    _flashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _flashAnim = Tween(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut));

    _countdownCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6));

    _cardCtrls = List.generate(widget.items.length,
      (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 400)));
    _cardAnims = _cardCtrls
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutBack))
        .toList();

    _startMemorize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose(); _successCtrl.dispose(); _failCtrl.dispose();
    _shakeCtrl.dispose(); _flashCtrl.dispose(); _countdownCtrl.dispose();
    for (final c in _cardCtrls) c.dispose();
    super.dispose();
  }

  // ─── Фазы ──────────────────────────────────────────────────────────────────
  void _startMemorize() {
    for (var i = 0; i < _cardCtrls.length; i++) {
      Future.delayed(Duration(milliseconds: 80 * i), () {
        if (mounted) _cardCtrls[i].forward();
      });
    }
    _timeLeft = 6;
    _countdownCtrl.forward(from: 0);
    _tick(onDone: _startFlash, total: 6);
  }

  void _startFlash() {
    _timer?.cancel();
    setState(() => _phase = _Phase.flash);
    HapticFeedback.mediumImpact();
    _flashCtrl.forward(from: 0).then((_) { if (mounted) _startReveal(); });
  }

  void _startReveal() {
    _removed = _shuffled.removeAt(0);
    _remaining = [..._shuffled];
    setState(() => _phase = _Phase.reveal);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      _flashCtrl.forward(from: 0).then((_) {
        if (!mounted) return;
        setState(() {
          _phase = _Phase.guess;
          _timeLeft = 15;
          _btnEnabled = true;
          _wrongGuess = null;
        });
        _countdownCtrl
          ..duration = const Duration(seconds: 15)
          ..forward(from: 0);
        _tick(onDone: _onTimeout, total: 15);
      });
    });
  }

  void _onTimeout() {
    HapticFeedback.vibrate();
    _lives--;
    if (_lives <= 0) {
      _triggerFail();
    } else {
      _shakeCtrl.forward(from: 0);
      setState(() => _timeLeft = 15);
      _countdownCtrl.forward(from: 0);
      _tick(onDone: _onTimeout, total: 15);
    }
  }

  void _tick({required VoidCallback onDone, required int total}) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) { t.cancel(); onDone(); }
    });
  }

  void _guess(String item) {
    if (!_btnEnabled || _phase != _Phase.guess) return;
    _timer?.cancel();
    HapticFeedback.lightImpact();
    if (item == _removed) {
      _score = (_timeLeft * 12) + (_lives * 25) + 30;
      setState(() { _btnEnabled = false; _phase = _Phase.success; });
      HapticFeedback.heavyImpact();
      _successCtrl.forward();
      Future.delayed(const Duration(milliseconds: 2500), widget.onSuccess);
    } else {
      _lives--;
      setState(() { _btnEnabled = false; _wrongGuess = item; });
      _shakeCtrl.forward(from: 0);
      HapticFeedback.vibrate();
      if (_lives <= 0) {
        Future.delayed(const Duration(milliseconds: 800), _triggerFail);
      } else {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          setState(() { _btnEnabled = true; _wrongGuess = null; _timeLeft = 15; });
          _countdownCtrl.forward(from: 0);
          _tick(onDone: _onTimeout, total: 15);
        });
      }
    }
  }

  void _triggerFail() {
    setState(() => _phase = _Phase.fail);
    _failCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2500), widget.onFail);
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Stack(children: [
          const BgCircle(top: -60, left: -40, size: 180, color: Color(0xFF6A11CB), opacity: 0.2),
          const BgCircle(top: 300, left: 200, size: 140, color: kBlue, opacity: 0.12),
          AnimatedBuilder(
            animation: _flashAnim,
            builder: (_, __) => _flashCtrl.isAnimating
                ? Positioned.fill(child: Container(
                    color: Colors.white.withOpacity(_flashAnim.value * 0.18)))
                : const SizedBox(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(children: [
              _buildHeader(),
              const SizedBox(height: 18),
              Expanded(child: _buildPhaseContent()),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: const Color(0xFF6A11CB).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          const Icon(Icons.visibility_off_rounded, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            _photoMode ? '📸 Найди исчезнувшее' : '👁️ Найди исчезнувшее',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ]),
      ),
      const Spacer(),
      AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(_shakeAnim.value, 0), child: child),
        child: Row(
          children: List.generate(3, (i) {
            final alive = i < _lives;
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(
                alive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: alive ? kRed : Colors.white.withOpacity(0.2),
                size: alive ? 24 : 20,
              ),
            );
          }),
        ),
      ),
    ]);
  }

  Widget _buildPhaseContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
              begin: const Offset(0, 0.06), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(_phase),
        child: switch (_phase) {
          _Phase.memorize => _memorizePhase(),
          _Phase.flash    => _flashPhase(),
          _Phase.reveal   => _revealPhase(),
          _Phase.guess    => _guessPhase(),
          _Phase.success  => _successPhase(),
          _Phase.fail     => _failPhase(),
        },
      ),
    );
  }

  // ── ЗАПОМИНАНИЕ ────────────────────────────────────────────────────────────
  Widget _memorizePhase() {
    return Column(children: [
      _infoCard(
        topText: _photoMode ? '📸  Запомни все картинки!' : '👀  Запомни все предметы!',
        bottomWidget: _countdownBar(6, kGreen),
        subText: 'Осталось $_timeLeft сек',
        subColor: _timeLeft <= 2 ? kRed : kGreen,
      ),
      const SizedBox(height: 14),
      Expanded(
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _photoMode ? 2 : 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: _photoMode ? 1.0 : 1.3,
          ),
          itemCount: _shuffled.length,
          itemBuilder: (_, i) => ScaleTransition(
            scale: _cardAnims[i],
            child: _itemCard(_shuffled[i], i, glowing: true, showLabel: true),
          ),
        ),
      ),
    ]);
  }

  // ── ВСПЫШКА ────────────────────────────────────────────────────────────────
  Widget _flashPhase() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      ScaleTransition(
        scale: _pulseAnim,
        child: const Text('⚡', style: TextStyle(fontSize: 72)),
      ),
      const SizedBox(height: 16),
      const Text('Внимание!',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
    ]));
  }

  // ── ЧТО-ТО ИСЧЕЗЛО ─────────────────────────────────────────────────────────
  Widget _revealPhase() {
    return Column(children: [
      _infoCard(
        topText: _photoMode ? '🫣  Одна картинка исчезла...' : '🫣  Что-то исчезло...',
        subText: 'Запомни что изменилось',
        subColor: Colors.white54,
      ),
      const SizedBox(height: 14),
      Expanded(child: Column(children: [
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _photoMode ? 2 : 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: _photoMode ? 1.0 : 1.3,
            ),
            itemCount: _remaining.length + 1,
            itemBuilder: (_, i) {
              if (i == _remaining.length) return _emptySlot();
              return _itemCard(_remaining[i], i, glowing: false, showLabel: false);
            },
          ),
        ),
        const SizedBox(height: 10),
        ScaleTransition(
          scale: _pulseAnim,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: kRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kRed.withOpacity(0.5)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.arrow_upward_rounded, color: kRed, size: 18),
              SizedBox(width: 6),
              Text('Один предмет исчез! ☝️',
                  style: TextStyle(color: kRed, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        ),
        const SizedBox(height: 10),
      ])),
    ]);
  }

  // ── УГАДЫВАНИЕ ─────────────────────────────────────────────────────────────
  Widget _guessPhase() {
    final timeColor = _timeLeft > 8 ? kGreen : (_timeLeft > 4 ? Colors.orange : kRed);
    return Column(children: [
      _infoCard(
        topText: _photoMode ? '🤔  Какая картинка исчезла?' : '🤔  Какой предмет исчез?',
        bottomWidget: AnimatedBuilder(
          animation: _countdownCtrl,
          builder: (_, __) => _countdownBar(15, timeColor),
        ),
        subText: '$_timeLeft сек',
        subColor: timeColor,
        timerColor: timeColor,
      ),
      const SizedBox(height: 16),
      Expanded(
        child: _photoMode ? _photoChoices() : _textChoices(),
      ),
    ]);
  }

  // Сетка фото для угадывания
  Widget _photoChoices() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: widget.items.length,
      itemBuilder: (_, i) {
        final item = widget.items[i];
        final isWrong = _wrongGuess == item;
        return AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(isWrong ? _shakeAnim.value : 0, 0),
            child: child,
          ),
          child: GestureDetector(
            onTap: _btnEnabled ? () => _guess(item) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isWrong ? kRed : kGreen.withOpacity(0.4),
                  width: isWrong ? 3 : 1.5,
                ),
                boxShadow: isWrong
                    ? [BoxShadow(color: kRed.withOpacity(0.4), blurRadius: 12)]
                    : [BoxShadow(color: kGreen.withOpacity(0.15), blurRadius: 8)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(
                    item,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1E3A5F),
                      child: const Center(child: Icon(Icons.image_not_supported_rounded,
                          color: Colors.white38, size: 32)),
                    ),
                  ),
                  // Затемнение при неправильном ответе
                  if (isWrong)
                    Container(
                      decoration: BoxDecoration(
                        color: kRed.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(child: Icon(Icons.close_rounded,
                          color: Colors.white, size: 36)),
                    ),
                  // Нижний градиент
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(14)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  // Текстовые кнопки для угадывания (старый режим)
  Widget _textChoices() {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 10, runSpacing: 10,
        alignment: WrapAlignment.center,
        children: widget.items.map((item) => _choiceBtn(item)).toList(),
      ),
    );
  }

  // ── УСПЕХ ──────────────────────────────────────────────────────────────────
  Widget _successPhase() {
    return ScaleTransition(
      scale: _successScaleAnim,
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 110, height: 110,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kGreen, Color(0xFF00A896)]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: kGreen.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 60)),
        const SizedBox(height: 24),
        const Text('Правильно!',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kGold, Color(0xFFFFA726)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: kGold.withOpacity(0.4), blurRadius: 16)],
          ),
          child: Text('+$_score очков',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 14),
        // Показываем исчезнувшую картинку
        if (_photoMode && _removed != null) ...[
          Text('Это было:', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(_removed!, width: 80, height: 80, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox()),
          ),
        ] else
          Text('Отличная память! 🧠',
              style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 16)),
      ])),
    );
  }

  // ── ПРОВАЛ ─────────────────────────────────────────────────────────────────
  Widget _failPhase() {
    return ScaleTransition(
      scale: _failScaleAnim,
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 110, height: 110,
          decoration: BoxDecoration(
            color: kRed.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: kRed, width: 3),
            boxShadow: [BoxShadow(color: kRed.withOpacity(0.3), blurRadius: 20, spreadRadius: 3)],
          ),
          child: const Icon(Icons.close_rounded, color: kRed, size: 60)),
        const SizedBox(height: 24),
        const Text('Не получилось...',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 12),
        if (_photoMode && _removed != null) ...[
          Text('Исчезла вот эта картинка:',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(_removed!, width: 90, height: 90, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox()),
          ),
        ] else
          Text('Исчезло: ${_removed ?? "?"}',
              style: const TextStyle(fontSize: 18, color: kGreen, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text('Попробуй ещё раз! 💪',
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14)),
      ])),
    );
  }

  // ─── Вспомогательные виджеты ───────────────────────────────────────────────
  Widget _infoCard({
    required String topText,
    Widget? bottomWidget,
    required String subText,
    required Color subColor,
    Color? timerColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(children: [
        Text(topText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        if (bottomWidget != null) ...[bottomWidget, const SizedBox(height: 5)],
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (timerColor != null) ...[
            Icon(Icons.timer_rounded, color: timerColor, size: 15),
            const SizedBox(width: 4),
          ],
          Text(subText, style: TextStyle(color: subColor, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

  Widget _countdownBar(int total, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: LinearProgressIndicator(
        value: _timeLeft / total,
        minHeight: 8,
        backgroundColor: Colors.white.withOpacity(0.1),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  // Карточка предмета — фото или текст
  Widget _itemCard(String item, int i, {required bool glowing, required bool showLabel}) {
    final isPhoto = item.startsWith('assets/');
    if (isPhoto) {
      return _photoCard(item, i, glowing: glowing, showLabel: showLabel);
    }
    return _textCard(item, i, glowing: glowing);
  }

  Widget _photoCard(String path, int i, {required bool glowing, required bool showLabel}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kGreen.withOpacity(glowing ? 0.65 : 0.2), width: 1.5),
        boxShadow: glowing
            ? [BoxShadow(color: kGreen.withOpacity(0.25), blurRadius: 10)]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(fit: StackFit.expand, children: [
          Image.asset(
            path,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1E3A5F),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.image_rounded, color: Colors.white38, size: 28),
                const SizedBox(height: 4),
                Text('Фото ${i + 1}',
                    style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ]),
            ),
          ),
          // Нижняя полоска с номером
          if (showLabel)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(child: Text(
                  '${i + 1}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700),
                )),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _textCard(String text, int i, {required bool glowing}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF1A4D3A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGreen.withOpacity(glowing ? 0.6 : 0.25), width: 1.5),
        boxShadow: glowing
            ? [BoxShadow(color: kGreen.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))]
            : null,
      ),
      child: Stack(children: [
        Center(child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w700, height: 1.2),
              textAlign: TextAlign.center, maxLines: 2),
        )),
        Positioned(top: 5, left: 5,
          child: Container(
            width: 20, height: 20,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [kBlue, kGreen]),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text('${i + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))),
          ),
        ),
      ]),
    );
  }

  Widget _emptySlot() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Transform.scale(
        scale: _pulseAnim.value,
        child: Container(
          decoration: BoxDecoration(
            color: kRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kRed, width: 2),
            boxShadow: [BoxShadow(color: kRed.withOpacity(0.3), blurRadius: 12)],
          ),
          child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.question_mark_rounded, color: kRed, size: 28),
            Text('?', style: TextStyle(color: kRed, fontWeight: FontWeight.w900, fontSize: 11)),
          ])),
        ),
      ),
    );
  }

  Widget _choiceBtn(String item) {
    final isWrong = _wrongGuess == item;
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(isWrong ? _shakeAnim.value : 0, 0), child: child),
      child: GestureDetector(
        onTap: _btnEnabled ? () => _guess(item) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          decoration: BoxDecoration(
            gradient: isWrong
                ? const LinearGradient(colors: [Color(0xFF8B0000), Color(0xFFB71C1C)])
                : const LinearGradient(colors: [kBlue, kGreen],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isWrong ? kRed : Colors.transparent, width: 2),
            boxShadow: [BoxShadow(
              color: (isWrong ? kRed : kBlue).withOpacity(0.35),
              blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Text(item,
              style: TextStyle(
                color: _btnEnabled ? Colors.white : Colors.white54,
                fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}