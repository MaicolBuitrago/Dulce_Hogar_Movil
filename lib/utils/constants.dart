// lib/utils/constants.dart

class AppConstants {
  AppConstants._();

  /// Cambia esto según tu entorno
  /// Desarrollo local:   'http://10.0.2.2:4000/api'  (emulador Android)
  /// Dispositivo físico: 'http://TU_IP_LOCAL:4000/api'
  /// Producción:         'https://tudominio.com/api'
  static const String baseUrl = 'http://localhost:4000/api';

  // ── Auth ──────────────────────────────────────────────────
  static const String login              = '$baseUrl/login';
  static const String registro           = '$baseUrl/usuario';
  static const String perfil             = '$baseUrl/usuario/perfil';
  static const String recuperar          = '$baseUrl/auth/recuperar';
  static const String restablecer        = '$baseUrl/auth/restablecer';

  // ── Productos ─────────────────────────────────────────────
  static const String productos          = '$baseUrl/productos';
  static const String categorias         = '$baseUrl/categorias';

  // ── Carrito ───────────────────────────────────────────────
  static const String carrito            = '$baseUrl/carrito';
  static const String carritoAgregar     = '$baseUrl/carrito/agregar';
  static const String carritoActualizar  = '$baseUrl/carrito/actualizar';
  static const String carritoVaciar      = '$baseUrl/carrito/vaciar';

  // ── Favoritos ─────────────────────────────────────────────
  static const String favoritos          = '$baseUrl/favoritos';

  // ── Stripe ────────────────────────────────────────────────
  static const String stripeCheckout     = '$baseUrl/stripe/create-checkout-session';
  static const String stripePedidoConfirmar = '$baseUrl/stripe/pedido/confirmar';
  static const String stripeFactura      = '$baseUrl/stripe/factura';
}
