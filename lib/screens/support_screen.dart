import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/support_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';
import 'support_chat_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<TicketResumen> _tickets = [];
  bool    _loading  = true;
  String? _error;
  bool    _esAdmin  = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });

    // Saber si es admin
    final perfil = await AuthService.getPerfil();
    if (!mounted) return;
    _esAdmin = perfil.data?.esAdmin ?? false;

    final r = _esAdmin
        ? await SupportService.getTodosTickets()
        : await SupportService.getMisTickets();

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.ok) _tickets = r.data ?? [];
      else      _error   = r.error;
    });
  }

  void _irAChat(TicketResumen ticket) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SupportChatScreen(
        idreclamo: ticket.idreclamo,
        asunto:    ticket.asunto,
        esAdmin:   _esAdmin,
      ),
    ));
    // Recargar al volver para actualizar badges de "nuevos"
    _cargar();
  }

  Future<void> _abrirNuevoTicket() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NuevoTicketSheet(
        onCreado: () {
          Navigator.pop(context);
          _cargar();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      bottomNavigationBar: const SharedBottomNav(),
      floatingActionButton: !_esAdmin
          ? FloatingActionButton.extended(
              onPressed: _abrirNuevoTicket,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
              label: const Text('Nueva consulta',
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (_loading)
              const Expanded(
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (_error != null)
              Expanded(child: _buildError(context))
            else if (_tickets.isEmpty)
              Expanded(child: _buildVacio(context))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _cargar,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _tickets.length,
                    itemBuilder: (_, i) => _TicketCard(
                      ticket:  _tickets[i],
                      esAdmin: _esAdmin,
                      onTap:   () => _irAChat(_tickets[i]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nuevos = _tickets.where((t) => t.tieneNuevos).length;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingM),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusM)),
              child: Icon(Icons.arrow_back_rounded,
                  color: colorScheme.onSurface, size: 20),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          const Icon(Icons.support_agent_rounded,
              color: AppColors.primary, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _esAdmin ? 'Mensajes de clientes' : 'Soporte y consultas',
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface),
                ),
                if (nuevos > 0)
                  Text('$nuevos con mensajes nuevos',
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVacio(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: AppDimensions.paddingL),
          Text(
            _esAdmin ? 'Sin consultas de clientes' : 'Sin consultas todavía',
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            _esAdmin
                ? 'Aquí verás los mensajes de tus clientes'
                : 'Toca el botón para hacer una consulta',
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
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
            Text(_error ?? 'Error al cargar',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
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

// ── Card de cada ticket ───────────────────────────────────────
class _TicketCard extends StatelessWidget {
  final TicketResumen ticket;
  final bool          esAdmin;
  final VoidCallback  onTap;

  const _TicketCard({
    required this.ticket,
    required this.esAdmin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final abierto = ticket.estaAbierto;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: ticket.tieneNuevos
              ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            // Ícono con badge de nuevos
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: abierto
                        ? AppColors.primary.withOpacity(0.10)
                        : colorScheme.surfaceVariant,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Icon(
                    abierto
                        ? Icons.chat_rounded
                        : Icons.check_circle_outline_rounded,
                    color: abierto
                        ? AppColors.primary
                        : colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                if (ticket.tieneNuevos)
                  Positioned(
                    right: -3, top: -3,
                    child: Container(
                      width: 12, height: 12,
                      decoration: const BoxDecoration(
                          color: AppColors.error, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(ticket.asunto,
                            style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      // Badge estado
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: abierto
                              ? AppColors.success.withOpacity(0.12)
                              : colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull),
                        ),
                        child: Text(
                          ticket.estado,
                          style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: abierto
                                  ? AppColors.success
                                  : colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatFecha(ticket.fecha),
                        style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 12, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        '${ticket.totalMensajes}',
                        style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant),
                      ),
                      if (ticket.tieneNuevos) ...[
                        const SizedBox(width: 8),
                        const Text('● Nuevo',
                            style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatFecha(String fecha) {
    try {
      final d = DateTime.parse(fecha);
      const m = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
                     'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
      return '${d.day} ${m[d.month]} ${d.year}';
    } catch (_) {
      return fecha;
    }
  }
}

// ── Sheet para abrir nuevo ticket ────────────────────────────
class _NuevoTicketSheet extends StatefulWidget {
  final VoidCallback onCreado;
  const _NuevoTicketSheet({required this.onCreado});

  @override
  State<_NuevoTicketSheet> createState() => _NuevoTicketSheetState();
}

class _NuevoTicketSheetState extends State<_NuevoTicketSheet> {
  final _asuntoCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();
  bool  _enviando   = false;

  @override
  void dispose() {
    _asuntoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (_asuntoCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Completa todos los campos'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _enviando = true);
    final r = await SupportService.abrirTicket(
      asunto:      _asuntoCtrl.text.trim(),
      descripcion: _descCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _enviando = false);
    if (r.ok) {
      widget.onCreado();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.error ?? 'Error al crear consulta'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXL)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.paddingL,
        AppDimensions.paddingM,
        AppDimensions.paddingL,
        AppDimensions.paddingL + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Row(
            children: [
              const Icon(Icons.add_comment_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text('Nueva consulta', 
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),
          TextField(
            controller: _asuntoCtrl,
            maxLength: 100,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontFamily: AppTextStyles.fontFamily,
            ),
            decoration: InputDecoration(
              labelText: 'Asunto',
              hintText: 'Ej: Consulta sobre el Televisor LED 50"',
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            maxLength: 500,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontFamily: AppTextStyles.fontFamily,
            ),
            decoration: InputDecoration(
              labelText: 'Descripción',
              hintText: 'Cuéntanos tu consulta con el mayor detalle posible...',
              alignLabelWithHint: true,
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enviando ? null : _crear,
              child: _enviando
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Enviar consulta'),
            ),
          ),
        ],
      ),
    );
  }
}