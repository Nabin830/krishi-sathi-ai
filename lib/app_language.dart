import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  static final ValueNotifier<String> language = ValueNotifier<String>('en');

  static bool get isNepali => language.value == 'ne';

  static Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('app_language') ?? 'en';
    language.value = savedLanguage;
  }

  static Future<void> toggleLanguage() async {
    final newLanguage = language.value == 'en' ? 'ne' : 'en';
    language.value = newLanguage;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', newLanguage);
  }

  static String text(String english, String nepali) {
    return language.value == 'ne' ? nepali : english;
  }
}
