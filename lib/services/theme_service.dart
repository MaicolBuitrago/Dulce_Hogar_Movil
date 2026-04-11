import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  ThemeService._();

  // Clave usada en SharedPreferences
  static const _kTema = 'dulce_hogar_tema_oscuro';

  // Notifier global — escúchalo en main.dart con ValueListenableBuilder
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.light);

  // ── Inicializar al arrancar la app ────────────────────────────
  // Llama esto en main() antes de runApp() para restaurar la preferencia
  static Future<void> init() async {
    final prefs   = await SharedPreferences.getInstance();
    final esOscuro = prefs.getBool(_kTema) ?? false;
    themeMode.value = esOscuro ? ThemeMode.dark : ThemeMode.light;
  }

  // ── Toggle — alterna entre claro y oscuro ─────────────────────
  static Future<void> toggle() async {
    final nuevoEsOscuro = themeMode.value != ThemeMode.dark;
    await setDark(nuevoEsOscuro);
  }

  // ── Forzar un valor concreto ──────────────────────────────────
  static Future<void> setDark(bool oscuro) async {
    themeMode.value = oscuro ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTema, oscuro);
  }

  // ── Getter de conveniencia ────────────────────────────────────
  static bool get esOscuro => themeMode.value == ThemeMode.dark;
}