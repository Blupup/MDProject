// lib/screens/quest_detail_screen.dart
import 'package:flutter/material.dart';
import '../data/quest_data.dart';
import '../widgets/common_widgets.dart';
import 'quest_execution_screen.dart';

class QuestDetailScreen extends StatelessWidget {
  final Quest quest;
  const QuestDetailScreen({super.key, required this.quest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(title: 'Детали квеста'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(),
                    const SizedBox(height: 20),
                    _buildInfoRow(),
                    const SizedBox(height: 24),
                    _buildTasksSection(),
                  ],
                ),
              ),
            ),
            _buildStartButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return AppCard(
      gradient: const LinearGradient(colors: [kBlue, kGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(quest.title,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2))),
              XpBadge(xp: quest.xpReward),
            ],
          ),
          const SizedBox(height: 10),
          Text(quest.description, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        Expanded(child: _infoCard(Icons.schedule_rounded, quest.duration, 'Время')),
        const SizedBox(width: 12),
        Expanded(child: _infoCard(Icons.assignment_rounded, '${quest.taskCount}', 'Задания')),
        const SizedBox(width: 12),
        Expanded(child: _infoCard(Icons.auto_awesome_rounded, quest.difficulty, 'Сложность')),
      ],
    );
  }

  Widget _infoCard(IconData icon, String value, String label) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, color: kGreen, size: 22),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 22, decoration: BoxDecoration(gradient: kGradientMain, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            const Text('Задания', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 16),
        ...quest.tasks.asMap().entries.map((e) => Padding(
          padding: EdgeInsets.only(bottom: e.key < quest.tasks.length - 1 ? 12 : 0),
          child: _TaskItem(task: e.value, isLast: e.key == quest.tasks.length - 1),
        )),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        child: GradientButton(
          text: 'Начать квест',
          icon: Icons.play_arrow_rounded,
          onTap: () => _showStoryIntro(context),
          height: 62,
        ),
      ),
    );
  }

  void _showStoryIntro(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF151A3A), Color(0xFF1E2344)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kGreen.withOpacity(0.4), width: 1.5),
            boxShadow: [BoxShadow(color: kGreen.withOpacity(0.15), blurRadius: 30)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Иконка терминала
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: kGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kGreen.withOpacity(0.4)),
                ),
                child: const Icon(Icons.terminal_rounded, color: kGreen, size: 28),
              ),
              const SizedBox(height: 16),
              Text(quest.emoji,
                  style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(quest.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 16),
              // Текст в стиле терминала
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kGreen.withOpacity(0.2)),
                ),
                child: Text(
                  '> ${quest.storyIntro.replaceAll('\n', '\n> ')}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: kGreen,
                    fontFamily: 'monospace',
                    height: 1.7,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.15))),
                    ),
                    child: Text('Назад',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GradientButton(
                    text: 'Начать',
                    icon: Icons.rocket_launch_rounded,
                    height: 50,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => QuestExecutionScreen(quest: quest)));
                    },
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final QuestTask task;
  final bool isLast;
  const _TaskItem({required this.task, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(gradient: kGradientMain, shape: BoxShape.circle),
              child: Center(child: Text('${task.number}',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800))),
            ),
            if (!isLast) Container(width: 2, height: 40, color: Colors.white.withOpacity(0.1)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: kBlue.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Icon(task.icon, color: kGreen, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(task.title,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
                          if (task.hasMiniGame)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Text('Игра', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(task.description, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6), height: 1.4)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 12, color: kGreen),
                          const SizedBox(width: 3),
                          Text(task.location, style: const TextStyle(fontSize: 11, color: kGreen, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}