// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../widgets/common_widgets.dart';
import 'quest_list_screen.dart';
import 'profile_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  final _state = AppState();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _go(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  int get _dailyMissionTarget => 3;
  int get _dailyMissionProgress => _state.questsCompleted.clamp(0, _dailyMissionTarget);
  double get _dailyMissionRatio => (_dailyMissionProgress / _dailyMissionTarget).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140A2E),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3B126B),
                      const Color(0xFF1F1651),
                      const Color(0xFF140A2E),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            const BgCircle(top: -130, left: -90, size: 300, color: Color(0xFFFF7A59), opacity: 0.28),
            const BgCircle(top: -60, left: 180, size: 250, color: Color(0xFFFF4ECD), opacity: 0.24),
            const BgCircle(top: 300, left: -100, size: 240, color: Color(0xFF60C1FF), opacity: 0.20),
            const BgCircle(top: 500, left: 220, size: 210, color: Color(0xFFFFD15C), opacity: 0.16),
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ListenableBuilder(
                    listenable: _state,
                    builder: (_, __) => SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          _buildHeader(),
                          const SizedBox(height: 18),
                          _buildHeroCard(),
                          const SizedBox(height: 16),
                          _buildDailyMissionCard(),
                          const SizedBox(height: 16),
                          _buildXpCard(),
                          const SizedBox(height: 14),
                          _buildQuickStats(),
                          const SizedBox(height: 18),
                          _buildMenuCards(),
                          const SizedBox(height: 22),
                          _buildStartButton(),
                          const SizedBox(height: 14),
                          Center(
                            child: Text(
                              'Добро пожаловать в атмосферу Б-корпуса',
                              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.50)),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB26B).withOpacity(0.22),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD9A4).withOpacity(0.45)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFFF0C2), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Серия: ${_state.tasksCompleted > 0 ? _state.tasksCompleted : 1} дн.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF4ECD), Color(0xFF8C6BFF)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 17),
                  const SizedBox(width: 6),
                  Text(
                    _state.level >= 6 ? 'Legend' : 'Elite',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(colors: [Color(0xFFFFE59A), Color(0xFFFF83C9)]).createShader(b),
          child: const Text('Б-КОРПУС', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3)),
        ),
        const Text('КВЕСТ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFFFD4F7), letterSpacing: 5)),
        const SizedBox(height: 6),
        Text('Исследуй • Узнавай • Вдохновляйся',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.72), letterSpacing: 1.3)),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6C8D), Color(0xFFFF9558), Color(0xFFFFC35A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7E6C).withOpacity(0.42),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Сегодня отличный день для нового квеста!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Твоя энергия на максимуме, а Б-корпус уже ждет тебя внутри приключения.',
                  style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.28),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMissionCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _go(const QuestListScreen()),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF7B42FF), Color(0xFFEC4899), Color(0xFFFF8A43)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFBC5CFF).withOpacity(0.36),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Миссия дня',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '+120 XP',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Пройди $_dailyMissionTarget квеста и открой бонусный фрагмент истории',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _dailyMissionRatio,
                  minHeight: 7,
                  backgroundColor: Colors.white.withOpacity(0.22),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFF6D2)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Прогресс: $_dailyMissionProgress / $_dailyMissionTarget квеста',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildXpCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.10),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 54, height: 54,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF66C8FF), Color(0xFF57F2C8)]),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text('${_state.level}',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_state.levelTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('${_state.totalXP} / ${_state.xpForNextLevel} XP',
                        style: const TextStyle(color: Color(0xFF7DF2D4), fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_state.levelProgress).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.14),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7DF2D4)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final questsTotal = 5;
    final rating = (_state.totalXP / 10).floor() + 1;
    final energy = (100 - (_state.totalMinutes / 2)).clamp(20, 100).toInt();
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.stars_rounded,
            title: 'Рейтинг',
            value: '#$rating',
            color: const Color(0xFFFFD86A),
            onTap: () => _go(const ProfileScreen()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.flag_rounded,
            title: 'Квестов',
            value: '${_state.questsCompleted}/$questsTotal',
            color: const Color(0xFF77D7FF),
            onTap: () => _go(const QuestListScreen()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.bolt_rounded,
            title: 'Энергия',
            value: '$energy%',
            color: const Color(0xFF6CFFDA),
            onTap: () => _go(const MapScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCards() {
    return Row(
      children: [
        Expanded(child: _MenuCard(
          icon: Icons.map_rounded,
          label: 'Карта',
          subtitle: 'Найди путь',
          gradient: const LinearGradient(colors: [Color(0xFF6F46FF), Color(0xFF3F88FF)]),
          onTap: () => _go(const MapScreen()),
        )),
        const SizedBox(width: 16),
        Expanded(child: _MenuCard(
          icon: Icons.person_rounded,
          label: 'Профиль',
          subtitle: 'Достижения',
          gradient: const LinearGradient(colors: [Color(0xFFFF4B9E), Color(0xFFFF8B54)]),
          onTap: () => _go(const ProfileScreen()),
        )),
      ],
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: GradientButton(
        text: 'Начать приключение',
        icon: Icons.rocket_launch_rounded,
        colors: const [Color(0xFFFF5F7A), Color(0xFFFF9360), Color(0xFFFFCC5A)],
        onTap: () => _go(const QuestListScreen()),
        height: 64,
        fontSize: 18,
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _MenuCard({required this.icon, required this.label, required this.subtitle, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 8))]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 28),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_outward_rounded, color: Colors.white, size: 14),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 10),
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.68), fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}