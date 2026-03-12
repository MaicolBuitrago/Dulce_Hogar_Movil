// lib/services/stripe_service.dart
import '../models/models.dart';
import 'api_client.dart';
import 'service_result.dart';

class StripeService {
  StripeService._();

  // ── POST /api/stripe/create-checkout-session ─────────────────
  /// Devuelve la URL de Stripe Checkout para abrir en el navegador
  static Future<ServiceResult<String>> crearSesion({
    required List<ProductoCheckout> productos,
    required String source, // 'carrito' | 'producto'
    int? iddireccion,
  }) async {
    final res = await ApiClient.post('/stripe/create-checkout-session', {
      'productos': productos.map((p) => p.toJson()).toList(),
      'source': source,
      if (iddireccion != null) 'iddireccion': iddireccion,
    });

    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al crear sesión de pago');

    final url = res.data['url'] as String?;
    if (url == null) return ServiceResult.error('URL de pago no recibida');
    return ServiceResult.ok(url);
  }

  // ── POST /api/stripe/pedido/confirmar ────────────────────────
  /// Confirma el pedido luego del pago exitoso con el session_id
  static Future<ServiceResult<Pedido>> confirmarPedido(String sessionId) async {
    final res = await ApiClient.post('/stripe/pedido/confirmar', {
      'session_id': sessionId,
    });

    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al confirmar pedido');
    return ServiceResult.ok(Pedido.fromJson(res.data['pedido']));
  }

  // ── GET /api/stripe/factura/:sessionId ───────────────────────
  /// Devuelve la URL del PDF de la factura
  static Future<ServiceResult<String>> getFactura(String sessionId) async {
    final res = await ApiClient.get('/stripe/factura/$sessionId');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al obtener factura');
    final url = res.data['url'] as String?;
    if (url == null) return ServiceResult.error('Factura no disponible aún');
    return ServiceResult.ok(url);
  }
}
