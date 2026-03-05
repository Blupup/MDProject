// lib/screens/game_selection_screen.dart
//
// Экран выбора мини-игры. Три карточки на выбор — игрок нажимает любую.
//
import 'package:flutter/material.dart';
import '../data/quest_data.dart';
import '../widgets/common_widgets.dart';
import '../game/disappeared_game.dart';
import '../game/memory_pairs_game.dart';
import '../game/puzzle_game.dart';

class _GameInfo {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final List<Color> colors;
  final String difficulty;
  final IconData icon;
  const _GameInfo({required this.id, required this.title, required this.description,
    required this.emoji, required this.colors, required this.difficulty, required this.icon});
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
    description: 'Переворачивай карточки с фото и находи одинаковые пары!',
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
];

class GameSelectionScreen extends StatefulWidget {
  final QuestTask task;
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const GameSelectionScreen({super.key, required this.task, required this.onSuccess, required this.onFail});
  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen> with TickerProviderStateMixin {
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

    _cardCtrls = List.generate(3, (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 450)));
    _cardAnims = _cardCtrls.map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutBack)).toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: 150 + i * 120), () { if (mounted) _cardCtrls[i].forward(); });
    }
  }

  @override
  void dispose() { _headerCtrl.dispose(); for (final c in _cardCtrls) {
    c.dispose();
  } super.dispose(); }

  void _launch(String gameId) {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => _buildGame(gameId)));
    });
  }

  Widget _buildGame(String id) {
    void ok() { Navigator.pop(context); widget.onSuccess(); }
    void fail() { Navigator.pop(context); widget.onFail(); }
    return switch (id) {
      'disappeared' => DisappearedGame(items: widget.task.miniGameItems, onSuccess: ok, onFail: fail),
      'pairs'       => MemoryPairsGame(items: widget.task.pairPhotos,    onSuccess: ok, onFail: fail),
      'puzzle'      => PuzzleGame(     items: widget.task.puzzlePhotos,  onSuccess: ok, onFail: fail),
      _             => DisappearedGame(items: widget.task.miniGameItems, onSuccess: ok, onFail: fail),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Stack(children: [
          const BgCircle(top: -80, left: -50, size: 200, color: kBlue, opacity: 0.2),
          const BgCircle(top: 350, left: 200, size: 160, color: Color(0xFF6A11CB), opacity: 0.15),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(children: [
              FadeTransition(opacity: _headerAnim, child: _buildHeader()),
              const SizedBox(height: 28),
              Expanded(
                child: Column(children: [
                  for (int i = 0; i < _kGames.length; i++) ...[
                    ScaleTransition(
                      scale: _cardAnims[i],
                      child: FadeTransition(
                        opacity: _cardAnims[i],
                        child: _GameCard(game: _kGames[i], onTap: () => _launch(_kGames[i].id)),
                      ),
                    ),
                    if (i < _kGames.length - 1) const SizedBox(height: 14),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
              Text('Выбери любую игру — после победы задание засчитается',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.35))),
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
          child: Container(width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Выбери мини-игру', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(widget.task.title, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)), overflow: TextOverflow.ellipsis),
        ])),
        Container(width: 48, height: 48,
          decoration: const BoxDecoration(gradient: kGradientMain, shape: BoxShape.circle),
          child: const Icon(Icons.videogame_asset_rounded, color: Colors.white, size: 24)),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07))),
        child: Row(children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [kBlue, kGreen]), borderRadius: BorderRadius.circular(10)),
            child: Icon(widget.task.icon, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.task.description,
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75), height: 1.4))),
        ]),
      ),
    ]);
  }
}

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
    _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _pressScale = Tween(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
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
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp:   (_) { _pressCtrl.reverse(); widget.onTap(); },
        onTapCancel: () => _pressCtrl.reverse(),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.game.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: widget.game.colors[1].withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Stack(children: [
            Positioned(right: -20, top: -20,
              child: Container(width: 90, height: 90,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)))),
            Positioned(right: 16, bottom: 8,
              child: Text(widget.game.emoji, style: const TextStyle(fontSize: 42))),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 80, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Icon(widget.game.icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(widget.game.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                ]),
                Row(children: [
                  Expanded(child: Text(widget.game.description,
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75), height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _diffColor.withOpacity(0.7), width: 1)),
                    child: Text(widget.game.difficulty,
                        style: TextStyle(color: _diffColor, fontSize: 10, fontWeight: FontWeight.w700))),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}