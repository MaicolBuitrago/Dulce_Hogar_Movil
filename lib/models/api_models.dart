// lib/models/api_models.dart
// Modelos basados en el schema real de Supabase - Dulce Hogar

// ──────────────────────────────────────────────────────────────
// USUARIO
// ──────────────────────────────────────────────────────────────
class UsuarioModel {
  final String cedula;
  final String nombre;
  final String apellido;
  final String? direccion;
  final String email;
  final String? ciudad;
  final String? telefono;
  final String rol;

  const UsuarioModel({
    required this.cedula,
    required this.nombre,
    required this.apellido,
    this.direccion,
    required this.email,
    this.ciudad,
    this.telefono,
    required this.rol,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      cedula: json['cedula']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      direccion: json['direccion']?.toString(),
      email: json['email']?.toString() ?? '',
      ciudad: json['ciudad']?.toString(),
      telefono: json['telefono']?.toString(),
      rol: json['rol']?.toString() ?? 'cliente',
    );
  }

  Map<String, dynamic> toJson() => {
        'cedula': cedula,
        'nombre': nombre,
        'apellido': apellido,
        'direccion': direccion,
        'email': email,
        'ciudad': ciudad,
        'telefono': telefono,
        'rol': rol,
      };

  String get nombreCompleto => '$nombre $apellido'.trim();
  bool get esAdmin => rol == 'administrador';
}

// ──────────────────────────────────────────────────────────────
// PRODUCTO
// ──────────────────────────────────────────────────────────────
class ProductoModel {
  final int idproducto;
  final String nombre;
  final double precio;
  final int stock;
  final String? descripcion;
  final int? idcategoria;
  final int? idmarca;
  final bool activo;
  final List<ProductoImagenModel> imagenes;

  const ProductoModel({
    required this.idproducto,
    required this.nombre,
    required this.precio,
    required this.stock,
    this.descripcion,
    this.idcategoria,
    this.idmarca,
    this.activo = true,
    this.imagenes = const [],
  });

  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    final rawImagenes = json['producto_imagen'];
    List<ProductoImagenModel> imagenesParsed = [];

    if (rawImagenes is List) {
      imagenesParsed = rawImagenes
          .map((img) => ProductoImagenModel.fromJson(img))
          .toList();
    }

    return ProductoModel(
      idproducto: json['idproducto'] as int,
      nombre: json['nombre']?.toString() ?? '',
      precio: double.tryParse(json['precio']?.toString() ?? '0') ?? 0,
      stock: json['stock'] as int? ?? 0,
      descripcion: json['descripcion']?.toString(),
      idcategoria: json['idcategoria'] as int?,
      idmarca: json['idmarca'] as int?,
      activo: json['activo'] as bool? ?? true,
      imagenes: imagenesParsed,
    );
  }

  String? get primeraImagenUrl =>
      imagenes.isNotEmpty ? imagenes.first.url : null;

  bool get hayStock => stock > 0;

  String formatPrecio() {
    final formatted = precio
        .toInt()
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '\$$formatted';
  }
}

class ProductoImagenModel {
  final int? idimagen;
  final String url;

  const ProductoImagenModel({this.idimagen, required this.url});

  factory ProductoImagenModel.fromJson(Map<String, dynamic> json) {
    return ProductoImagenModel(
      idimagen: json['idimagen'] as int?,
      url: json['url']?.toString() ?? '',
    );
  }
}

// ──────────────────────────────────────────────────────────────
// CATEGORÍA
// ──────────────────────────────────────────────────────────────
class CategoriaModel {
  final int idcategoria;
  final String descripcion;

  const CategoriaModel({
    required this.idcategoria,
    required this.descripcion,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      idcategoria: json['idcategoria'] as int,
      // el backend devuelve 'descripcionCategoria' o 'descripcion'
      descripcion: json['descripcionCategoria']?.toString() ??
          json['descripcion']?.toString() ??
          '',
    );
  }
}

// ──────────────────────────────────────────────────────────────
// CARRITO
// ──────────────────────────────────────────────────────────────
class CarritoItemModel {
  final int idproducto;
  final String nombre;
  final double precio;
  int cantidad;
  final double subtotal;
  final String? imagenUrl;

  CarritoItemModel({
    required this.idproducto,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.subtotal,
    this.imagenUrl,
  });

  factory CarritoItemModel.fromJson(Map<String, dynamic> json) {
    return CarritoItemModel(
      idproducto: json['idproducto'] as int,
      nombre: json['nombre']?.toString() ?? '',
      precio: double.tryParse(json['precio']?.toString() ?? '0') ?? 0,
      cantidad: json['cantidad'] as int? ?? 1,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      imagenUrl: json['imagen_url']?.toString(),
    );
  }

