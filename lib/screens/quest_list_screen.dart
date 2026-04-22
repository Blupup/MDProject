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
  final _state = AppState();
  QuestFilter _filter = QuestFilter.all;

  static const _gradients = [
    LinearGradient(colors: [Color(0xFF2D3FCE), Color(0xFF4B76FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFF7B2CFF), Color(0xFFAE5DFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFF00897B), Color(0xFF00BFA5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFFDB5B2F), Color(0xFFFF8C42)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFFAD1457), Color(0xFFE91E63)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  ];

  List<Quest> get _visibleQuests {
    switch (_filter) {
      case QuestFilter.completed:
        return QuestData.quests.where((q) => _state.isQuestCompleted(q.id)).toList();
      case QuestFilter.inProgress:
        return QuestData.quests.where((q) {
          final progress = _state.getQuestProgress(q.id);
          return progress > 0 && !_state.isQuestCompleted(q.id);
        }).toList();
      case QuestFilter.all:
        return QuestData.quests;
    }
  }

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
    final completedCount = QuestData.quests.where((q) => _state.isQuestCompleted(q.id)).length;
    final completion = (completedCount / QuestData.quests.length).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF070B24),
      body: SafeArea(
        child: Stack(
          children: [
            const BgCircle(top: -120, left: -70, size: 260, color: Color(0xFF4B76FF), opacity: 0.30),
            const BgCircle(top: 200, left: 220, size: 190, color: Color(0xFFAE5DFF), opacity: 0.20),
            const BgCircle(top: 530, left: -100, size: 240, color: Color(0xFF00BFA5), opacity: 0.15),
            Column(children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildOverviewCard(completedCount, completion),
              const SizedBox(height: 16),
              _buildFilters(),
              const SizedBox(height: 10),
              Expanded(
                child: FadeTransition(
                  opacity: _entryAnim,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: _visibleQuests.length,
                    itemBuilder: (_, i) {
                      final quest = _visibleQuests[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _QuestCard(
                          quest: quest,
                          gradient: _gradients[i % _gradients.length],
                          index: QuestData.quests.indexOf(quest),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ]),
          ],
        ),
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

  Widget _buildOverviewCard(int completedCount, double completion) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B275A), Color(0xFF11193F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph_rounded, color: Color(0xFF77D7FF), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Прогресс кампании',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '$completedCount/${QuestData.quests.length}',
                style: const TextStyle(color: Color(0xFF6CFFDA), fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.10),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6CFFDA)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Выполнено ${_state.tasksCompleted} заданий',
                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
              ),
              const Spacer(),
              Text(
                '${_state.totalXP} XP',
                style: const TextStyle(color: Color(0xFFFFD86A), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _FilterChip(
            label: 'Все',
            active: _filter == QuestFilter.all,
            onTap: () => setState(() => _filter = QuestFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'В процессе',
            active: _filter == QuestFilter.inProgress,
            onTap: () => setState(() => _filter = QuestFilter.inProgress),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Завершенные',
            active: _filter == QuestFilter.completed,
            onTap: () => setState(() => _filter = QuestFilter.completed),
          ),
        ],
      ),
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
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.32), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.18), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ),
        Positioned(right: -20, top: -20,
          child: Container(width: 100, height: 100,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)))),

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        quest.difficulty,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      quest.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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

enum QuestFilter { all, inProgress, completed }

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: active ? const Color(0xFF3A58E8) : Colors.white.withOpacity(0.08),
            border: Border.all(
              color: active ? const Color(0xFF77D7FF) : Colors.white.withOpacity(0.18),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(active ? 1 : 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
