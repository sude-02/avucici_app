import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Kart / container arka planı
  static Color card(BuildContext context) =>
      isDark(context) ? const Color(0xFF1A1A2E) : Colors.white;

  // Ana metin rengi
  static Color text(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  // İkincil metin (%55 opaklık)
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.55);

  // Soluk metin (%38 opaklık)
  static Color textMuted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.38);

  // Kart kenar rengi (%8 opaklık)
  static Color border(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.08);
}
