import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../models/order_models.dart';
import '../services/order_service.dart';
import '../utils/formatters.dart';
import '../widgets/app_widgets.dart';

// ══════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL — lista de pedidos
// ══════════════════════════════════════════════════════════════
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<PedidoResumen> _pedidos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error   = null;
    });

    final r = await OrderService.getMisPedidos();

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.ok) {
        _pedidos = r.data ?? [];
      } else {
        _error = r.error;
      }
    });
  }

  void _irADetalle(PedidoResumen pedido) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(idpedido: pedido.idpedido),
        settings: RouteSettings(name: '/orders/${pedido.idpedido}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      bottomNavigationBar: const SharedBottomNav(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_error != null)
              Expanded(child: _buildError(context))
            else if (_pedidos.isEmpty)
              Expanded(child: _buildVacio(context))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _cargar,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _pedidos.length,
                    itemBuilder: (_, i) => _PedidoCard(
                      pedido: _pedidos[i],
                      onTap: () => _irADetalle(_pedidos[i]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingM,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: colorScheme.onSurface, size: 20),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          const Icon(Icons.receipt_long_rounded,
              color: AppColors.primary, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mis Pedidos${_pedidos.isNotEmpty ? ' (${_pedidos.length})' : ''}',
              style: textTheme.headlineLarge,
            ),
          ),
        ],
      ),
    );
  }

  // ── Estado vacío ───────────────────────────────────────────
  Widget _buildVacio(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: AppDimensions.paddingL),
          Text('Aún no tienes pedidos',
              style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Tus compras aparecerán aquí',
              style: textTheme.bodyMedium),
          const SizedBox(height: AppDimensions.paddingL),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/'),
              child: const Text('Explorar productos'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Estado error ───────────────────────────────────────────
  Widget _buildError(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 56, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: AppDimensions.paddingM),
            Text(_error ?? 'Error al cargar pedidos',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.paddingM),
            ElevatedButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CARD de cada pedido en la lista
// ══════════════════════════════════════════════════════════════
class _PedidoCard extends StatelessWidget {
  final PedidoResumen pedido;
  final VoidCallback onTap;

  const _PedidoCard({required this.pedido, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Ícono del pedido ───────────────────────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),

            // ── Info del pedido ────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(pedido.numero,
                          style: textTheme.titleMedium),
                      // Badge de estado
                      _EstadoBadge(
                        estado:      pedido.estado,
                        colorEstado: pedido.colorEstado,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatFecha(pedido.fecha),
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${pedido.totalItems} ${pedido.totalItems == 1 ? 'producto' : 'productos'}',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        Formatters.precio(pedido.total),
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
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
    if (fecha.isEmpty) return 'Fecha desconocida';
    try {
      final dt = DateTime.parse(fecha);
      const meses = [
        '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      return '${dt.day} ${meses[dt.month]} ${dt.year}';
    } catch (_) {
      return fecha;
    }
  }
}

// ══════════════════════════════════════════════════════════════
// BADGE de estado — reutilizable también en el detalle
// ══════════════════════════════════════════════════════════════
class _EstadoBadge extends StatelessWidget {
  final String estado;
  final String colorEstado;

  const _EstadoBadge({required this.estado, required this.colorEstado});

  @override
  Widget build(BuildContext context) {
    final colores = _resolverColor(colorEstado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colores.$1,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colores.$2,
        ),
      ),
    );
  }

  // Devuelve (colorFondo, colorTexto) según el estado
  (Color, Color) _resolverColor(String color) {
    switch (color) {
      case 'warning':
        return (
          AppColors.warning.withOpacity(0.15),
          AppColors.warning,
        );
      case 'info':
        return (
          AppColors.secondary.withOpacity(0.12),
          AppColors.secondary,
        );
      case 'primary':
        return (
          AppColors.primary.withOpacity(0.12),
          AppColors.primaryDark,
        );
      case 'success':
        return (
          AppColors.success.withOpacity(0.12),
          AppColors.primaryDark,
        );
      case 'error':
        return (
          AppColors.error.withOpacity(0.12),
          AppColors.error,
        );
      default:
        return (
          AppColors.surfaceVariant,
          AppColors.textSecondary,
        );
    }
  }
}

