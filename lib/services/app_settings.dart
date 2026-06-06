import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const _keyThreshold = 'match_threshold';
  static const _keyDarkMode = 'dark_mode';
  static const _keyLanguage = 'language';

  static late SharedPreferences _prefs;

  static final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);
  static final languageNotifier = ValueNotifier<String>('tr');
  static final thresholdNotifier = ValueNotifier<double>(0.6);

  static Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final dark = _prefs.getBool(_keyDarkMode) ?? true;
    final lang = _prefs.getString(_keyLanguage) ?? 'tr';
    final threshold = _prefs.getDouble(_keyThreshold) ?? 0.6;
    themeNotifier.value = dark ? ThemeMode.dark : ThemeMode.light;
    languageNotifier.value = lang;
    thresholdNotifier.value = threshold;
  }

  static double get threshold => thresholdNotifier.value;
  static bool get isDark => themeNotifier.value == ThemeMode.dark;
  static String get language => languageNotifier.value;

  static Future<void> setDarkMode(bool dark) async {
    await _prefs.setBool(_keyDarkMode, dark);
    themeNotifier.value = dark ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setLanguage(String lang) async {
    await _prefs.setString(_keyLanguage, lang);
    languageNotifier.value = lang;
  }

  static Future<void> setThreshold(double value) async {
    await _prefs.setDouble(_keyThreshold, value);
    thresholdNotifier.value = value;
  }
}
