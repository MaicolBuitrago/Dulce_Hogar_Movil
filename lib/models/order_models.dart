class PedidoResumen {
  final int idpedido;
  final String numero;      // "#12"
  final String fecha;
  final double total;
  final String estado;
  final String colorEstado; // "warning" | "info" | "primary" | "success" | "error"
  final int totalItems;     // cantidad total de productos

  const PedidoResumen({
    required this.idpedido,
    required this.numero,
    required this.fecha,
    required this.total,
    required this.estado,
    required this.colorEstado,
    required this.totalItems,
  });

  factory PedidoResumen.fromJson(Map<String, dynamic> j) => PedidoResumen(
        idpedido:    j['idpedido']    ?? 0,
        numero:      j['numero']      ?? '#0',
        fecha:       j['fecha']       ?? '',
        total:       double.tryParse(j['total'].toString()) ?? 0,
        estado:      j['estado']      ?? 'Desconocido',
        colorEstado: j['colorEstado'] ?? 'default',
        totalItems:  j['totalItems']  ?? 0,
      );
}

// ══════════════════════════════════════════════════════════════
// PRODUCTO dentro del detalle de pedido
// ══════════════════════════════════════════════════════════════
class ItemPedido {
  final int iddetalle;
  final int idproducto;
  final String nombre;
  final double precio;
  final int cantidad;
  final double subtotal;
  final String? imagen;

  const ItemPedido({
    required this.iddetalle,
    required this.idproducto,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.subtotal,
    this.imagen,
  });

  factory ItemPedido.fromJson(Map<String, dynamic> j) => ItemPedido(
        iddetalle:  j['iddetalle']  ?? 0,
        idproducto: j['idproducto'] ?? 0,
        nombre:     j['nombre']     ?? 'Producto',
        precio:     double.tryParse(j['precio'].toString())   ?? 0,
        cantidad:   j['cantidad']   ?? 1,
        subtotal:   double.tryParse(j['subtotal'].toString()) ?? 0,
        imagen:     j['imagen'],
      );
}

// ══════════════════════════════════════════════════════════════
// DETALLE COMPLETO DE PEDIDO
// ══════════════════════════════════════════════════════════════
class PedidoDetalle {
  final int idpedido;
  final String numero;
  final String fecha;
  final double total;
  final String estado;
  final String colorEstado;
  final String direccion;
  final List<ItemPedido> productos;

  const PedidoDetalle({
    required this.idpedido,
    required this.numero,
    required this.fecha,
    required this.total,
    required this.estado,
    required this.colorEstado,
    required this.direccion,
    required this.productos,
  });

  factory PedidoDetalle.fromJson(Map<String, dynamic> j) => PedidoDetalle(
        idpedido:    j['idpedido']    ?? 0,
        numero:      j['numero']      ?? '#0',
        fecha:       j['fecha']       ?? '',
        total:       double.tryParse(j['total'].toString()) ?? 0,
        estado:      j['estado']      ?? 'Desconocido',
        colorEstado: j['colorEstado'] ?? 'default',
        direccion:   j['direccion']   ?? '',
        productos: (j['productos'] as List? ?? [])
            .map((p) => ItemPedido.fromJson(p))
            .toList(),
      );
}