// lib/screens/quest_detail_screen.dart
import 'package:flutter/material.dart';
import '../data/quest_data.dart';
import '../widgets/common_widgets.dart';
import 'quest_execution_screen.dart';
import 'dart:math';

class QuestDetailScreen extends StatelessWidget {
  final Quest quest;
  const QuestDetailScreen({super.key, required this.quest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(children: [
          const AppHeader(title: 'Детали квеста'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildHero(),
                const SizedBox(height: 20),
                _buildInfoRow(),
                const SizedBox(height: 20),
                _buildFragment(),
                const SizedBox(height: 24),
                _buildTasksSection(),
              ]),
            ),
          ),
          _buildStartButton(context),
        ]),
      ),
    );
  }

  Widget _buildHero() {
    return AppCard(
      gradient: const LinearGradient(colors: [kBlue, kGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(quest.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(child: Text(quest.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2))),
          XpBadge(xp: quest.xpReward),
        ]),
        const SizedBox(height: 12),
        Text(quest.description,
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.88), height: 1.55)),
      ]),
    );
  }

  Widget _buildInfoRow() {
    return Row(children: [
      Expanded(child: _infoCard(Icons.schedule_rounded, quest.duration, 'Время')),
      const SizedBox(width: 10),
      Expanded(child: _infoCard(Icons.assignment_rounded, '${quest.taskCount}', 'Задания')),
      const SizedBox(width: 10),
      Expanded(child: _infoCard(Icons.auto_awesome_rounded, quest.difficulty, 'Сложность')),
    ]);
  }

  Widget _infoCard(IconData icon, String value, String label) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        Icon(icon, color: kGreen, size: 20),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10)),
      ]),
    );
  }

  Widget _buildFragment() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kGold.withOpacity(0.12), kCard],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGold.withOpacity(0.3)),
      ),
      child: Row(children: [
        Text(quest.fragmentEmoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Награда за прохождение',
              style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4), letterSpacing: 1)),
          Text(quest.fragmentName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kGold)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: kGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kGold.withOpacity(0.4)),
          ),
          child: Text('+${quest.xpReward} XP',
              style: const TextStyle(color: kGold, fontSize: 12, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }

  Widget _buildTasksSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 4, height: 22,
            decoration: BoxDecoration(gradient: kGradientMain, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        const Text('Задания', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
      ]),
      const SizedBox(height: 16),
      ...quest.tasks.asMap().entries.map((e) => Padding(
        padding: EdgeInsets.only(bottom: e.key < quest.tasks.length - 1 ? 12 : 0),
        child: _TaskItem(task: e.value, isLast: e.key == quest.tasks.length - 1),
      )),
    ]);
  }

  Widget _buildStartButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        child: GradientButton(
          text: 'Начать квест',
          icon: Icons.play_arrow_rounded,
          onTap: () => _showQuestIntro(context),
          height: 62,
        ),
      ),
    );
  }

  // ─── Красивое интро для каждого квеста ───────────────────────────────────
  void _showQuestIntro(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.92),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) => _QuestIntroDialog(quest: quest),
    );
  }
}

// ─── Диалог-интро для квеста ──────────────────────────────────────────────
class _QuestIntroDialog extends StatefulWidget {
  final Quest quest;
  const _QuestIntroDialog({required this.quest});

  @override
  State<_QuestIntroDialog> createState() => _QuestIntroDialogState();
}

