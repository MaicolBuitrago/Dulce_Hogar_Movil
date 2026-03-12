// lib/utils/formatters.dart
class Formatters {
  Formatters._();

  /// Formatea un número como precio COP
  /// Ejemplo: 1200000 → "$1.200.000"
  static String precio(double amount) {
    final s = amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '\$$s';
  }
}
