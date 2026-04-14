// lib/services/support_service.dart
//
// Modelos + servicio del sistema de mensajería con soporte.

import 'api_client.dart';
import 'service_result.dart';

// ══════════════════════════════════════════════════════════════
// MODELOS
// ══════════════════════════════════════════════════════════════

class TicketResumen {
  final int    idreclamo;
  final String asunto;
  final String estado;       // "Abierto" | "Cerrado"
  final String fecha;
  final int    totalMensajes;
  final bool   tieneNuevos;  // hay mensajes no leídos
  final int?   idproducto;

  const TicketResumen({
    required this.idreclamo,
    required this.asunto,
    required this.estado,
    required this.fecha,
    required this.totalMensajes,
    required this.tieneNuevos,
    this.idproducto,
  });

  factory TicketResumen.fromJson(Map<String, dynamic> j) => TicketResumen(
        idreclamo:     j['idreclamo']     ?? 0,
        asunto:        j['asunto']        ?? '',
        estado:        j['estado']        ?? 'Abierto',
        fecha:         j['fecha']         ?? '',
        totalMensajes: j['totalMensajes'] ?? 0,
        tieneNuevos:   j['tieneNuevos']   ?? false,
        idproducto:    j['idproducto'],
      );

  bool get estaAbierto => estado == 'Abierto';
}

class MensajeSoporte {
  final int    idmensaje;
  final String cedula;
  final String mensaje;
  final bool   esAdmin;
  final bool   esMio;
  final bool   editado;
  final String fechaenvio;

  const MensajeSoporte({
    required this.idmensaje,
    required this.cedula,
    required this.mensaje,
    required this.esAdmin,
    required this.esMio,
    required this.editado,
    required this.fechaenvio,
  });

  factory MensajeSoporte.fromJson(Map<String, dynamic> j) => MensajeSoporte(
        idmensaje:  j['idmensaje']  ?? 0,
        cedula:     j['cedula']     ?? '',
        mensaje:    j['mensaje']    ?? '',
        esAdmin:    j['esAdmin']    ?? false,
        esMio:      j['esMio']      ?? false,
        editado:    j['editado']    ?? false,
        fechaenvio: j['fechaenvio'] ?? '',
      );
}

class TicketDetalle {
  final int                  idreclamo;
  final String               asunto;
  final String               estado;
  final String               fecha;
  final bool                 cerrado;
  final String               cliente;
  final List<MensajeSoporte> mensajes;

  const TicketDetalle({
    required this.idreclamo,
    required this.asunto,
    required this.estado,
    required this.fecha,
    required this.cerrado,
    required this.cliente,
    required this.mensajes,
  });

  factory TicketDetalle.fromJson(Map<String, dynamic> j) => TicketDetalle(
        idreclamo: j['idreclamo'] ?? 0,
        asunto:    j['asunto']    ?? '',
        estado:    j['estado']    ?? 'Abierto',
        fecha:     j['fecha']     ?? '',
        cerrado:   j['cerrado']   ?? false,
        cliente:   j['cliente']   ?? 'Cliente',
        mensajes: (j['mensajes'] as List? ?? [])
            .map((m) => MensajeSoporte.fromJson(m))
            .toList(),
      );
}

// ══════════════════════════════════════════════════════════════
// SERVICIO
// ══════════════════════════════════════════════════════════════
class SupportService {
  SupportService._();

  // Abrir nuevo ticket
  static Future<ServiceResult<void>> abrirTicket({
    required String asunto,
    required String descripcion,
    int? idproducto,
  }) async {
    final body = {
      'asunto':      asunto,
      'descripcion': descripcion,
      if (idproducto != null) 'idproducto': idproducto,
    };
    final res = await ApiClient.post('/soporte', body);
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al abrir ticket');
    return ServiceResult.ok(null);
  }

  // Mis tickets (cliente)
  static Future<ServiceResult<List<TicketResumen>>> getMisTickets() async {
    final res = await ApiClient.get('/soporte/mis-tickets');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al cargar tickets');
    final lista = (res.data as List).map((j) => TicketResumen.fromJson(j)).toList();
    return ServiceResult.ok(lista);
  }

  // Todos los tickets (admin)
  static Future<ServiceResult<List<TicketResumen>>> getTodosTickets() async {
    final res = await ApiClient.get('/soporte/admin/todos');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al cargar tickets');
    final lista = (res.data as List).map((j) => TicketResumen.fromJson(j)).toList();
    return ServiceResult.ok(lista);
  }

  // Hilo completo de un ticket
  static Future<ServiceResult<TicketDetalle>> getTicket(int id) async {
    final res = await ApiClient.get('/soporte/$id');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al cargar ticket');
    return ServiceResult.ok(TicketDetalle.fromJson(res.data));
  }

  // Enviar mensaje
  static Future<ServiceResult<MensajeSoporte>> enviarMensaje({
    required int    idreclamo,
    required String mensaje,
  }) async {
    final res = await ApiClient.post('/soporte/$idreclamo/mensajes', {'mensaje': mensaje});
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al enviar mensaje');
    return ServiceResult.ok(MensajeSoporte.fromJson(res.data['mensaje']));
  }

  // Editar mensaje (REQ 13)
  static Future<ServiceResult<void>> editarMensaje({
    required int    idreclamo,
    required int    idmensaje,
    required String nuevoTexto,
  }) async {
    final res = await ApiClient.put(
        '/soporte/$idreclamo/mensajes/$idmensaje', {'mensaje': nuevoTexto});
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al editar mensaje');
    return ServiceResult.ok(null);
  }

  // Eliminar mensaje (REQ 12)
  static Future<ServiceResult<void>> eliminarMensaje({
    required int idreclamo,
    required int idmensaje,
  }) async {
    final res = await ApiClient.delete('/soporte/$idreclamo/mensajes/$idmensaje');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al eliminar mensaje');
    return ServiceResult.ok(null);
  }

  // Cerrar ticket (admin)
  static Future<ServiceResult<void>> cerrarTicket(int idreclamo) async {
    final res = await ApiClient.patch('/soporte/$idreclamo/cerrar', {});
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al cerrar ticket');
    return ServiceResult.ok(null);
  }
}