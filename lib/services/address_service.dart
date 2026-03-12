// lib/services/address_service.dart
import '../models/models.dart';
import 'api_client.dart';
import 'service_result.dart';

class AddressService {
  AddressService._();

  // ── GET /api/direcciones ─────────────────────────────────────
  static Future<ServiceResult<List<DireccionEntrega>>> getDirecciones() async {
    final res = await ApiClient.get('/direcciones');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al obtener direcciones');
    final list = (res.data as List)
        .map((j) => DireccionEntrega.fromJson(j))
        .toList();
    return ServiceResult.ok(list);
  }

  // ── POST /api/direcciones ────────────────────────────────────
  static Future<ServiceResult<DireccionEntrega>> agregar(String direccion) async {
    final res = await ApiClient.post('/direcciones', {'direccion': direccion});
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al agregar dirección');
    return ServiceResult.ok(DireccionEntrega.fromJson(res.data['direccion']));
  }

  // ── PUT /api/direcciones/:id ─────────────────────────────────
  static Future<ServiceResult<DireccionEntrega>> actualizar({
    required int id,
    required String direccion,
  }) async {
    final res = await ApiClient.put('/direcciones/$id', {'direccion': direccion});
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al actualizar dirección');
    return ServiceResult.ok(DireccionEntrega.fromJson(res.data['direccion']));
  }

  // ── DELETE /api/direcciones/:id ──────────────────────────────
  static Future<ServiceResult<void>> eliminar(int id) async {
    final res = await ApiClient.delete('/direcciones/$id');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al eliminar dirección');
    return ServiceResult.ok(null);
  }
}
