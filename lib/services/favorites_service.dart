import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'service_result.dart';

class FavoritesService {
  FavoritesService._();

  /// Set de idproducto que el usuario tiene en favoritos — escúchalo con ValueListenableBuilder
  static final ValueNotifier<Set<int>> favoriteIds = ValueNotifier<Set<int>>({});

  // ── GET /api/favoritos ───────────────────────────────────────
  static Future<ServiceResult<List<Favorito>>> getFavoritos() async {
    final res = await ApiClient.get('/api/favoritos');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al obtener favoritos');
    final list = (res.data as List).map((j) => Favorito.fromJson(j)).toList();
    // Sincronizar el set de ids
    favoriteIds.value = list.map((f) => f.idproducto).toSet();
    return ServiceResult.ok(list);
  }

  // ── POST /api/favoritos ──────────────────────────────────────
  static Future<ServiceResult<void>> agregar(int idproducto) async {
    final res = await ApiClient.post('/api/favoritos', {'idproducto': idproducto});
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al agregar favorito');
    favoriteIds.value = {...favoriteIds.value, idproducto};
    return ServiceResult.ok(null);
  }

  // ── DELETE /api/favoritos/:id ────────────────────────────────
  static Future<ServiceResult<void>> eliminar(int idproducto) async {
    final res = await ApiClient.delete('/api/favoritos/$idproducto');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al eliminar favorito');
    favoriteIds.value = favoriteIds.value.where((id) => id != idproducto).toSet();
    return ServiceResult.ok(null);
  }

  // ── Toggle conveniente ───────────────────────────────────────
  static Future<ServiceResult<void>> toggle(int idproducto) async {
    if (favoriteIds.value.contains(idproducto)) {
      return eliminar(idproducto);
    } else {
      return agregar(idproducto);
    }
  }
}