class _QuestIntroDialogState extends State<_QuestIntroDialog>
    with TickerProviderStateMixin {

  late AnimationController _glowCtrl, _lineCtrl, _particleCtrl;
  late Animation<double> _glowAnim, _lineAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _lineCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _particleCtrl= AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

    _glowAnim = Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _lineAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _lineCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose(); _lineCtrl.dispose(); _particleCtrl.dispose();
    super.dispose();
  }

  void _launch() {
    Navigator.pop(context);
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => QuestExecutionScreen(quest: widget.quest)));
  }

  @override
  Widget build(BuildContext context) {
    final quest = widget.quest;

    return Material(
      color: Colors.transparent,
      child: Stack(children: [
        // Анимированные частицы на фоне
        AnimatedBuilder(
          animation: _particleCtrl,
          builder: (_, __) => CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _IntroParticlePainter(progress: _particleCtrl.value),
          ),
        ),

        // Центральный контент
        Center(child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // Эмодзи квеста с пульсирующим кольцом
              AnimatedBuilder(animation: _glowAnim, builder: (_, __) =>
                Stack(alignment: Alignment.center, children: [
                  Container(
                    width: 100 + 10 * _glowAnim.value,
                    height: 100 + 10 * _glowAnim.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kGreen.withOpacity(0.2 * _glowAnim.value),
                        width: 2,
                      ),
                    ),
                  ),
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kGreen.withOpacity(0.08),
                      border: Border.all(color: kGreen.withOpacity(0.4 * _glowAnim.value), width: 2),
                      boxShadow: [BoxShadow(
                        color: kGreen.withOpacity(0.15 * _glowAnim.value),
                        blurRadius: 20, spreadRadius: 4,
                      )],
                    ),
                    child: Center(child: Text(quest.emoji, style: const TextStyle(fontSize: 40))),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // Заголовок
              Text(quest.title, textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white,
                    letterSpacing: 0.5, height: 1.2,
                  )),
              const SizedBox(height: 6),

              // Фрагмент
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: kGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kGold.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(quest.fragmentEmoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(quest.fragmentName,
                      style: const TextStyle(color: kGold, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(height: 24),

              // Декоративная линия — анимированная
              AnimatedBuilder(animation: _lineAnim, builder: (_, __) {
                final w = MediaQuery.of(context).size.width - 80;
                return ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: _lineAnim.value,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(height: 1, width: w * 0.35, color: kGreen.withOpacity(0.3)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(width: 6, height: 6,
                            decoration: BoxDecoration(color: kGreen, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: kGreen, blurRadius: 8)]))),
                      Container(height: 1, width: w * 0.35, color: kGreen.withOpacity(0.3)),
                    ]),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Текст предыстории в стиле терминала
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kGreen.withOpacity(0.2), width: 1),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 6, height: 6,
                        decoration: BoxDecoration(color: kGreen, shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: kGreen, blurRadius: 4)])),
                    const SizedBox(width: 8),
                    Text('СИСТЕМА > БРИФИНГ',
                        style: TextStyle(color: kGreen.withOpacity(0.5), fontSize: 9, letterSpacing: 2)),
                  ]),
                  const SizedBox(height: 14),
                  Text(
                    quest.storyIntro,
                    style: const TextStyle(
                      color: kGreen, fontSize: 14, height: 1.85,
                      fontFamily: 'monospace', fontWeight: FontWeight.w500,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 28),

              // Кнопки
              GradientButton(
                text: 'Активировать уровень →',
                icon: Icons.rocket_launch_rounded,
                onTap: _launch,
                height: 56,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text('Вернуться назад',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
              ),
            ]),
          ),
        )),
      ]),
    );
  }
}

// ─── Частицы для интро ────────────────────────────────────────────────────
class _IntroParticlePainter extends CustomPainter {
  final double progress;
  static final _rng = Random(42);

  _IntroParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 30; i++) {
      final x = _rng.nextDouble() * size.width;
      final baseY = _rng.nextDouble() * size.height;
      final t = (progress + i / 30) % 1.0;
      final y = baseY - t * 60;
      final opacity = sin(t * pi) * 0.25;
      canvas.drawCircle(Offset(x, y), 1.5,
          Paint()..color = kGreen.withOpacity(opacity));
    }
  }

  @override
  bool shouldRepaint(_IntroParticlePainter old) => old.progress != progress;
}

// ─── Элемент задания ──────────────────────────────────────────────────────
class _TaskItem extends StatelessWidget {
  final QuestTask task;
  final bool isLast;
  const _TaskItem({required this.task, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(gradient: kGradientMain, shape: BoxShape.circle),
          child: Center(child: Text('${task.number}',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800))),
        ),
        if (!isLast) Container(width: 2, height: 40, color: Colors.white.withOpacity(0.1)),
      ]),
      const SizedBox(width: 14),
      Expanded(child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: kBlue.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(task.icon, color: kGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(task.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
              if (task.hasMiniGame)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Игра', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
            ]),
            const SizedBox(height: 4),
            Text(task.description,
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6), height: 1.4)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_rounded, size: 12, color: kGreen),
              const SizedBox(width: 3),
              Text(task.location,
                  style: const TextStyle(fontSize: 11, color: kGreen, fontWeight: FontWeight.w500)),
            ]),
          ])),
        ]),
      )),
    ]);
  }
}