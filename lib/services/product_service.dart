// lib/services/product_service.dart
import '../models/models.dart';
import 'api_client.dart';
import 'service_result.dart';

class ProductService {
  ProductService._();

  // ── GET /api/productos  →  Lista pública ─────────────────────
  static Future<ServiceResult<List<Producto>>> getProductos({String? search}) async {
    final path = search != null && search.isNotEmpty
        ? '/productos?search=$search'
        : '/productos';
    final res = await ApiClient.get(path);
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al obtener productos');
    final list = (res.data as List).map((j) => Producto.fromJson(j)).toList();
    return ServiceResult.ok(list);
  }

  // ── GET /api/productos/:id  →  Detalle ───────────────────────
  static Future<ServiceResult<Producto>> getProductoById(int id) async {
    final res = await ApiClient.get('/productos/$id');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Producto no encontrado');
    return ServiceResult.ok(Producto.fromJson(res.data));
  }

  // ── GET /api/categorias  →  Categorías ───────────────────────
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

  // ── GET /api/categorias/marcas/lista  →  Marcas ──────────────
  static Future<ServiceResult<List<Marca>>> getMarcas() async {
    final res = await ApiClient.get('/categorias/marcas/lista');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al obtener marcas');
    final list = (res.data as List).map((j) => Marca.fromJson(j)).toList();
    return ServiceResult.ok(list);
  }
}
