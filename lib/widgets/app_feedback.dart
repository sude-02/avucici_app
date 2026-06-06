import 'package:flutter/material.dart';

enum FeedbackType { success, error, warning, info }

class AppFeedback {
  static void success(BuildContext context, String message) =>
      _show(context, message: message, type: FeedbackType.success);

  static void error(BuildContext context, String message) =>
      _show(context, message: message, type: FeedbackType.error);

  static void warning(BuildContext context, String message) =>
      _show(context, message: message, type: FeedbackType.warning);

  static void info(BuildContext context, String message) =>
      _show(context, message: message, type: FeedbackType.info);

  static void _show(
    BuildContext context, {
    required String message,
    required FeedbackType type,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: _ToastContent(message: message, type: type),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          padding: EdgeInsets.zero,
          duration: duration,
        ),
      );
  }
}

class _ToastContent extends StatelessWidget {
  final String message;
  final FeedbackType type;

  const _ToastContent({required this.message, required this.type});

  Color get _bgColor => switch (type) {
        FeedbackType.success => const Color(0xFF065F46),
        FeedbackType.error => const Color(0xFF7F1D1D),
        FeedbackType.warning => const Color(0xFF78350F),
        FeedbackType.info => const Color(0xFF1E1B4B),
      };

  Color get _iconBg => switch (type) {
        FeedbackType.success => const Color(0xFF10B981),
        FeedbackType.error => const Color(0xFFEF4444),
        FeedbackType.warning => const Color(0xFFF59E0B),
        FeedbackType.info => const Color(0xFF6C63FF),
      };

  IconData get _icon => switch (type) {
        FeedbackType.success => Icons.check_circle_rounded,
        FeedbackType.error => Icons.error_rounded,
        FeedbackType.warning => Icons.warning_rounded,
        FeedbackType.info => Icons.info_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _iconBg.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _iconBg.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _iconBg, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
