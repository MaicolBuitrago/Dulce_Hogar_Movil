import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/support_service.dart';
import '../services/auth_service.dart';

class SupportChatScreen extends StatefulWidget {
  final int    idreclamo;
  final String asunto;
  final bool   esAdmin;

  const SupportChatScreen({
    super.key,
    required this.idreclamo,
    required this.asunto,
    required this.esAdmin,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  TicketDetalle? _ticket;
  bool   _loading  = true;
  bool   _enviando = false;
  String? _error;
  String? _miCedula;
  RealtimeChannel? _realtimeChannel;

  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _obtenerMiCedula();
    _cargar();
  }

  Future<void> _obtenerMiCedula() async {
    final perfil = await AuthService.getPerfil();
    if (mounted && perfil.ok) {
      _miCedula = perfil.data?.cedula;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 🔥 SUSCRIPCIÓN A REALTIME - CON CIERRE, EDICIÓN Y ELIMINACIÓN
  // ─────────────────────────────────────────────────────────────
  void _suscribirRealtime() {
    final supabase = Supabase.instance.client;
    
    _realtimeChannel = supabase.channel('mensajes_${widget.idreclamo}');
    
    _realtimeChannel!
        // 1️⃣ Escuchar NUEVOS mensajes (INSERT)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes_soporte',
          callback: (payload) {
            if (!mounted) return;
            
            final nuevo = payload.newRecord;
            
            if (nuevo['idreclamo'] != widget.idreclamo) return;
            
            final idmensaje = nuevo['idmensaje'];
            
            final yaExiste = _ticket?.mensajes.any((m) => m.idmensaje == idmensaje) ?? false;
            
            if (yaExiste) return;
            
            final cedulaMensaje = nuevo['cedula'];
            final esMio = cedulaMensaje == _miCedula;
            
            final nuevoMensaje = MensajeSoporte(
              idmensaje:  idmensaje,
              cedula:     cedulaMensaje,
              mensaje:    nuevo['mensaje'],
              esAdmin:    nuevo['es_admin'],
              esMio:      esMio,
              editado:    nuevo['editado'] ?? false,
              fechaenvio: nuevo['fechaenvio'],
            );
            
            setState(() {
              _ticket?.mensajes.add(nuevoMensaje);
            });
            _scrollAlFinal();
          },
        )
        // 2️⃣ Escuchar EDICIÓN de mensajes (UPDATE)
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'mensajes_soporte',
          callback: (payload) {
            if (!mounted) return;
            
            final nuevo = payload.newRecord;
            final idmensaje = nuevo['idmensaje'];
            
            // Verificar que sea del ticket actual
            if (nuevo['idreclamo'] != widget.idreclamo) return;
            
            // Actualizar el mensaje editado en la lista local
            setState(() {
              final index = _ticket?.mensajes.indexWhere((m) => m.idmensaje == idmensaje);
              if (index != null && index != -1 && _ticket != null) {
                final mensajeActualizado = MensajeSoporte(
                  idmensaje:  idmensaje,
                  cedula:     nuevo['cedula'],
                  mensaje:    nuevo['mensaje'],
                  esAdmin:    nuevo['es_admin'],
                  esMio:      nuevo['cedula'] == _miCedula,
                  editado:    true,
                  fechaenvio: nuevo['fechaenvio'],
                );
                _ticket!.mensajes[index] = mensajeActualizado;
              }
            });
          },
        )
        // 3️⃣ Escuchar ELIMINACIÓN de mensajes (DELETE)
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'mensajes_soporte',
          callback: (payload) {
            if (!mounted) return;
            
            final viejo = payload.oldRecord;
            final idmensaje = viejo['idmensaje'];
            
            // Verificar que sea del ticket actual
            if (viejo['idreclamo'] != widget.idreclamo) return;
            
            // Eliminar el mensaje de la lista local
            setState(() {
              _ticket?.mensajes.removeWhere((m) => m.idmensaje == idmensaje);
            });
          },
        )
        // 4️⃣ Escuchar cuando el ticket se cierra
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'soportedereclamos',
          callback: (payload) {
            if (!mounted) return;
            
            final nuevo = payload.newRecord;
            final viejo = payload.oldRecord;
            
            // Si cambió fecharesolucion de null a algo → ticket cerrado
            if (nuevo['fecharesolucion'] != null && viejo['fecharesolucion'] == null) {
              setState(() {
                _ticket = TicketDetalle(
                  idreclamo: _ticket!.idreclamo,
                  asunto:    _ticket!.asunto,
                  estado:    'Cerrado',
                  fecha:     _ticket!.fecha,
                  cerrado:   true,
                  cliente:   _ticket!.cliente,
                  mensajes:  _ticket!.mensajes,
                );
              });
              
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Este ticket ha sido cerrado'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ));
            }
          },
        )
        .subscribe();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    final r = await SupportService.getTicket(widget.idreclamo);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.ok) {
        _ticket = r.data;
        _suscribirRealtime();
      } else {
        _error = r.error;
      }
    });
    _scrollAlFinal();
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _msgCtrl.text.trim();
    if (texto.isEmpty || _ticket == null) return;

    setState(() => _enviando = true);
    final r = await SupportService.enviarMensaje(
        idreclamo: widget.idreclamo, mensaje: texto);
    if (!mounted) return;

    if (r.ok) {
      _msgCtrl.clear();
      setState(() => _enviando = false);
      _scrollAlFinal();
    } else {
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.error ?? 'Error al enviar'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _opcionesMensaje(MensajeSoporte m) async {
    if (!m.esMio) return;

    final opcion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusXL)),
          ),
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppColors.secondary),
                title: Text('Editar mensaje',
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: colorScheme.onSurface)),
                onTap: () => Navigator.pop(ctx, 'editar'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: Text('Eliminar mensaje',
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: AppColors.error)),
                onTap: () => Navigator.pop(ctx, 'eliminar'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    if (opcion == 'editar') await _editarMensaje(m);
    if (opcion == 'eliminar') await _eliminarMensaje(m);
  }

  Future<void> _editarMensaje(MensajeSoporte m) async {
    final ctrl = TextEditingController(text: m.mensaje);
    final nuevoTexto = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL)),
          title: Text('Editar mensaje',
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface)),
          content: TextField(
            controller: ctrl,
            maxLines: 4,
            autofocus: true,
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: colorScheme.onSurface),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    ctrl.dispose();
    if (nuevoTexto == null || nuevoTexto.isEmpty || nuevoTexto == m.mensaje) return;

    final r = await SupportService.editarMensaje(
      idreclamo:  widget.idreclamo,
      idmensaje:  m.idmensaje,
      nuevoTexto: nuevoTexto,
    );
    if (!mounted) return;
    if (r.ok) {
      // No actualizamos localmente porque Realtime lo hará automáticamente
      _scrollAlFinal();
    }
  }

  Future<void> _eliminarMensaje(MensajeSoporte m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL)),
          title: Text('Eliminar mensaje',
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface)),
          content: Text('¿Estás seguro de eliminar este mensaje?',
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: colorScheme.onSurfaceVariant)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    final r = await SupportService.eliminarMensaje(
      idreclamo: widget.idreclamo,
      idmensaje: m.idmensaje,
    );
    if (!mounted) return;
    if (r.ok) {
      // No actualizamos localmente porque Realtime lo hará automáticamente
      _scrollAlFinal();
    }
  }

  Future<void> _cerrarTicket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL)),
          title: Text('Cerrar ticket',
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface)),
          content: Text(
              '¿Marcar este ticket como resuelto? El cliente ya no podrá responder.',
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: colorScheme.onSurfaceVariant)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    final r = await SupportService.cerrarTicket(widget.idreclamo);
    if (!mounted) return;
    if (r.ok) {
      setState(() {
        _ticket = TicketDetalle(
          idreclamo: _ticket!.idreclamo,
          asunto:    _ticket!.asunto,
          estado:    'Cerrado',
          fecha:     _ticket!.fecha,
          cerrado:   true,
          cliente:   _ticket!.cliente,
          mensajes:  _ticket!.mensajes,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ticket cerrado correctamente'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cerrado = _ticket?.cerrado ?? false;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (_loading)
              const Expanded(
                  child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary)))
            else if (_error != null)
              Expanded(child: _buildError(context))
            else
              Expanded(child: _buildMensajes(context)),

            if (!_loading && _error == null && !cerrado)
              _buildInputArea(context, colorScheme),

            if (!_loading && cerrado)
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                color: colorScheme.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text('Este ticket está cerrado',
                        style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cerrado = _ticket?.cerrado ?? false;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingM),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: colorScheme.onSurface, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.asunto,
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_ticket != null)
                  Text(
                    widget.esAdmin
                        ? 'Cliente: ${_ticket!.cliente}'
                        : cerrado ? 'Cerrado' : 'Abierto',
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        color: cerrado
                            ? colorScheme.onSurfaceVariant
                            : AppColors.success),
                  ),
              ],
            ),
          ),
          if (widget.esAdmin && !cerrado)
            IconButton(
              onPressed: _cerrarTicket,
              icon: const Icon(Icons.check_circle_outline_rounded),
              color: AppColors.success,
              tooltip: 'Cerrar ticket',
            ),
        ],
      ),
    );
  }

  Widget _buildMensajes(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mensajes = _ticket?.mensajes ?? [];
    final nombreCliente = _ticket?.cliente ?? 'Cliente';

    if (mensajes.isEmpty) {
      return Center(
        child: Text('Sin mensajes todavía',
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                color: colorScheme.onSurfaceVariant)),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      physics: const BouncingScrollPhysics(),
      itemCount: mensajes.length,
      itemBuilder: (_, i) => _BurbujaMensaje(
        mensaje:  mensajes[i],
        esAdmin:  widget.esAdmin,
        nombreCliente: nombreCliente,
        onLongPress: mensajes[i].esMio
            ? () => _opcionesMensaje(mensajes[i])
            : null,
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        AppDimensions.paddingS,
        AppDimensions.paddingM,
        AppDimensions.paddingS + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                hintStyle: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                filled: true,
                fillColor: colorScheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusXL),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _enviar(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _enviando ? null : _enviar,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _enviando
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: _enviando
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 56, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: AppDimensions.paddingM),
            Text(_error ?? 'Error',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppDimensions.paddingM),
            ElevatedButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
  }
}

