import 'api_client.dart';
import 'service_result.dart';

// ── Modelo ────────────────────────────────────────────────────
class Resena {
  final int    idcomentario;
  final String fecha;
  final int    calificacion; // 1-5
  final String comentario;
  final String autor;
  final String cedula;       // para saber si es del usuario actual

  const Resena({
    required this.idcomentario,
    required this.fecha,
    required this.calificacion,
    required this.comentario,
    required this.autor,
    required this.cedula,
  });

  factory Resena.fromJson(Map<String, dynamic> j) => Resena(
        idcomentario: j['idcomentario'] ?? 0,
        fecha:        j['fecha']        ?? '',
        calificacion: j['calificacion'] ?? 0,
        comentario:   j['comentario']   ?? '',
        autor:        j['autor']        ?? 'Usuario',
        cedula:       j['cedula']       ?? '',
      );
}

class ResumenResenas {
  final double      promedio;
  final int         total;
  final List<Resena> resenas;

  const ResumenResenas({
    required this.promedio,
    required this.total,
    required this.resenas,
  });

  factory ResumenResenas.fromJson(Map<String, dynamic> j) => ResumenResenas(
        promedio: double.tryParse(j['promedio'].toString()) ?? 0,
        total:    j['total'] ?? 0,
        resenas:  (j['resenas'] as List? ?? [])
            .map((r) => Resena.fromJson(r))
            .toList(),
      );

  factory ResumenResenas.vacio() =>
      const ResumenResenas(promedio: 0, total: 0, resenas: []);
}

// ── Servicio ──────────────────────────────────────────────────
class ReviewService {
  ReviewService._();

  // GET /api/resenas/:idproducto
  static Future<ServiceResult<ResumenResenas>> getResenas(int idproducto) async {
    final res = await ApiClient.get('/api/resenas/$idproducto');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al cargar reseñas');
    return ServiceResult.ok(ResumenResenas.fromJson(res.data));
  }

  // POST /api/resenas/:idproducto
  static Future<ServiceResult<Resena>> crear({
    required int    idproducto,
    required int    calificacion,
    required String comentario,
  }) async {
    final res = await ApiClient.post('/api/resenas/$idproducto', {
      'calificacion': calificacion,
      'comentario':   comentario,
    });
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al publicar reseña');
    return ServiceResult.ok(Resena.fromJson(res.data['resena']));
  }

  // DELETE /api/resenas/:idresena
  static Future<ServiceResult<void>> eliminar(int idresena) async {
    final res = await ApiClient.delete('/api/resenas/$idresena');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al eliminar reseña');
    return ServiceResult.ok(null);
  }
}