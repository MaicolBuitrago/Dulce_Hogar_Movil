// lib/config/api_config.dart

class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://broderick-peristomatic-nonalphabetically.ngrok-free.dev/api';

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

  // ── Marcas (NUEVO)
  static const String marcas           = '$baseUrl/marcas'; 

  // ── Carrito
  static const String carrito          = '$baseUrl/carrito';
  static const String carritoAgregar   = '$baseUrl/carrito/agregar';
  static const String carritoActualizar= '$baseUrl/carrito/actualizar';
  static const String carritoVaciar    = '$baseUrl/carrito/vaciar';
  static String carritoEliminar(int id) => '$baseUrl/carrito/eliminar/$id';

  // ── Favoritos
  static const String favoritos        = '$baseUrl/favoritos';
  static String favoritoEliminar(int id) => '$baseUrl/favoritos/$id';

  // ── MercadoPago
  static const String mpPreferencia    = '$baseUrl/mercadopago/create-preference';
  static const String mpPedido         = '$baseUrl/mercadopago/pedido/confirmar';
}