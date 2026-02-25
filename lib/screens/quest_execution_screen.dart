// lib/screens/quest_execution_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../data/quest_data.dart';
import '../data/app_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/confetti_widget.dart';
import '../game/disappeared_game.dart';

class QuestExecutionScreen extends StatefulWidget {
  final Quest quest;
  const QuestExecutionScreen({super.key, required this.quest});
  @override
  State<QuestExecutionScreen> createState() => _QuestExecutionScreenState();
}

class _QuestExecutionScreenState extends State<QuestExecutionScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _taskDone = false;
  bool _showMiniGame = false;
  bool _showConfetti = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  final _state = AppState();

  late AnimationController _taskCtrl;
  late Animation<double> _taskFade;
  late Animation<Offset> _taskSlide;

  @override
  void initState() {
    super.initState();
    _taskCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _taskFade = CurvedAnimation(parent: _taskCtrl, curve: Curves.easeOut);
    _taskSlide = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _taskCtrl, curve: Curves.easeOut));
    _taskCtrl.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _taskCtrl.dispose();
    super.dispose();
  }

  QuestTask get _task => widget.quest.tasks[_currentIndex];
  int get _total => widget.quest.tasks.length;
  double get _progress => _currentIndex / _total;

  String get _elapsed {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _onComplete() {
    if (_task.hasMiniGame) {
      setState(() => _showMiniGame = true);
    } else {
      _markDone();
    }
  }

  void _markDone() {
    setState(() => _taskDone = true);
    _state.updateQuestProgress(widget.quest.id, _currentIndex + 1);
  }

  void _onGameSuccess() {
    setState(() => _showMiniGame = false);
    _markDone();
  }

  void _onGameFail() {
    setState(() => _showMiniGame = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.close_rounded, color: Colors.white),
        SizedBox(width: 8),
        Text('Попробуй ещё раз!', style: TextStyle(fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: kRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _next() {
    if (_currentIndex < _total - 1) {
      setState(() { _currentIndex++; _taskDone = false; _showMiniGame = false; });
      _taskCtrl.forward(from: 0);
    } else {
      _finishQuest();
    }
  }

  void _finishQuest() {
    _timer?.cancel();
    final mins = _elapsedSeconds ~/ 60;
    _state.completeQuest(widget.quest.id, widget.quest.xpReward, mins);
    setState(() => _showConfetti = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _CompletionDialog(
          quest: widget.quest,
          xp: widget.quest.xpReward,
          elapsed: _elapsed,
          onDone: () {
            Navigator.pop(context);
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showMiniGame) {
      return DisappearedGame(
        items: _task.miniGameItems,
        onSuccess: _onGameSuccess,
        onFail: _onGameFail,
      );
    }

    return ConfettiOverlay(
      active: _showConfetti,
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Column(children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: FadeTransition(
                opacity: _taskFade,
                child: SlideTransition(
                  position: _taskSlide,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    child: Column(children: [
                      _buildTaskCard(),
                      const SizedBox(height: 14),
                      if (_taskDone) _buildSuccessBanner() else _buildInstructions(),
                      if (_task.hasMiniGame && !_taskDone) ...[
                        const SizedBox(height: 14),
                        _buildGameBadge(),
                      ],
                    ]),
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white60), onPressed: _confirmExit),
        Expanded(child: Text(widget.quest.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            overflow: TextOverflow.ellipsis)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.timer_outlined, color: kGreen, size: 14),
            const SizedBox(width: 5),
            Text(_elapsed, style: const TextStyle(color: kGreen, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _showHint,
          child: Container(width: 36, height: 36,
            decoration: const BoxDecoration(gradient: kGradientMain, shape: BoxShape.circle),
            child: const Icon(Icons.lightbulb_outline_rounded, color: Colors.white, size: 18)),
        ),
      ]),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Задание ${_currentIndex + 1} / $_total',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600)),
          Text('${(_progress * 100).round()}%',
              style: const TextStyle(fontSize: 12, color: kGreen, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        Row(children: List.generate(_total, (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < _total - 1 ? 4 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 6,
              decoration: BoxDecoration(
                color: i < _currentIndex ? kGreen : (i == _currentIndex ? kBlue : Colors.white.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ))),
      ]),
    );
  }

  Widget _buildTaskCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _taskDone
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : [kCard, kCardDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: (_taskDone ? kGreen : Colors.white).withOpacity(0.08)),
        boxShadow: [BoxShadow(
          color: (_taskDone ? kGreen : kBlue).withOpacity(0.15),
          blurRadius: 20, offset: const Offset(0, 6),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: _taskDone
                  ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)])
                  : kGradientMain,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_taskDone ? Icons.check_rounded : _task.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_task.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.location_on_rounded, size: 13, color: kGreen),
              const SizedBox(width: 3),
              Expanded(child: Text(_task.location,
                  style: const TextStyle(fontSize: 12, color: kGreen, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis)),
            ]),
          ])),
        ]),
        const SizedBox(height: 14),
        Text(_task.description,
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.88), height: 1.5)),
      ]),
    );
  }

  Widget _buildGameBadge() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF6A11CB).withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6A11CB).withOpacity(0.4)),
      ),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.videogame_asset_rounded, color: Colors.white, size: 20)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Мини-игра: Найди исчезнувшее 👁️',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          Text('Запомни предметы и угадай что пропало',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF2575FC), size: 16),
      ]),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 30),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Задание выполнено! 🎉', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          Text('Отличная работа, продолжай!', style: TextStyle(fontSize: 12, color: Colors.white70)),
        ])),
      ]),
    );
  }

  Widget _buildInstructions() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Как выполнить', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.55))),
        const SizedBox(height: 10),
        _instrRow(Icons.directions_walk_rounded, 'Следуй к указанному месту'),
        const SizedBox(height: 8),
        _instrRow(Icons.search_rounded, 'Внимательно осмотрись вокруг'),
        const SizedBox(height: 8),
        _instrRow(Icons.lightbulb_outline_rounded, 'Используй подсказку если нужно'),
        const SizedBox(height: 8),
        _instrRow(Icons.touch_app_rounded, 'Нажми кнопку когда найдёшь'),
      ]),
    );
  }

  Widget _instrRow(IconData icon, String text) {
    return Row(children: [
      Container(width: 30, height: 30,
        decoration: BoxDecoration(color: kBlue.withOpacity(0.13), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 15, color: kGreen)),
      const SizedBox(width: 10),
      Text(text, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.65))),
    ]);
  }

  Widget _buildBottomBar() {
    final isLast = _currentIndex == _total - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      child: Row(children: [
        if (_currentIndex > 0) ...[
          Container(width: 50, height: 50,
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08))),
            child: Material(color: Colors.transparent,
              child: InkWell(borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() { _currentIndex--; _taskDone = false; _showMiniGame = false; }),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white60)))),
          const SizedBox(width: 12),
        ],
        Expanded(child: GradientButton(
          text: _taskDone
              ? (isLast ? 'Завершить квест 🎉' : 'Следующее задание')
              : (_task.hasMiniGame ? 'Начать мини-игру 🎮' : 'Я нашёл это место ✓'),
          icon: _taskDone
              ? (isLast ? Icons.celebration_rounded : Icons.arrow_forward_rounded)
              : (_task.hasMiniGame ? Icons.videogame_asset_rounded : Icons.check_rounded),
          onTap: _taskDone ? _next : _onComplete,
          colors: _taskDone
              ? [const Color(0xFF2E7D32), const Color(0xFF4CAF50)]
              : (_task.hasMiniGame
                  ? [const Color(0xFF6A11CB), const Color(0xFF2575FC)]
                  : [kBlue, kGreen]),
          height: 56, fontSize: 15,
        )),
      ]),
    );
  }

  void _showHint() {
    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 54, height: 54,
          decoration: const BoxDecoration(gradient: kGradientMain, shape: BoxShape.circle),
          child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 26)),
        const SizedBox(height: 14),
        const Text('Подсказка', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 12),
        Text(_task.hint, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.5)),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity,
          child: GradientButton(text: 'Понятно', onTap: () => Navigator.pop(context), height: 46, fontSize: 14)),
      ])),
    ));
  }

  void _confirmExit() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Выйти из квеста?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      content: const Text('Прогресс сессии не сохранится', style: TextStyle(color: Colors.white60)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: kGreen))),
        TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Выйти', style: TextStyle(color: kRed))),
      ],
    ));
  }
}

