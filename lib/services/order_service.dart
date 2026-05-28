import '../models/order_models.dart';
import 'api_client.dart';
import 'service_result.dart';

class OrderService {
  OrderService._(); // No se puede instanciar — todo es estático

  // ── GET /api/pedidos/mis-pedidos ─────────────────────────────
  // Devuelve la lista de pedidos del usuario autenticado
  static Future<ServiceResult<List<PedidoResumen>>> getMisPedidos() async {
    final res = await ApiClient.get('/api/pedidos/mis-pedidos');

    if (!res.ok) {
      return ServiceResult.error(res.error ?? 'Error al obtener tus pedidos');
    }

    final lista = (res.data as List)
        .map((j) => PedidoResumen.fromJson(j))
        .toList();

    return ServiceResult.ok(lista);
  }

  // ── GET /api/pedidos/mis-pedidos/:id ─────────────────────────
  // Devuelve el detalle completo de un pedido con sus productos
  static Future<ServiceResult<PedidoDetalle>> getDetallePedido(int idpedido) async {
    final res = await ApiClient.get('/api/pedidos/mis-pedidos/$idpedido');

    if (!res.ok) {
      return ServiceResult.error(res.error ?? 'Error al obtener el pedido');
    }

    return ServiceResult.ok(PedidoDetalle.fromJson(res.data));
  }
}