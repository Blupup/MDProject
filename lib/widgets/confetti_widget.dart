// lib/widgets/confetti_widget.dart
import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool active;

  const ConfettiOverlay({super.key, required this.child, this.active = false});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  final _rng = Random();
  late List<_Particle> _particles;

  static const _colors = [
    Color(0xFF00D4AA), Color(0xFF2E86AB), Color(0xFFFF6B6B),
    Color(0xFFFFD700), Color(0xFF6A11CB), Color(0xFF2575FC),
    Color(0xFFFF8E53),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _particles = List.generate(80, (_) => _Particle(_rng, _colors));
    if (widget.active) _ctrl.forward();
  }

  @override
  void didUpdateWidget(ConfettiOverlay old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _particles = List.generate(80, (_) => _Particle(_rng, _colors));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.active)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(_particles, _ctrl.value),
              ),
            ),
          ),
      ],
    );
  }
}

class _Particle {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final Color color;
  final double rotationSpeed;
  final double drift;
  final bool isSquare;

  _Particle(Random rng, List<Color> colors)
      : x = rng.nextDouble(),
        startY = -0.1 - rng.nextDouble() * 0.5,
        speed = 0.3 + rng.nextDouble() * 0.5,
        size = 4 + rng.nextDouble() * 8,
        color = colors[rng.nextInt(colors.length)],
        rotationSpeed = (rng.nextDouble() - 0.5) * 10,
        drift = (rng.nextDouble() - 0.5) * 0.1,
        isSquare = rng.nextBool();
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = ((progress * p.speed + (-p.startY)) ).clamp(0.0, 1.0);
      final y = size.height * (p.startY + t * 1.4);
      final x = size.width * (p.x + p.drift * t);
      final opacity = (1 - (t * t)).clamp(0.0, 1.0);

      final paint = Paint()..color = p.color.withOpacity(opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotationSpeed * t * 3.14);

      if (p.isSquare) {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6), paint);
      } else {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
