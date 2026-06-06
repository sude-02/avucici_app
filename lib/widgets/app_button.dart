import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, destructive, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.height = 54,
  });

  Color get _bgColor {
    if (onPressed == null && !isLoading) {
      return Colors.white.withOpacity(0.06);
    }
    return switch (variant) {
      AppButtonVariant.primary => const Color(0xFF6C63FF),
      AppButtonVariant.secondary => Colors.white.withOpacity(0.08),
      AppButtonVariant.destructive => const Color(0xFFDC2626),
      AppButtonVariant.ghost => Colors.transparent,
    };
  }

  Color get _fgColor {
    if (onPressed == null && !isLoading) return Colors.white24;
    return switch (variant) {
      AppButtonVariant.primary => Colors.white,
      AppButtonVariant.secondary => Colors.white,
      AppButtonVariant.destructive => Colors.white,
      AppButtonVariant.ghost => const Color(0xFF6C63FF),
    };
  }

  BorderSide? get _border {
    if (variant == AppButtonVariant.secondary) {
      return BorderSide(
        color: onPressed == null
            ? Colors.white.withOpacity(0.12)
            : Colors.white.withOpacity(0.2),
      );
    }
    return null;
  }

  List<BoxShadow>? get _shadows {
    if (onPressed == null || variant != AppButtonVariant.primary) return null;
    return [
      BoxShadow(
        color: const Color(0xFF6C63FF).withOpacity(0.35),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: _shadows,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _bgColor,
            foregroundColor: _fgColor,
            disabledBackgroundColor: Colors.white.withOpacity(0.06),
            disabledForegroundColor: Colors.white24,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: _border ?? BorderSide.none,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: _fgColor,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
