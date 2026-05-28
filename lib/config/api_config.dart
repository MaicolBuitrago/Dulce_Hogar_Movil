// lib/config/api_config.dart

class ApiConfig {
  ApiConfig._();

  // ── Auth
  static const String login       = '/api/usuario/login';
  static const String registro    = '/api/usuario';
  static const String perfil      = '/api/usuario/perfil';
  static const String refresh     = '/api/refresh';
  static const String logout      = '/api/logout';

  // ── Recuperar contraseña
  static const String recuperar   = '/api/auth/recuperar';
  static const String restablecer = '/api/auth/restablecer';

  // ── Productos
  static const String productos   = '/api/productos';
  static String productoDetalle(int id)       => '/api/productos/$id';

  // ── Categorías
  static const String categorias  = '/api/categorias';
  static String productosPorCategoria(int id) => '/api/categorias/$id/productos';

  // ── Marcas
  static const String marcas      = '/api/marcas';

  // ── Carrito
  static const String carrito           = '/api/carrito';
  static const String carritoAgregar    = '/api/carrito/agregar';
  static const String carritoActualizar = '/api/carrito/actualizar';
  static const String carritoVaciar     = '/api/carrito/vaciar';
  static String carritoEliminar(int id) => '/api/carrito/eliminar/$id';

  // ── Favoritos
  static const String favoritos         = '/api/favoritos';
  static String favoritoEliminar(int id) => '/api/favoritos/$id';

  // ── Promociones
  static const String promociones       = '/api/promociones';

  // ── Soporte
  static const String soporte           = '/api/soporte';

  // ── Pedidos
  static const String pedidos           = '/api/pedidos';
  static const String misPedidos        = '/api/mis-pedidos';

  // ── Reseñas
  static const String resenas           = '/api/resenas';

  // ── Direcciones
  static const String direcciones       = '/api/direcciones';

  // ── MercadoPago
  static const String mpPreferencia     = '/api/mercadopago/create-preference';
  static const String mpPedido          = '/api/mercadopago/pedido/confirmar';
}