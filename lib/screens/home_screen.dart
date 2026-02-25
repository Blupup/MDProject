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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Stack(
          children: [
            const BgCircle(top: -80, left: -60, size: 220, color: kBlue, opacity: 0.25),
            const BgCircle(top: 300, left: -100, size: 180, color: kGreen, opacity: 0.15),
            const BgCircle(top: -60, left: 200, size: 150, color: Color(0xFF6A11CB), opacity: 0.15),
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildXpCard(),
                      const SizedBox(height: 28),
                      _buildMenuCards(),
                      const Spacer(),
                      _buildStartButton(),
                      const SizedBox(height: 16),
                      Text('Открой тайны Б-корпуса', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.4))),
                      const SizedBox(height: 8),
                    ],
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
      children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(colors: [kBlue, kGreen]).createShader(b),
          child: const Text('Б-КОРПУС', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3)),
        ),
        const Text('КВЕСТ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kGreen, letterSpacing: 5)),
        const SizedBox(height: 6),
        Text('Исследуй • Узнавай • Открывай',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.55), letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildXpCard() {
    return ListenableBuilder(
      listenable: _state,
      builder: (_, __) => AppCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: const BoxDecoration(gradient: kGradientMain, shape: BoxShape.circle),
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
                          style: const TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_state.levelProgress).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(kGreen),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCards() {
    return Row(
      children: [
        Expanded(child: _MenuCard(
          icon: Icons.map_rounded,
          label: 'Карта',
          subtitle: 'Найди путь',
          gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
          onTap: () => _go(const MapScreen()),
        )),
        const SizedBox(width: 16),
        Expanded(child: _MenuCard(
          icon: Icons.person_rounded,
          label: 'Профиль',
          subtitle: 'Достижения',
          gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
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
      height: 110,
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
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
                Icon(icon, color: Colors.white, size: 28),
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