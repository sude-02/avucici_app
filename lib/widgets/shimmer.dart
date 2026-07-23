import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// ── Shimmer engine ────────────────────────────────────────────────────

class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final base = isDark ? const Color(0xFF1E1E35) : const Color(0xFFE4E4EA);
    final mid = isDark ? const Color(0xFF2E2E50) : const Color(0xFFEDEDF2);
    final highlight = isDark ? const Color(0xFF383860) : const Color(0xFFF6F6FA);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [base, mid, highlight, mid, base],
          stops: [
            (_anim.value - 0.5).clamp(0.0, 1.0),
            (_anim.value - 0.15).clamp(0.0, 1.0),
            _anim.value.clamp(0.0, 1.0),
            (_anim.value + 0.15).clamp(0.0, 1.0),
            (_anim.value + 0.5).clamp(0.0, 1.0),
          ],
        ).createShader(bounds),
        child: widget.child,
      ),
    );
  }
}

// ── Primitives ────────────────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.isDark(context)
            ? const Color(0xFF252542)
            : const Color(0xFFDCDCE4),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Skeleton cards ────────────────────────────────────────────────────

class ShimmerUserCard extends StatelessWidget {
  const ShimmerUserCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const ShimmerBox(width: 48, height: 48, radius: 14),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                      width: MediaQuery.of(context).size.width * 0.38,
                      height: 14,
                      radius: 7),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 80, height: 10, radius: 5),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const ShimmerBox(width: 24, height: 24, radius: 12),
          ],
        ),
      ),
    );
  }
}

class ShimmerTransactionCard extends StatelessWidget {
  const ShimmerTransactionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const ShimmerBox(width: 46, height: 46, radius: 23),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                      width: MediaQuery.of(context).size.width * 0.35,
                      height: 13,
                      radius: 6),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 100, height: 10, radius: 5),
                ],
              ),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShimmerBox(width: 56, height: 14, radius: 7),
                SizedBox(height: 6),
                ShimmerBox(width: 44, height: 10, radius: 5),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerUserListView extends StatelessWidget {
  final int count;
  const ShimmerUserListView({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) => const ShimmerUserCard(),
    );
  }
}

class ShimmerTransactionListView extends StatelessWidget {
  final int count;
  const ShimmerTransactionListView({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) => const ShimmerTransactionCard(),
    );
  }
}
