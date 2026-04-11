import '../models/models.dart';
import 'api_client.dart';
import 'service_result.dart';

// Opciones de ordenamiento
enum OrdenProducto { recientes, precioAsc, precioDesc, nombreAz }

extension OrdenProductoExt on OrdenProducto {
  String get queryParam {
    switch (this) {
      case OrdenProducto.recientes:  return '';
      case OrdenProducto.precioAsc:  return 'precio_asc';
      case OrdenProducto.precioDesc: return 'precio_desc';
      case OrdenProducto.nombreAz:   return 'nombre_asc';
    }
  }

  String get label {
    switch (this) {
      case OrdenProducto.recientes:  return 'Más recientes';
      case OrdenProducto.precioAsc:  return 'Precio: menor a mayor';
      case OrdenProducto.precioDesc: return 'Precio: mayor a menor';
      case OrdenProducto.nombreAz:   return 'Nombre A-Z';
    }
  }
}

// Modelo de filtros activos
class FiltrosProducto {
  final String? search;
  final double? precioMin;
  final double? precioMax;
  final int? idMarca;
  final int? idCategoria;
  final OrdenProducto orden;

  const FiltrosProducto({
    this.search,
    this.precioMin,
    this.precioMax,
    this.idMarca,
    this.idCategoria,
    this.orden = OrdenProducto.recientes,
  });

  int get cantidadActivos {
    int c = 0;
    if (precioMin != null) c++;
    if (precioMax != null) c++;
    if (idMarca != null) c++;
    if (orden != OrdenProducto.recientes) c++;
    if (search != null && search!.isNotEmpty) c++;
    return c;
  }

  FiltrosProducto copyWith({
    String? search,
    double? precioMin,
    double? precioMax,
    int? idMarca,
    int? idCategoria,
    OrdenProducto? orden,
    bool limpiarPrecioMin = false,
    bool limpiarPrecioMax = false,
    bool limpiarMarca = false,
    bool limpiarSearch = false,
  }) {
    return FiltrosProducto(
      search:      limpiarSearch ? null : (search ?? this.search),
      precioMin:   limpiarPrecioMin ? null : (precioMin ?? this.precioMin),
      precioMax:   limpiarPrecioMax ? null : (precioMax ?? this.precioMax),
      idMarca:     limpiarMarca     ? null : (idMarca   ?? this.idMarca),
      idCategoria: idCategoria ?? this.idCategoria,
      orden:       orden       ?? this.orden,
    );
  }

  FiltrosProducto limpiar() => FiltrosProducto();
}

class ProductService {
  ProductService._();

  // ── GET /api/productos con filtros ───────────────────────────
  static Future<ServiceResult<List<Producto>>> getProductos({
    FiltrosProducto? filtros,
    String? search,  // para compatibilidad
  }) async {
    final f = filtros ?? FiltrosProducto(search: search);
    final params = <String>[];

    // Búsqueda por texto
    if (f.search != null && f.search!.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(f.search!)}');
    }
    
    // Rango de precios
    if (f.precioMin != null) params.add('precioMin=${f.precioMin!.toInt()}');
    if (f.precioMax != null) params.add('precioMax=${f.precioMax!.toInt()}');
    
    // Filtros por ID
    if (f.idMarca != null) params.add('idMarca=${f.idMarca}');
    if (f.idCategoria != null) params.add('idCategoria=${f.idCategoria}');
    
    // Ordenamiento (solo si no es el default "recientes")
    if (f.orden != OrdenProducto.recientes && f.orden.queryParam.isNotEmpty) {
      params.add('ordenar=${f.orden.queryParam}');
    }

    final path = params.isEmpty ? '/productos' : '/productos?${params.join('&')}';
    print('📡 URL de productos: $path');  // Debug
    
    final res = await ApiClient.get(path);
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al obtener productos');
    
    final list = (res.data as List).map((j) => Producto.fromJson(j)).toList();
    return ServiceResult.ok(list);
  }

  // ── GET /api/productos/:id ───────────────────────────────────
  static Future<ServiceResult<Producto>> getProductoById(int id) async {
    final res = await ApiClient.get('/productos/$id');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Producto no encontrado');
    return ServiceResult.ok(Producto.fromJson(res.data));
  }

  // ── GET /api/categorias ──────────────────────────────────────
  static Future<ServiceResult<List<Categoria>>> getCategorias() async {
    final res = await ApiClient.get('/categorias');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al obtener categorías');
    final list = (res.data as List).map((j) => Categoria.fromJson(j)).toList();
    return ServiceResult.ok(list);
  }

  // ── GET /api/categorias/:id/productos ────────────────────────
  static Future<ServiceResult<List<Producto>>> getProductosByCategoria(int idCategoria) async {
    final res = await ApiClient.get('/categorias/$idCategoria/productos');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al obtener productos');
    final list = (res.data as List).map((j) => Producto.fromJson(j)).toList();
    return ServiceResult.ok(list);
  }

  // ── GET /api/marcas (ajusta la ruta según tu backend) ────────
  static Future<ServiceResult<List<Marca>>> getMarcas() async {
    final res = await ApiClient.get('/categorias/marcas/lista');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al obtener marcas');
    final list = (res.data as List).map((j) => Marca.fromJson(j)).toList();
    return ServiceResult.ok(list);
  }
}