// ── Burbuja de mensaje individual ─────────────────────────────
class _BurbujaMensaje extends StatelessWidget {
  final MensajeSoporte mensaje;
  final bool           esAdmin;
  final String         nombreCliente;
  final VoidCallback?  onLongPress;

  const _BurbujaMensaje({
    required this.mensaje,
    required this.esAdmin,
    required this.nombreCliente,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final esDerecha = mensaje.esMio;

    final colorBurbuja = esDerecha
        ? AppColors.primary
        : colorScheme.surfaceVariant;
    final colorTexto = esDerecha
        ? Colors.white
        : colorScheme.onSurface;
    final colorMeta = esDerecha
        ? Colors.white.withOpacity(0.7)
        : colorScheme.onSurfaceVariant;

    String etiqueta;
    if (esDerecha) {
      etiqueta = 'Tú';
    } else {
      if (esAdmin) {
        etiqueta = mensaje.esAdmin ? 'Tú' : nombreCliente;
      } else {
        etiqueta = mensaje.esAdmin ? 'Soporte Dulce Hogar' : 'Tú';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            esDerecha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 3, left: 4, right: 4),
            child: Text(
              etiqueta,
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant),
            ),
          ),
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorBurbuja,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(16),
                  topRight:    const Radius.circular(16),
                  bottomLeft:
                      Radius.circular(esDerecha ? 16 : 4),
                  bottomRight:
                      Radius.circular(esDerecha ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mensaje.mensaje,
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        color: colorTexto,
                        height: 1.4),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatHoraReal(mensaje.fechaenvio),
                        style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            color: colorMeta),
                      ),
                      if (mensaje.editado) ...[
                        const SizedBox(width: 4),
                        Text('· editado',
                            style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: colorMeta)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHoraReal(String fecha) {
    try {
      final d = DateTime.parse(fecha).toUtc();
      final horaLocal = d.subtract(const Duration(hours: 5));
      final h = horaLocal.hour.toString().padLeft(2, '0');
      final m = horaLocal.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}