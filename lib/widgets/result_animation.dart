import 'dart:math';
import 'package:flutter/material.dart';

// ── Animated green checkmark ─────────────────────────────────────────

class AnimatedCheck extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedCheck({
    super.key,
    this.size = 80,
    this.color = const Color(0xFF10B981),
  });

  @override
  State<AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<AnimatedCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _CheckPainter(progress: _anim.value, color: widget.color),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Circle scale: 0→1 in first 50%
    final circleP = (progress * 2).clamp(0.0, 1.0);
    final circleR = r * Curves.elasticOut.transform(circleP);

    final bgPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), circleR, bgPaint);

    final borderPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(cx, cy), circleR - 1.2, borderPaint);

    // Checkmark draws after circle is at 40%
    if (progress > 0.4) {
      final checkP = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);

      final p1 = Offset(size.width * 0.22, size.height * 0.52);
      final p2 = Offset(size.width * 0.44, size.height * 0.70);
      final p3 = Offset(size.width * 0.78, size.height * 0.33);

      final seg1 = (p2 - p1).distance;
      final seg2 = (p3 - p2).distance;
      final total = seg1 + seg2;
      final drawn = total * checkP;

      final path = Path()..moveTo(p1.dx, p1.dy);
      if (drawn <= seg1) {
        final t = drawn / seg1;
        path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
      } else {
        path.lineTo(p2.dx, p2.dy);
        final t = min(1.0, (drawn - seg1) / seg2);
        path.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
      }

      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

// ── Animated red cross ───────────────────────────────────────────────

class AnimatedCross extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedCross({
    super.key,
    this.size = 80,
    this.color = Colors.red,
  });

  @override
  State<AnimatedCross> createState() => _AnimatedCrossState();
}

class _AnimatedCrossState extends State<AnimatedCross>
    with TickerProviderStateMixin {
  late final AnimationController _drawCtrl;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _drawAnim;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _drawCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _drawAnim = CurvedAnimation(parent: _drawCtrl, curve: Curves.easeOut);
    _shakeAnim = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut));

    _drawCtrl.forward().then((_) => _shakeCtrl.forward());
  }

  @override
  void dispose() {
    _drawCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_drawAnim, _shakeAnim]),
      builder: (_, __) {
        final shakeOffset = _shakeCtrl.isAnimating
            ? sin(_shakeAnim.value * pi * 4) * 4 * (1 - _shakeAnim.value)
            : 0.0;
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CrossPainter(
                progress: _drawAnim.value, color: widget.color),
          ),
        );
      },
    );
  }
}

class _CrossPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CrossPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final circleP = (progress * 2).clamp(0.0, 1.0);
    final circleR = r * Curves.easeOut.transform(circleP);

    canvas.drawCircle(
      Offset(cx, cy),
      circleR,
      Paint()
        ..color = color.withOpacity(0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      circleR - 1.2,
      Paint()
        ..color = color.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    if (progress > 0.4) {
      final xP = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
      final pad = size.width * 0.28;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      // First arm of X
      final line1P = (xP * 2).clamp(0.0, 1.0);
      final x1s = Offset(pad, pad);
      final x1e = Offset(size.width - pad, size.height - pad);
      canvas.drawLine(
        x1s,
        Offset(x1s.dx + (x1e.dx - x1s.dx) * line1P,
            x1s.dy + (x1e.dy - x1s.dy) * line1P),
        paint,
      );

      // Second arm of X
      if (xP > 0.5) {
        final line2P = ((xP - 0.5) / 0.5).clamp(0.0, 1.0);
        final x2s = Offset(size.width - pad, pad);
        final x2e = Offset(pad, size.height - pad);
        canvas.drawLine(
          x2s,
          Offset(x2s.dx + (x2e.dx - x2s.dx) * line2P,
              x2s.dy + (x2e.dy - x2s.dy) * line2P),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CrossPainter old) => old.progress != progress;
}

// ── Full-screen failure overlay (used in ScanScreen) ─────────────────

class FailureOverlay extends StatefulWidget {
  const FailureOverlay({super.key});

  @override
  State<FailureOverlay> createState() => _FailureOverlayState();
}

class _FailureOverlayState extends State<FailureOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 35),
    ]).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Container(
          color: Colors.red.withOpacity(0.15),
          child: Center(
            child: AnimatedCross(size: 100, color: Colors.red.shade400),
          ),
        ),
      ),
    );
  }
}
