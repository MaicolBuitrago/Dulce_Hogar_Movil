// lib/models/models.dart
// Modelos reales basados en el schema de Supabase / respuestas del backend

// ══════════════════════════════════════════════════════════════
// USUARIO
// ══════════════════════════════════════════════════════════════
class Usuario {
  final String cedula;
  final String nombre;
  final String apellido;
  final String? direccion;
  final String email;
  final String? ciudad;
  final String rol;
  final String? telefono;

  const Usuario({
    required this.cedula, required this.nombre, required this.apellido,
    this.direccion, required this.email, this.ciudad,
    required this.rol, this.telefono,
  });

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
    cedula: j['cedula'] ?? '',
    nombre: j['nombre'] ?? '',
    apellido: j['apellido'] ?? '',
    direccion: j['direccion'],
    email: j['email'] ?? '',
    ciudad: j['ciudad'],
    rol: j['rol'] ?? 'cliente',
    telefono: j['telefono'],
  );

  bool get esAdmin => rol == 'administrador';
}

// ══════════════════════════════════════════════════════════════
// CATEGORÍA
// ══════════════════════════════════════════════════════════════
class Categoria {
  final int idcategoria;
  final String descripcion;

  const Categoria({required this.idcategoria, required this.descripcion});

  factory Categoria.fromJson(Map<String, dynamic> j) => Categoria(
    idcategoria: j['idcategoria'] ?? 0,
    descripcion: j['descripcionCategoria'] ?? j['descripcion'] ?? '',
  );
}

// ══════════════════════════════════════════════════════════════
// MARCA
// ══════════════════════════════════════════════════════════════
class Marca {
  final int idmarca;
  final String descripcion;

  const Marca({required this.idmarca, required this.descripcion});

  factory Marca.fromJson(Map<String, dynamic> j) => Marca(
    idmarca: j['idmarca'] ?? 0,
    descripcion: j['descripcionMarca'] ?? j['descripcion'] ?? '',
  );
}

// ══════════════════════════════════════════════════════════════
// PRODUCTO
// ══════════════════════════════════════════════════════════════
class Producto {
  final int idproducto;
  final String nombre;
  final double precio;
  final int stock;
  final String? descripcion;
  final int? idcategoria;
  final int? idmarca;
  final bool activo;
  final List<String> imagenes;

  const Producto({
    required this.idproducto, required this.nombre, required this.precio,
    required this.stock, this.descripcion, this.idcategoria, this.idmarca,
    this.activo = true, this.imagenes = const [],
  });

  factory Producto.fromJson(Map<String, dynamic> j) {
    final imgs = (j['producto_imagen'] as List<dynamic>? ?? [])
        .map((i) => i['url'] as String? ?? '')
        .where((u) => u.isNotEmpty)
        .toList();
    return Producto(
      idproducto: j['idproducto'] ?? 0,
      nombre: j['nombre'] ?? '',
      precio: double.tryParse(j['precio'].toString()) ?? 0,
      stock: j['stock'] ?? 0,
      descripcion: j['descripcion'],
      idcategoria: j['idcategoria'],
      idmarca: j['idmarca'],
      activo: j['activo'] ?? true,
      imagenes: imgs,
    );
  }

  String? get imagenPrincipal => imagenes.isNotEmpty ? imagenes.first : null;
  bool get disponible => stock > 0 && activo;
}

// ══════════════════════════════════════════════════════════════
// CARRITO ITEM
// ══════════════════════════════════════════════════════════════
class CarritoItem {
  final int idproducto;
  final String nombre;
  final double precio;
  int cantidad;
  final double subtotal;
  final String? imagenUrl;

  CarritoItem({
    required this.idproducto, required this.nombre, required this.precio,
    required this.cantidad, required this.subtotal, this.imagenUrl,
  });

  factory CarritoItem.fromJson(Map<String, dynamic> j) => CarritoItem(
    idproducto: j['idproducto'] ?? 0,
    nombre: j['nombre'] ?? '',
    precio: double.tryParse(j['precio'].toString()) ?? 0,
    cantidad: j['cantidad'] ?? 1,
    subtotal: double.tryParse(j['subtotal'].toString()) ?? 0,
    imagenUrl: j['imagen_url'],
  );

  double get totalCalculado => precio * cantidad;
}

// ══════════════════════════════════════════════════════════════
// FAVORITO
// ══════════════════════════════════════════════════════════════
class Favorito {
  final int idfavorito;
  final String? fechaagregado;
  final int idproducto;
  final String nombre;
  final double precio;
  final String? descripcion;
  final int stock;
  final List<String> imagenes;
  final String? imagen;

  const Favorito({
    required this.idfavorito, this.fechaagregado, required this.idproducto,
    required this.nombre, required this.precio, this.descripcion,
    required this.stock, this.imagenes = const [], this.imagen,
  });

  factory Favorito.fromJson(Map<String, dynamic> j) => Favorito(
    idfavorito: j['idfavorito'] ?? 0,
    fechaagregado: j['fechaagregado'],
    idproducto: j['idproducto'] ?? 0,
    nombre: j['nombre'] ?? '',
    precio: double.tryParse(j['precio'].toString()) ?? 0,
    descripcion: j['descripcion'],
    stock: j['stock'] ?? 0,
    imagenes: List<String>.from(j['imagenes'] ?? []),
    imagen: j['imagen'],
  );
}

// ══════════════════════════════════════════════════════════════
// DIRECCIÓN DE ENTREGA
// ══════════════════════════════════════════════════════════════
class DireccionEntrega {
  final int iddireccion;
  final String direccion;

  const DireccionEntrega({required this.iddireccion, required this.direccion});

  factory DireccionEntrega.fromJson(Map<String, dynamic> j) => DireccionEntrega(
    iddireccion: j['iddireccion'] ?? 0,
    direccion: j['direccion'] ?? '',
  );
}

// ══════════════════════════════════════════════════════════════
// PEDIDO
// ══════════════════════════════════════════════════════════════
class Pedido {
  final int idpedido;
  final String numero;
  final String cliente;
  final String? correo;
  final String? direccion;
  final String? ciudad;
  final String? telefono;
  final String estado;
  final double total;
  final String? fecha;

  const Pedido({
    required this.idpedido, required this.numero, required this.cliente,
    this.correo, this.direccion, this.ciudad, this.telefono,
    required this.estado, required this.total, this.fecha,
  });

  factory Pedido.fromJson(Map<String, dynamic> j) => Pedido(
    idpedido: j['idpedido'] ?? 0,
    numero: j['numero'] ?? '#0',
    cliente: j['cliente'] ?? '',
    correo: j['correo'],
    direccion: j['direccion'],
    ciudad: j['ciudad'],
    telefono: j['telefono'],
    estado: j['estado'] ?? 'Desconocido',
    total: double.tryParse(j['total'].toString()) ?? 0,
    fecha: j['fecha'],
  );
}

// ══════════════════════════════════════════════════════════════
// PRODUCTO PARA STRIPE CHECKOUT
// ══════════════════════════════════════════════════════════════
class ProductoCheckout {
  final int id;
  final String nombre;
  final double precio;
  final int cantidad;

  const ProductoCheckout({
    required this.id, required this.nombre,
    required this.precio, required this.cantidad,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'precio': precio,
    'cantidad': cantidad,
  };
}
