// lib/config/api_config.dart

class ApiConfig {
  ApiConfig._();

  /// Cambia esta URL por la de tu servidor en producción
  static const String baseUrl = 'http://localhost:4000/api';

  // ── Auth
  static const String login            = '$baseUrl/login';
  static const String registro         = '$baseUrl/usuario';
  static const String perfil           = '$baseUrl/usuario/perfil';
  static const String recuperar        = '$baseUrl/auth/recuperar';
  static const String restablecer      = '$baseUrl/auth/restablecer';

  // ── Productos
  static const String productos        = '$baseUrl/productos';
  static String productoDetalle(int id) => '$baseUrl/productos/$id';

  // ── Categorías
  static const String categorias       = '$baseUrl/categorias';
  static String productosPorCategoria(int id) => '$baseUrl/categorias/$id/productos';

  // ── Carrito
  static const String carrito          = '$baseUrl/carrito';
  static const String carritoAgregar   = '$baseUrl/carrito/agregar';
  static const String carritoActualizar= '$baseUrl/carrito/actualizar';
  static const String carritoVaciar    = '$baseUrl/carrito/vaciar';
  static String carritoEliminar(int id) => '$baseUrl/carrito/eliminar/$id';

  // ── Favoritos
  static const String favoritos        = '$baseUrl/favoritos';
  static String favoritoEliminar(int id) => '$baseUrl/favoritos/$id';

  // ── Stripe
  static const String stripeCheckout   = '$baseUrl/stripe/create-checkout-session';
  static const String stripePedido     = '$baseUrl/stripe/pedido/confirmar';
  static String stripeFactura(String sessionId) => '$baseUrl/stripe/factura/$sessionId';

  // ── Direcciones (si las agregas como endpoint)
  // static const String direcciones = '$baseUrl/direcciones';
}
