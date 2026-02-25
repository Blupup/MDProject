// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';

// ─── Константы цветов ─────────────────────────────────────────────────────
const kBg = Color(0xFF0A0F2D);
const kCard = Color(0xFF151A3A);
const kCardDark = Color(0xFF1E2344);
const kBlue = Color(0xFF2E86AB);
const kGreen = Color(0xFF00D4AA);
const kRed = Color(0xFFFF6B6B);
const kGold = Color(0xFFFFD700);

const kGradientMain = LinearGradient(
  colors: [kBlue, kGreen],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ─── Кнопка с градиентом ──────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;
  final List<Color> colors;
  final double height;
  final double fontSize;

  const GradientButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.colors = const [kBlue, kGreen],
    this.height = 60,
    this.fontSize = 17,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors.last.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, color: Colors.white, size: 22), const SizedBox(width: 8)],
                Text(text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Карточка ─────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Gradient? gradient;

  const AppCard({super.key, required this.child, this.padding, this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient ?? const LinearGradient(colors: [kCard, kCardDark], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────
class AppHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final Widget? trailing;

  const AppHeader({super.key, required this.title, this.showBack = true, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [kBg, kCard.withOpacity(0.5)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          const SizedBox(width: 4),
          Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Фоновый декоративный круг ────────────────────────────────────────────
class BgCircle extends StatelessWidget {
  final double top, left, size;
  final Color color;
  final double opacity;

  const BgCircle({super.key, required this.top, required this.left, required this.size, required this.color, this.opacity = 0.2});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, left: left,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withOpacity(opacity), Colors.transparent]),
        ),
      ),
    );
  }
}

// ─── XP Badge ─────────────────────────────────────────────────────────────
class XpBadge extends StatelessWidget {
  final int xp;
  const XpBadge({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [kGold, Color(0xFFFFA726)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text('+$xp XP', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Difficulty stars ─────────────────────────────────────────────────────
class DifficultyWidget extends StatelessWidget {
  final int level;
  const DifficultyWidget({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Icon(
        Icons.star_rounded,
        size: 16,
        color: i < level ? kGold : Colors.white.withOpacity(0.2),
      )),
    );
  }
}
