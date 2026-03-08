// lib/screens/game_selection_screen.dart
import 'package:flutter/material.dart';
import '../data/quest_data.dart';
import '../widgets/common_widgets.dart';
import '../game/disappeared_game.dart';
import '../game/memory_pairs_game.dart';
import '../game/puzzle_game.dart';
import '../game/word_scramble_game.dart';
import '../game/planet_hop_game.dart';

class _GameInfo {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final List<Color> colors;
  final String difficulty;
  final IconData icon;
  const _GameInfo({
    required this.id, required this.title, required this.description,
    required this.emoji, required this.colors, required this.difficulty, required this.icon,
  });
}

const _kGames = [
  _GameInfo(
    id: 'disappeared',
    title: 'Найди исчезнувшее',
    description: 'Запомни все предметы — один пропадёт. Успей угадать какой!',
    emoji: '👁️',
    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
    difficulty: 'Средняя',
    icon: Icons.visibility_off_rounded,
  ),
  _GameInfo(
    id: 'pairs',
    title: 'Найди пары',
    description: 'Переворачивай карточки и ищи одинаковые пары — тренируй память!',
    emoji: '🃏',
    colors: [Color(0xFF00796B), Color(0xFF00D4AA)],
    difficulty: 'Лёгкая',
    icon: Icons.photo_library_rounded,
  ),
  _GameInfo(
    id: 'puzzle',
    title: 'Пятнашки',
    description: 'Собери картинку из перемешанных кусочков за 2 минуты!',
    emoji: '🧩',
    colors: [Color(0xFF1565C0), Color(0xFF2E86AB)],
    difficulty: 'Сложная',
    icon: Icons.grid_view_rounded,
  ),
  _GameInfo(
    id: 'scramble',
    title: 'Собери слово',
    description: 'Из перемешанных букв составь правильное слово как можно быстрее!',
    emoji: '🔤',
    colors: [Color(0xFFFF6B35), Color(0xFFFFD700)],
    difficulty: 'Средняя',
    icon: Icons.abc_rounded,
  ),
  _GameInfo(
    id: 'planethop',
    title: 'Межпланетный прыжок',
    description: 'Прыгай между планетами Б-корпуса — поймай момент и лети точно в цель!',
    emoji: '🚀',
    colors: [Color(0xFFFF3D71), Color(0xFFFF6B35)],
    difficulty: 'Сложная',
    icon: Icons.directions_run_rounded,
  ),
];

class GameSelectionScreen extends StatefulWidget {
  final QuestTask task;
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const GameSelectionScreen({
    super.key,
    required this.task,
    required this.onSuccess,
    required this.onFail,
  });

  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _cardCtrls;
  late List<Animation<double>> _cardAnims;
  late AnimationController _headerCtrl;
  late Animation<double> _headerAnim;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _headerAnim = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerCtrl.forward();

    _cardCtrls = List.generate(
      _kGames.length,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 420)),
    );
    _cardAnims = _cardCtrls
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutBack))
        .toList();

    for (int i = 0; i < _kGames.length; i++) {
      Future.delayed(Duration(milliseconds: 120 + i * 90), () {
        if (mounted) _cardCtrls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    for (final c in _cardCtrls) c.dispose();
    super.dispose();
  }

  void _launch(String gameId) {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _buildGame(gameId)),
      );
    });
  }

  Widget _buildGame(String id) {
    void ok()   { Navigator.pop(context); widget.onSuccess(); }
    void fail() { Navigator.pop(context); widget.onFail(); }

    return switch (id) {
      'disappeared' => DisappearedGame(
          items: widget.task.miniGameItems, onSuccess: ok, onFail: fail),
      'pairs'       => MemoryPairsGame(
          items: widget.task.pairPhotos.isNotEmpty
              ? widget.task.pairPhotos
              : widget.task.miniGameItems,
          onSuccess: ok, onFail: fail),
      'puzzle'      => PuzzleGame(
          items: widget.task.puzzlePhotos, onSuccess: ok, onFail: fail),
      'scramble'    => WordScrambleGame(
          items: widget.task.miniGameItems, onSuccess: ok, onFail: fail),
      'planethop'   => PlanetHopGame(onSuccess: ok, onFail: fail),
      _             => DisappearedGame(
          items: widget.task.miniGameItems, onSuccess: ok, onFail: fail),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Stack(children: [
          const BgCircle(top: -80, left: -50, size: 200, color: kBlue, opacity: 0.2),
          const BgCircle(top: 400, left: 200, size: 160, color: Color(0xFF6A11CB), opacity: 0.15),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(children: [
              // Заголовок
              FadeTransition(opacity: _headerAnim, child: _buildHeader()),
              const SizedBox(height: 20),
              // Список игр — прокручиваемый
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: _kGames.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ScaleTransition(
                      scale: _cardAnims[i],
                      child: FadeTransition(
                        opacity: _cardAnims[i],
                        child: _GameCard(
                          game: _kGames[i],
                          onTap: () => _launch(_kGames[i].id),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(children: [
      Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Выбери мини-игру',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(widget.task.title,
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)),
              overflow: TextOverflow.ellipsis),
        ])),
        // Счётчик игр
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: kGradientMain,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('${_kGames.length} игр',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
      const SizedBox(height: 12),
      // Описание задания
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kBlue, kGreen]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.task.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(
            widget.task.description,
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75), height: 1.4),
          )),
        ]),
      ),
      const SizedBox(height: 8),
      // Подсказка прокрутки
      Text(
        'Прокрути вниз чтобы увидеть все игры 👇',
        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3)),
      ),
    ]);
  }
}

// ─── Карточка игры ────────────────────────────────────────────────────────
class _GameCard extends StatefulWidget {
  final _GameInfo game;
  final VoidCallback onTap;
  const _GameCard({required this.game, required this.onTap});

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _pressScale = Tween(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  Color get _diffColor => switch (widget.game.difficulty) {
    'Лёгкая'  => kGreen,
    'Средняя' => const Color(0xFFFFA726),
    _          => kRed,
  };

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pressScale,
      child: GestureDetector(
        onTapDown:   (_) => _pressCtrl.forward(),
        onTapUp:     (_) { _pressCtrl.reverse(); widget.onTap(); },
        onTapCancel: () => _pressCtrl.reverse(),
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.game.colors,
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
              color: widget.game.colors[1].withOpacity(0.32),
              blurRadius: 14, offset: const Offset(0, 5),
            )],
          ),
          child: Stack(children: [
            // Декоративный круг
            Positioned(right: -18, top: -18,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            // Эмодзи
            Positioned(right: 14, bottom: 6,
              child: Text(widget.game.emoji, style: const TextStyle(fontSize: 40))),
            // Контент
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 72, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Заголовок + иконка
                  Row(children: [
                    Icon(widget.game.icon, color: Colors.white, size: 16),
                    const SizedBox(width: 7),
                    Text(widget.game.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  ]),
                  // Описание + сложность
                  Row(children: [
                    Expanded(child: Text(
                      widget.game.description,
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.78), height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    )),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: _diffColor.withOpacity(0.7)),
                      ),
                      child: Text(widget.game.difficulty,
                          style: TextStyle(
                              color: _diffColor, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}