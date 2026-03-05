// lib/game/word_scramble_game.dart
//
// Игра «Собери слово» — из перемешанных букв составь правильное слово.
// Использование:
//   WordScrambleGame(items: task.miniGameItems, onSuccess: ..., onFail: ...)
//
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

class WordScrambleGame extends StatefulWidget {
  final List<String> items;   // Слова из задания (будет показано по одному за раз)
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const WordScrambleGame({
    super.key,
    required this.items,
    required this.onSuccess,
    required this.onFail,
  });

  @override
  State<WordScrambleGame> createState() => _WordScrambleGameState();
}

class _WordScrambleGameState extends State<WordScrambleGame>
    with TickerProviderStateMixin {
  // ─── Игровое состояние ────────────────────────────────────────────────────
  late List<String> _words;          // все слова
  int _wordIndex = 0;                // текущее слово
  late List<String> _scrambled;      // перемешанные буквы (источник)
  List<String> _answer = [];         // буквы, которые игрок уже выбрал
  List<bool>   _usedIndices = [];    // какие индексы в _scrambled уже использованы

  int _score = 0;
  int _lives = 3;
  int _timeLeft = 30;
  Timer? _timer;
  bool _wordSolved = false;
  bool _gameWon  = false;
  bool _gameFail = false;

  // ─── Анимации ─────────────────────────────────────────────────────────────
  late AnimationController _shakeCtrl;
  late AnimationController _solveCtrl;
  late AnimationController _winCtrl;
  late AnimationController _failCtrl;
  late AnimationController _wordEntryCtrl;

  late Animation<double> _shakeAnim;
  late Animation<double> _solveScale;
  late Animation<double> _winScale;
  late Animation<double> _failScale;
  late Animation<double> _wordFade;

  @override
  void initState() {
    super.initState();
    _words = widget.items.toList()..shuffle(Random());

    _shakeCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _solveCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _winCtrl       = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _failCtrl      = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _wordEntryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));

    _shakeAnim  = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);
    _solveScale = Tween(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _solveCtrl, curve: Curves.elasticOut));
    _winScale  = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _winCtrl, curve: Curves.elasticOut));
    _failScale = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _failCtrl, curve: Curves.easeOut));
    _wordFade  = CurvedAnimation(parent: _wordEntryCtrl, curve: Curves.easeOut);

    _loadWord(0);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeCtrl.dispose();
    _solveCtrl.dispose();
    _winCtrl.dispose();
    _failCtrl.dispose();
    _wordEntryCtrl.dispose();
    super.dispose();
  }

  // ─── Подготовка слова ─────────────────────────────────────────────────────
  void _loadWord(int index) {
    final word = _words[index].toUpperCase();
    final letters = word.split('');
    // Перемешиваем до тех пор, пока не получим результат, отличающийся от исходного
    List<String> shuffled;
    do { shuffled = [...letters]..shuffle(Random()); }
    while (shuffled.join() == word && word.length > 1);

    setState(() {
      _scrambled    = shuffled;
      _answer       = [];
      _usedIndices  = List.filled(shuffled.length, false);
      _wordSolved   = false;
    });
    _wordEntryCtrl.forward(from: 0);
  }

  // ─── Таймер ───────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) { t.cancel(); _handleTimeout(); }
    });
  }

  void _handleTimeout() {
    _lives--;
    if (_lives <= 0) {
      _triggerFail();
    } else {
      HapticFeedback.vibrate();
      _shakeCtrl.forward(from: 0);
      // Сбрасываем текущее слово и начинаем сначала
      _loadWord(_wordIndex);
      _startTimer();
    }
  }

  // ─── Нажатие на букву (из перемешанных) ──────────────────────────────────
  void _pickLetter(int index) {
    if (_usedIndices[index] || _wordSolved) return;
    HapticFeedback.lightImpact();
    setState(() {
      _answer.add(_scrambled[index]);
      _usedIndices[index] = true;
    });
    _checkAnswer();
  }

  // ─── Убрать последнюю выбранную букву ────────────────────────────────────
  void _removeLast() {
    if (_answer.isEmpty) return;
    // Найти последний использованный индекс
    final lastLetter = _answer.last;
    for (int i = _scrambled.length - 1; i >= 0; i--) {
      if (_usedIndices[i] && _scrambled[i] == lastLetter) {
        setState(() {
          _usedIndices[i] = false;
          _answer.removeLast();
        });
        return;
      }
    }
  }

  void _checkAnswer() {
    final target = _words[_wordIndex].toUpperCase();
    if (_answer.length < target.length) return;

    final attempt = _answer.join();
    if (attempt == target) {
      // Правильно!
      HapticFeedback.heavyImpact();
      _score += _timeLeft * 5 + 30;
      _solveCtrl.forward(from: 0);
      setState(() => _wordSolved = true);
      _timer?.cancel();

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        final nextIndex = _wordIndex + 1;
        if (nextIndex >= _words.length) {
          _triggerWin();
        } else {
          setState(() => _wordIndex = nextIndex);
          _loadWord(nextIndex);
          _startTimer();
        }
      });
    } else if (_answer.length == target.length) {
      // Все буквы заняты, но ответ неверный
      HapticFeedback.vibrate();
      _shakeCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _answer.clear();
          _usedIndices = List.filled(_scrambled.length, false);
        });
      });
    }
  }

  void _triggerWin() {
    setState(() => _gameWon = true);
    HapticFeedback.heavyImpact();
    _winCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2500), widget.onSuccess);
  }

  void _triggerFail() {
    setState(() => _gameFail = true);
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
          const BgCircle(top: -60, left: -40, size: 160, color: Color(0xFFFFD700), opacity: 0.12),
          const BgCircle(top: 280, left: 200, size: 140, color: kBlue, opacity: 0.1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (_gameWon)
                Expanded(child: _winScreen())
              else if (_gameFail)
                Expanded(child: _failScreen())
              else
                Expanded(child: _buildGameContent()),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    final timeColor = _timeLeft > 15 ? kGreen : (_timeLeft > 7 ? Colors.orange : kRed);
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFFD700)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: kGold.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Row(children: [
          Icon(Icons.abc_rounded, color: Colors.white, size: 18),
          SizedBox(width: 6),
          Text('Собери слово', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
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

  Widget _buildGameContent() {
    return Column(children: [
      // Прогресс слов
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Слово ${_wordIndex + 1} / ${_words.length}',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _wordIndex / _words.length,
          minHeight: 6,
          backgroundColor: Colors.white.withOpacity(0.08),
          valueColor: const AlwaysStoppedAnimation<Color>(kGold),
        ),
      ),
      const SizedBox(height: 24),
      // Поле ответа
      FadeTransition(
        opacity: _wordFade,
        child: AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(_shakeAnim.value, 0),
            child: child,
          ),
          child: _buildAnswerSlots(),
        ),
      ),
      const SizedBox(height: 28),
      // Перемешанные буквы
      _buildScrambledLetters(),
      const Spacer(),
      // Кнопка удалить
      if (_answer.isNotEmpty)
        GestureDetector(
          onTap: _removeLast,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: kRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kRed.withOpacity(0.4)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.backspace_outlined, color: kRed, size: 16),
              SizedBox(width: 8),
              Text('Удалить', style: TextStyle(color: kRed, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        ),
    ]);
  }

  Widget _buildAnswerSlots() {
    final target = _words[_wordIndex].toUpperCase();
    return ScaleTransition(
      scale: _wordSolved ? _solveScale : const AlwaysStoppedAnimation(1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(target.length, (i) {
          final filled = i < _answer.length;
          final correct = _wordSolved;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42, height: 52,
              decoration: BoxDecoration(
                gradient: filled && correct
                    ? const LinearGradient(colors: [Color(0xFF1B5E20), kGreen])
                    : filled
                        ? const LinearGradient(colors: [kBlue, kGreen])
                        : null,
                color: filled ? null : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: filled ? Colors.transparent : Colors.white.withOpacity(0.15),
                  width: 2,
                ),
                boxShadow: filled
                    ? [BoxShadow(color: kBlue.withOpacity(0.3), blurRadius: 8)]
                    : null,
              ),
              child: Center(child: Text(
                filled ? _answer[i] : '_',
                style: TextStyle(
                  color: filled ? Colors.white : Colors.white.withOpacity(0.25),
                  fontSize: 20, fontWeight: FontWeight.w900,
                ),
              )),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScrambledLetters() {
    return Wrap(
      spacing: 10, runSpacing: 10,
      alignment: WrapAlignment.center,
      children: List.generate(_scrambled.length, (i) {
        final used = _usedIndices[i];
        return GestureDetector(
          onTap: used ? null : () => _pickLetter(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48, height: 56,
            decoration: BoxDecoration(
              gradient: used
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF1E3A5F), Color(0xFF0D1F3C)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
              color: used ? Colors.white.withOpacity(0.05) : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: used ? Colors.white.withOpacity(0.06) : kBlue.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: used ? null : [BoxShadow(color: kBlue.withOpacity(0.2), blurRadius: 6)],
            ),
            child: Center(child: Text(
              _scrambled[i],
              style: TextStyle(
                color: used ? Colors.white.withOpacity(0.15) : Colors.white,
                fontSize: 20, fontWeight: FontWeight.w900,
              ),
            )),
          ),
        );
      }),
    );
  }

  // ─── Экраны результата ────────────────────────────────────────────────────
  Widget _winScreen() {
    return ScaleTransition(
      scale: _winScale,
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 110, height: 110,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF6B35), kGold]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: kGold.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
          ),
          child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 60)),
        const SizedBox(height: 24),
        const Text('Все слова собраны!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kGold, Color(0xFFFFA726)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: kGold.withOpacity(0.4), blurRadius: 16)],
          ),
          child: Text('+$_score очков',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 12),
        Text('${_words.length} слов(а) — отличный результат! 🔤',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
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
        const Text('Жизни закончились!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 10),
        Text('Правильное слово: ${_words[_wordIndex]}',
            style: const TextStyle(fontSize: 16, color: kGreen, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Попробуй ещё раз! 💪',
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14)),
      ])),
    );
  }
}