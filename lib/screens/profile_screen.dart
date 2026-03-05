// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Stack(
          children: [
            const BgCircle(top: -80, left: -60, size: 200, color: kBlue, opacity: 0.2),
            const BgCircle(top: 200, left: 250, size: 160, color: kGreen, opacity: 0.12),
            Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListenableBuilder(
                    listenable: AppState(),
                    builder: (_, __) {
                      final s = AppState();
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        child: Column(
                          children: [
                            _buildAvatarCard(s),
                            const SizedBox(height: 16),
                            _buildStatsCard(s),
                            const SizedBox(height: 16),
                            _buildAchievements(s),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 4),
          const Text('Профиль', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildAvatarCard(AppState s) {
    return AppCard(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120, height: 120,
                child: CircularProgressIndicator(
                  value: s.levelProgress.clamp(0.0, 1.0),
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(kGreen),
                ),
              ),
              Container(
                width: 104, height: 104,
                decoration: const BoxDecoration(gradient: kGradientMain, shape: BoxShape.circle),
                child: Center(child: Text(
                  s.userName.isNotEmpty ? s.userName[0].toUpperCase() : 'И',
                  style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900),
                )),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
                  child: Center(child: Text('${s.level}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(s.userName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [kGold, Color(0xFFFFA726)]), borderRadius: BorderRadius.circular(20)),
            child: Text('⭐ ${s.levelTitle.toUpperCase()}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.8)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _levelItem('Уровень', '${s.level}', Icons.star_rounded, kGold)),
                Container(width: 1, height: 36, color: Colors.white.withOpacity(0.1)),
                Expanded(child: _levelItem('Опыт', '${s.totalXP}/${s.xpForNextLevel}', Icons.bolt_rounded, kGreen)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
      ],
    );
  }

  Widget _buildStatsCard(AppState s) {
    final mins = s.totalMinutes;
    final timeStr = mins < 60 ? '$minsм' : '${mins ~/ 60}ч ${mins % 60}м';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: kGreen, size: 22),
              SizedBox(width: 10),
              Text('Статистика', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(Icons.flag_rounded, '${s.questsCompleted}', 'Квестов\nпройдено', kBlue),
              _statItem(Icons.check_circle_rounded, '${s.tasksCompleted}', 'Заданий\nвыполнено', kGreen),
              _statItem(Icons.timer_rounded, timeStr, 'Время в\nквестах', kRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6), height: 1.3)),
      ],
    );
  }

  Widget _buildAchievements(AppState s) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: kGold, size: 22),
              SizedBox(width: 10),
              Text('Достижения', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          ...s.achievements.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AchievementTile(achievement: a),
          )),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? kBlue.withOpacity(0.12) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: unlocked ? kGreen.withOpacity(0.4) : Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: unlocked ? kGradientMain : null,
              color: unlocked ? null : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(achievement.icon, color: unlocked ? Colors.white : Colors.white.withOpacity(0.3), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: unlocked ? Colors.white : Colors.white.withOpacity(0.4))),
                Text(achievement.description,
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(unlocked ? 0.6 : 0.3))),
              ],
            ),
          ),
          if (unlocked) const Icon(Icons.check_circle_rounded, color: kGreen, size: 20)
          else const Icon(Icons.lock_rounded, color: Colors.white24, size: 18),
        ],
      ),
    );
  }
}