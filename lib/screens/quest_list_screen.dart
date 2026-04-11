// lib/screens/quest_list_screen.dart
import 'package:flutter/material.dart';
import '../data/quest_data.dart';
import '../data/app_state.dart';
import '../widgets/common_widgets.dart';
import 'quest_detail_screen.dart';
import 'legend_screen.dart';

class QuestListScreen extends StatefulWidget {
  const QuestListScreen({super.key});

  @override
  State<QuestListScreen> createState() => _QuestListScreenState();
}

class _QuestListScreenState extends State<QuestListScreen> with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;

  static const _gradients = [
    LinearGradient(colors: [Color(0xFF2E86AB), Color(0xFF00D4AA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFF00796B), Color(0xFF26C6DA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFFD700)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFFFF3D71), Color(0xFF9C27B0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    // Показываем легенду при первом входе
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!AppState().hasSeenLegend) {
        AppState().markLegendSeen();
        _showLegend();
      } else {
        _entryCtrl.forward();
      }
    });
  }

  @override
  void dispose() { _entryCtrl.dispose(); super.dispose(); }

  void _showLegend() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LegendScreen(
          onDone: () {
            Navigator.pop(context);
            _entryCtrl.forward(from: 0);
          },
        ),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: FadeTransition(
              opacity: _entryAnim,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: QuestData.quests.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _QuestCard(
                    quest: QuestData.quests[i],
                    gradient: _gradients[i % _gradients.length],
                    index: i,
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 4),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 4),
        const Text('Квесты',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
        const Spacer(),
        // Кнопка «Читать легенду снова»
        GestureDetector(
          onTap: _showLegend,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kGreen.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.history_edu_rounded, color: kGreen, size: 14),
              const SizedBox(width: 5),
              Text('Легенда', style: TextStyle(color: kGreen, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Quest quest;
  final Gradient gradient;
  final int index;

  const _QuestCard({required this.quest, required this.gradient, required this.index});

  @override
  Widget build(BuildContext context) {
    final state      = AppState();
    final isCompleted = state.isQuestCompleted(quest.id);
    final progress   = state.getQuestProgress(quest.id);

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(children: [
        // Декоративный круг
        Positioned(right: -20, top: -20,
          child: Container(width: 100, height: 100,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)))),

        // Номер фрагмента
        Positioned(right: 16, bottom: 16,
          child: Text(quest.fragmentEmoji,
              style: TextStyle(fontSize: 32, color: Colors.white.withOpacity(0.12)))),

        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => QuestDetailScreen(quest: quest))),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  // Номер уровня
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text('${index + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(quest.title,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2))),
                  const SizedBox(width: 10),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Пройден', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    )
                  else
                    DifficultyWidget(level: quest.difficultyLevel),
                ]),
                const SizedBox(height: 8),
                Text(quest.description,
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 14),
                Row(children: [
                  _chip(Icons.schedule_rounded, quest.duration),
                  const SizedBox(width: 14),
                  _chip(Icons.assignment_rounded, '${quest.taskCount} задания'),
                  const Spacer(),
                  XpBadge(xp: quest.xpReward),
                ]),
                if (!isCompleted && progress > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / quest.taskCount,
                      minHeight: 5,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text('$progress / ${quest.taskCount} заданий',
                      style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11)),
                ],
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: Colors.white.withOpacity(0.7)),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500)),
    ]);
  }
}