// ══════════════════════════════════════════════════════════════
// PANTALLA DETALLE — productos del pedido
// ══════════════════════════════════════════════════════════════
class OrderDetailScreen extends StatefulWidget {
  final int idpedido;

  const OrderDetailScreen({super.key, required this.idpedido});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  PedidoDetalle? _detalle;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error   = null;
    });

    final r = await OrderService.getDetallePedido(widget.idpedido);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.ok) {
        _detalle = r.data;
      } else {
        _error = r.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (_loading)
              const Expanded(
                child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_error != null)
              Expanded(child: _buildError(context))
            else if (_detalle != null)
              Expanded(child: _buildContenido(context)),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingM,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: colorScheme.onSurface, size: 20),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Text(
              _detalle != null
                  ? 'Pedido ${_detalle!.numero}'
                  : 'Detalle del pedido',
              style: textTheme.headlineLarge,
            ),
          ),
          if (_detalle != null)
            _EstadoBadge(
              estado:      _detalle!.estado,
              colorEstado: _detalle!.colorEstado,
            ),
        ],
      ),
    );
  }

  // ── Contenido principal ─────────────────────────────────────
  Widget _buildContenido(BuildContext context) {
    final d = _detalle!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tarjeta resumen del pedido ──────────────────────
          _InfoCard(detalle: d),
          const SizedBox(height: AppDimensions.paddingM),

          // ── Título sección productos ────────────────────────
          Text(
            'Productos (${d.productos.length})',
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: AppDimensions.paddingS),

          // ── Lista de productos ──────────────────────────────
          ...d.productos.map((item) => _ItemProducto(item: item)),

          const SizedBox(height: AppDimensions.paddingM),

          // ── Total final ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(color: AppColors.primaryBorder, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total del pedido',
                    style: textTheme.titleMedium),
                Text(
                  Formatters.precio(d.total),
                  style: textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.paddingL),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 56, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: AppDimensions.paddingM),
            Text(_error ?? 'Error al cargar el pedido',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.paddingM),
            ElevatedButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TARJETA de info general del pedido (fecha, dirección, estado)
// ══════════════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  final PedidoDetalle detalle;
  const _InfoCard({required this.detalle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Fecha',
            value: _formatFecha(detalle.fecha),
          ),
          Divider(color: colorScheme.outline, height: 20),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Dirección de entrega',
            value: detalle.direccion,
          ),
          Divider(color: colorScheme.outline, height: 20),
          _InfoRow(
            icon: Icons.local_shipping_outlined,
            label: 'Estado',
            value: detalle.estado,
          ),
        ],
      ),
    );
  }

  String _formatFecha(String fecha) {
    if (fecha.isEmpty) return 'Fecha desconocida';
    try {
      final dt = DateTime.parse(fecha);
      const meses = [
        '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
      ];
      return '${dt.day} de ${meses[dt.month]} de ${dt.year}';
    } catch (_) {
      return fecha;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// FILA de cada producto dentro del detalle
// ══════════════════════════════════════════════════════════════
class _ItemProducto extends StatelessWidget {
  final ItemPedido item;
  const _ItemProducto({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Imagen del producto ──────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: SizedBox(
              width: 60,
              height: 60,
              child: item.imagen != null
                  ? CachedNetworkImage(
                      imageUrl: item.imagen!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholder(context),
                    )
                  : _placeholder(context),
            ),
          ),
          const SizedBox(width: 12),

          // ── Nombre + cantidad ────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombre,
                  style: textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Cantidad: ${item.cantidad}  ×  ${Formatters.precio(item.precio)}',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // ── Subtotal ─────────────────────────────────────────
          Text(
            Formatters.precio(item.subtotal),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      color: colorScheme.surfaceVariant,
      child: Icon(Icons.image_outlined,
          color: colorScheme.onSurfaceVariant, size: 28),
    );
  }
}