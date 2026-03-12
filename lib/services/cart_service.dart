// lib/services/cart_service.dart
import '../models/models.dart';
import 'api_client.dart';
import 'service_result.dart';

class CartService {
  CartService._();

  // ── GET /api/carrito ─────────────────────────────────────────
  static Future<ServiceResult<List<CarritoItem>>> getCarrito() async {
    final res = await ApiClient.get('/carrito');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al obtener carrito');
    final list = (res.data as List).map((j) => CarritoItem.fromJson(j)).toList();
    return ServiceResult.ok(list);
  }

  // ── POST /api/carrito/agregar ────────────────────────────────
  static Future<ServiceResult<void>> agregar({
    required int idproducto,
    required int cantidad,
  }) async {
    final res = await ApiClient.post('/carrito/agregar', {
      'idproducto': idproducto,
      'cantidad': cantidad,
    });
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al agregar al carrito');
    return ServiceResult.ok(null);
  }

  // ── PUT /api/carrito/actualizar  (0 = eliminar) ──────────────
  static Future<ServiceResult<List<CarritoItem>>> actualizar({
    required int idproducto,
    required int cantidad,
  }) async {
    final res = await ApiClient.put('/carrito/actualizar', {
      'idproducto': idproducto,
      'cantidad': cantidad,
    });
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al actualizar carrito');
    final list = (res.data['carrito'] as List? ?? [])
        .map((j) => CarritoItem.fromJson(j))
        .toList();
    return ServiceResult.ok(list);
  }

  // ── DELETE /api/carrito/eliminar/:id ────────────────────────
  static Future<ServiceResult<void>> eliminar(int idproducto) async {
    final res = await ApiClient.delete('/carrito/eliminar/$idproducto');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al eliminar del carrito');
    return ServiceResult.ok(null);
  }

  // ── DELETE /api/carrito/vaciar ───────────────────────────────
  static Future<ServiceResult<void>> vaciar() async {
    final res = await ApiClient.delete('/carrito/vaciar');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al vaciar carrito');
    return ServiceResult.ok(null);
  }
}
