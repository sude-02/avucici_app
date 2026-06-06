import 'package:flutter/material.dart';

class AppRoutes {
  static PageRouteBuilder<T> push<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final slide = Tween(
          begin: const Offset(0.06, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

        final fade = Tween(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        final outFade = Tween(begin: 1.0, end: 0.92)
            .animate(CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn));

        return FadeTransition(
          opacity: outFade,
          child: FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          ),
        );
      },
    );
  }
}
