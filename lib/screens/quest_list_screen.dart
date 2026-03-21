// lib/screens/quest_list_screen.dart
import 'package:flutter/material.dart';
import '../data/quest_data.dart';
import '../data/app_state.dart';
import '../widgets/common_widgets.dart';
import 'quest_detail_screen.dart';

class QuestListScreen extends StatelessWidget {
  const QuestListScreen({super.key});

  static const _gradients = [
    LinearGradient(colors: [Color(0xFF2E86AB), Color(0xFF00D4AA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFF00796B), Color(0xFF26C6DA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFFD700)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFFFF3D71), Color(0xFF9C27B0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(title: 'Квесты'),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: QuestData.quests.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _QuestCard(quest: QuestData.quests[i], gradient: _gradients[i % _gradients.length]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Quest quest;
  final Gradient gradient;

  const _QuestCard({required this.quest, required this.gradient});

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final isCompleted = state.isQuestCompleted(quest.id);
    final progress = state.getQuestProgress(quest.id);

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          // Декоративный круг
          Positioned(right: -20, top: -20,
            child: Container(width: 100, height: 100,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)))),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuestDetailScreen(quest: quest))),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(quest.title,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
                        ),
                        const SizedBox(width: 12),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(12)),
                            child: const Row(mainAxisSize: MainAxisSize.min,
                              children: [Icon(Icons.check_circle_rounded, color: Colors.white, size: 14), SizedBox(width: 4),
                                Text('Пройден', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))]),
                          )
                        else
                          DifficultyWidget(level: quest.difficultyLevel),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(quest.description,
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _chip(Icons.schedule_rounded, quest.duration),
                        const SizedBox(width: 14),
                        _chip(Icons.assignment_rounded, '${quest.taskCount} задания'),
                        const Spacer(),
                        XpBadge(xp: quest.xpReward),
                      ],
                    ),
                    if (!isCompleted && progress > 0) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress / quest.taskCount,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('$progress / ${quest.taskCount} заданий',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.7)),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500)),
      ],
    );
  }
}