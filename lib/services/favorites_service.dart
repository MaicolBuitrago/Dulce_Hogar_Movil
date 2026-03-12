// lib/services/favorites_service.dart
import '../models/models.dart';
import 'api_client.dart';
import 'service_result.dart';

class FavoritesService {
  FavoritesService._();

  // ── GET /api/favoritos ───────────────────────────────────────
  static Future<ServiceResult<List<Favorito>>> getFavoritos() async {
    final res = await ApiClient.get('/favoritos');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al obtener favoritos');
    final list = (res.data as List).map((j) => Favorito.fromJson(j)).toList();
    return ServiceResult.ok(list);
  }

  // ── POST /api/favoritos ──────────────────────────────────────
  static Future<ServiceResult<void>> agregar(int idproducto) async {
    final res = await ApiClient.post('/favoritos', {'idproducto': idproducto});
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al agregar favorito');
    return ServiceResult.ok(null);
  }

  // ── DELETE /api/favoritos/:id ────────────────────────────────
  static Future<ServiceResult<void>> eliminar(int idproducto) async {
    final res = await ApiClient.delete('/favoritos/$idproducto');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al eliminar favorito');
    return ServiceResult.ok(null);
  }
}
