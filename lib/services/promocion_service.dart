// lib/services/promocion_service.dart
import 'api_client.dart';
import 'service_result.dart';

class Promocion {
  final int idpromocion;
  final String nombre;
  final String? descripcion;
  final String tipoDescuento;
  final double valorDescuento;
  final String scope;
  final int? idproducto;
  final int? idcategoria;
  final String fechaInicio;
  final String fechaFin;

  Promocion({
    required this.idpromocion,
    required this.nombre,
    this.descripcion,
    required this.tipoDescuento,
    required this.valorDescuento,
    required this.scope,
    this.idproducto,
    this.idcategoria,
    required this.fechaInicio,
    required this.fechaFin,
  });

  factory Promocion.fromJson(Map<String, dynamic> json) => Promocion(
    idpromocion: json['idpromocion'],
    nombre: json['nombre'],
    descripcion: json['descripcion'],
    tipoDescuento: json['tipo_descuento'],
    valorDescuento: (json['valor_descuento'] as num).toDouble(),
    scope: json['scope'],
    idproducto: json['idproducto'],
    idcategoria: json['idcategoria'],
    fechaInicio: json['fecha_inicio'],
    fechaFin: json['fecha_fin'],
  );

  bool get esPorcentaje => tipoDescuento == 'porcentaje';
  double get porcentaje => esPorcentaje ? valorDescuento / 100 : 0;
}

class PromocionService {
  PromocionService._();

  // ✅ CORREGIDO: URL correcta es '/promociones', no '/promociones/promociones'
  static Future<ServiceResult<List<Promocion>>> getPromociones() async {
    final res = await ApiClient.get('/api/promociones');
    if (!res.ok) {
      return ServiceResult.error(res.error ?? 'Error al cargar promociones');
    }
    final list = (res.data as List).map((j) => Promocion.fromJson(j)).toList();
    return ServiceResult.ok(list);
  }

  // GET /api/promociones/producto/:id
  static Future<ServiceResult<Promocion?>> getPromocionPorProducto(int idproducto) async {
    final res = await ApiClient.get('/api/promociones/producto/$idproducto');
    if (!res.ok) {
      return ServiceResult.error(res.error ?? 'Error al obtener promoción');
    }
    if (res.data == null) {
      return ServiceResult.ok(null);
    }
    return ServiceResult.ok(Promocion.fromJson(res.data));
  }

  // GET /api/promociones/categoria/:id
  static Future<ServiceResult<Promocion?>> getPromocionPorCategoria(int idcategoria) async {
    final res = await ApiClient.get('/api/promociones/categoria/$idcategoria');
    if (!res.ok) {
      return ServiceResult.error(res.error ?? 'Error al obtener promoción');
    }
    if (res.data == null) {
      return ServiceResult.ok(null);
    }
    return ServiceResult.ok(Promocion.fromJson(res.data));
  }

  // GET /api/promociones/globales
  static Future<ServiceResult<List<Promocion>>> getPromocionesGlobales() async {
    final res = await ApiClient.get('/api/promociones/globales');
    if (!res.ok) {
      return ServiceResult.error(res.error ?? 'Error al cargar promociones globales');
    }
    final list = (res.data as List).map((j) => Promocion.fromJson(j)).toList();
    return ServiceResult.ok(list);
  }

  static double calcularPrecioConDescuento(double precio, double porcentaje) {
    return precio * (1 - porcentaje);
  }

  static String formatearPorcentaje(double porcentaje) {
    return '-${(porcentaje * 100).toInt()}%';
  }
}