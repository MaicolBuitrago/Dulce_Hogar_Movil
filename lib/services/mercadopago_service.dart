import '../models/models.dart';
import 'api_client.dart';
import 'service_result.dart';

class MercadoPagoService {
  MercadoPagoService._();

  // ── POST /api/mercadopago/create-preference ──────────────────
  /// Crea la preferencia y devuelve la URL de pago de MercadoPago
  static Future<ServiceResult<String>> crearPreferencia({
    required List<ProductoCheckout> productos,
    required String source, // 'carrito' | 'producto'
    int? iddireccion,
  }) async {
    final res = await ApiClient.post('/mercadopago/create-preference', {
      'productos': productos.map((p) => p.toJson()).toList(),
      'source': source,
      if (iddireccion != null) 'iddireccion': iddireccion,
    });

    if (!res.ok) {
      return ServiceResult.error(res.error ?? 'Error al crear preferencia de pago');
    }

    final url = res.data['url'] as String?;
    if (url == null) return ServiceResult.error('URL de pago no recibida');
    return ServiceResult.ok(url);
  }

  // ── POST /api/mercadopago/pedido/confirmar ───────────────────
  /// Confirma el pedido luego del pago exitoso con el payment_id
  /// que MercadoPago devuelve como query param en la URL de retorno:
  ///   ?payment_id=xxx&status=approved&payment_type=credit_card
  static Future<ServiceResult<Pedido>> confirmarPedido(String paymentId) async {
    final res = await ApiClient.post('/mercadopago/pedido/confirmar', {
      'payment_id': paymentId,
    });

    if (!res.ok) {
      return ServiceResult.error(res.error ?? 'Error al confirmar pedido');
    }
    return ServiceResult.ok(Pedido.fromJson(res.data['pedido']));
  }
}