// ─── Диалог завершения с анимацией ────────────────────────────────────────
class _CompletionDialog extends StatefulWidget {
  final Quest quest;
  final int xp;
  final String elapsed;
  final VoidCallback onDone;
  const _CompletionDialog({required this.quest, required this.xp, required this.elapsed, required this.onDone});
  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<double> _emojiScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scale = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade  = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.easeOut));
    _emojiScale = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0, curve: Curves.elasticOut)));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Dialog(
          backgroundColor: kCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Большой эмодзи квеста
              ScaleTransition(
                scale: _emojiScale,
                child: Text(widget.quest.emoji, style: const TextStyle(fontSize: 64)),
              ),
              const SizedBox(height: 8),
              const Text('Квест завершён!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 6),
              Text(widget.quest.title,
                  style: const TextStyle(fontSize: 14, color: Colors.white54),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              // Статистика
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(16)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _stat('⚡', '+${widget.xp}', 'XP'),
                  Container(width: 1, height: 44, color: Colors.white.withOpacity(0.08)),
                  _stat('⏱️', widget.elapsed, 'Время'),
                  Container(width: 1, height: 44, color: Colors.white.withOpacity(0.08)),
                  _stat('✅', '${widget.quest.taskCount}/${widget.quest.taskCount}', 'Задания'),
                ]),
              ),
              const SizedBox(height: 22),
              SizedBox(width: double.infinity,
                child: GradientButton(text: 'Получить награду!', icon: Icons.workspace_premium_rounded, onTap: widget.onDone, height: 56)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _stat(String emoji, String val, String label) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 4),
      Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
    ]);
  }
}