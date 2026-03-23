// lib/utils/constants.dart

class AppConstants {
  AppConstants._();

  static const String baseUrl = 'https://broderick-peristomatic-nonalphabetically.ngrok-free.dev/api';

  // ── Auth
  static const String login              = '$baseUrl/login';
  static const String registro           = '$baseUrl/usuario';
  static const String perfil             = '$baseUrl/usuario/perfil';
  static const String recuperar          = '$baseUrl/auth/recuperar';
  static const String restablecer        = '$baseUrl/auth/restablecer';

  // ── Productos
  static const String productos          = '$baseUrl/productos';
  static const String categorias         = '$baseUrl/categorias';

  // ── Carrito
  static const String carrito            = '$baseUrl/carrito';
  static const String carritoAgregar     = '$baseUrl/carrito/agregar';
  static const String carritoActualizar  = '$baseUrl/carrito/actualizar';
  static const String carritoVaciar      = '$baseUrl/carrito/vaciar';

  // ── Favoritos
  static const String favoritos          = '$baseUrl/favoritos';

  // ── MercadoPago
  static const String mpPreferencia      = '$baseUrl/mercadopago/create-preference';
  static const String mpPedidoConfirmar  = '$baseUrl/mercadopago/pedido/confirmar';
}