  double get totalCalculado => precio * cantidad;

  String formatPrecio() {
    final formatted = precio
        .toInt()
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '\$$formatted';
  }

  String formatSubtotal() {
    final s = totalCalculado
        .toInt()
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '\$$s';
  }
}

// ──────────────────────────────────────────────────────────────
// FAVORITO
// ──────────────────────────────────────────────────────────────
class FavoritoModel {
  final int idfavorito;
  final int idproducto;
  final String nombre;
  final double precio;
  final String? descripcion;
  final int? stock;
  final List<String> imagenes;
  final String? imagen;
  final String? fechaAgregado;

  const FavoritoModel({
    required this.idfavorito,
    required this.idproducto,
    required this.nombre,
    required this.precio,
    this.descripcion,
    this.stock,
    this.imagenes = const [],
    this.imagen,
    this.fechaAgregado,
  });

  factory FavoritoModel.fromJson(Map<String, dynamic> json) {
    final rawImagenes = json['imagenes'];
    List<String> imagenesParsed = [];
    if (rawImagenes is List) {
      imagenesParsed = rawImagenes.map((e) => e.toString()).toList();
    }

    return FavoritoModel(
      idfavorito: json['idfavorito'] as int,
      idproducto: json['idproducto'] as int,
      nombre: json['nombre']?.toString() ?? '',
      precio: double.tryParse(json['precio']?.toString() ?? '0') ?? 0,
      descripcion: json['descripcion']?.toString(),
      stock: json['stock'] as int?,
      imagenes: imagenesParsed,
      imagen: json['imagen']?.toString(),
      fechaAgregado: json['fechaagregado']?.toString(),
    );
  }

  String formatPrecio() {
    final formatted = precio
        .toInt()
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '\$$formatted';
  }
}

// ──────────────────────────────────────────────────────────────
// DIRECCIÓN DE ENTREGA
// ──────────────────────────────────────────────────────────────
class DireccionModel {
  final int iddireccion;
  final String direccion;

  const DireccionModel({
    required this.iddireccion,
    required this.direccion,
  });

  factory DireccionModel.fromJson(Map<String, dynamic> json) {
    return DireccionModel(
      iddireccion: json['iddireccion'] as int,
      direccion: json['direccion']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'iddireccion': iddireccion,
        'direccion': direccion,
      };
}

// ──────────────────────────────────────────────────────────────
// PEDIDO
// ──────────────────────────────────────────────────────────────
class PedidoModel {
  final int idpedido;
  final String numero;
  final String cliente;
  final String estado;
  final double total;
  final String fecha;
  final String? direccion;
  final String? correo;

  const PedidoModel({
    required this.idpedido,
    required this.numero,
    required this.cliente,
    required this.estado,
    required this.total,
    required this.fecha,
    this.direccion,
    this.correo,
  });

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    return PedidoModel(
      idpedido: json['idpedido'] as int,
      numero: json['numero']?.toString() ?? '#${json['idpedido']}',
      cliente: json['cliente']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'Pendiente',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      fecha: json['fecha']?.toString() ?? '',
      direccion: json['direccion']?.toString(),
      correo: json['correo']?.toString(),
    );
  }

  String formatTotal() {
    final formatted = total
        .toInt()
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '\$$formatted';
  }
}

// ──────────────────────────────────────────────────────────────
// RESPUESTAS DE API
// ──────────────────────────────────────────────────────────────

/// Respuesta genérica del API
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.ok(T data, {String? message}) {
    return ApiResponse(success: true, data: data, message: message);
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
        success: false, message: message, statusCode: statusCode);
  }
}

/// Payload para crear checkout con Stripe
class CheckoutPayload {
  final String productName;
  final double price;
  final String source; // "producto" | "carrito"
  final int? iddireccion;
  final List<CheckoutProducto> productos;

  const CheckoutPayload({
    required this.productName,
    required this.price,
    required this.source,
    this.iddireccion,
    required this.productos,
  });

  Map<String, dynamic> toJson() => {
        'productName': productName,
        'price': price,
        'source': source,
        'iddireccion': iddireccion,
        'productos': productos.map((p) => p.toJson()).toList(),
      };
}

class CheckoutProducto {
  final int id;
  final String nombre;
  final double precio;
  final int cantidad;

  const CheckoutProducto({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.cantidad,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'precio': precio,
        'cantidad': cantidad,
      };
}
