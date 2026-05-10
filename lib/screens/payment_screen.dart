import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/mercadopago_service.dart';
import '../services/promocion_service.dart';
import '../utils/formatters.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int? _selectedMethod;
  bool _loading = false;

  List<ProductoCheckout> _productos   = [];
  String                 _source      = 'carrito';
  int?                   _iddireccion;
  
  Map<int, double> _descuentosPorProducto = {};

  double get _totalOriginal => _productos.fold(0, (s, p) => s + p.precio * p.cantidad);
  double get _totalConDescuento => _productos.fold(0, (s, p) {
    final descuento = _descuentosPorProducto[p.id] ?? 0;
    final precioConDescuento = p.precio * (1 - descuento);
    return s + precioConDescuento * p.cantidad;
  });
  double get _ahorroTotal => _totalOriginal - _totalConDescuento;
  bool get _tieneDescuento => _ahorroTotal > 0;

  final List<_PaymentMethod> _methods = [
    _PaymentMethod(id: 0, title: 'Pagar con MercadoPago', icon: Icons.credit_card_rounded, color: const Color(0xFF009EE3), available: true),
    _PaymentMethod(id: 1, title: 'Pagar con Nequi', subtitle: 'Próximamente', icon: Icons.phone_android_rounded, color: const Color(0xFF6B0F8C), available: false),
    _PaymentMethod(id: 2, title: 'Transferencia Bancolombia', subtitle: 'Próximamente', icon: Icons.account_balance_rounded, color: const Color(0xFFF5A623), available: false),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _productos   = (args['productos'] as List<ProductoCheckout>?) ?? [];
      _source      = args['source'] as String? ?? 'carrito';
      _iddireccion = args['iddireccion'] as int?;
      _cargarPromociones();
    }
  }

  // Cargar promociones y aplicarlas a los productos
  Future<void> _cargarPromociones() async {
    final result = await PromocionService.getPromociones();
    if (!mounted) return;
    
    if (result.ok && result.data != null) {
      final Map<int, double> descuentos = {};
      
      for (final promo in result.data!) {
        if (promo.scope == 'producto' && promo.idproducto != null) {
          descuentos[promo.idproducto!] = promo.porcentaje;
        } else if (promo.scope == 'global') {
          for (final producto in _productos) {
            if (!descuentos.containsKey(producto.id) || 
                (descuentos[producto.id] ?? 0) < promo.porcentaje) {
              descuentos[producto.id] = promo.porcentaje;
            }
          }
        }
      }
      
      setState(() {
        _descuentosPorProducto = descuentos;
      });
    }
  }

  // Obtener precio con descuento para un producto
  double _getPrecioConDescuento(ProductoCheckout producto) {
    final descuento = _descuentosPorProducto[producto.id] ?? 0;
    if (descuento > 0) {
      return producto.precio * (1 - descuento);
    }
    return producto.precio;
  }

  Future<void> _pagar() async {
    if (_selectedMethod != 0) return;
    setState(() => _loading = true);

    // Crear lista de productos con precios actualizados (con descuento)
    final productosConDescuento = _productos.map((p) => ProductoCheckout(
      id: p.id,
      nombre: p.nombre,
      precio: _getPrecioConDescuento(p),
      cantidad: p.cantidad,
    )).toList();

    final r = await MercadoPagoService.crearPreferencia(
      productos:   productosConDescuento,
      source:      _source,
      iddireccion: _iddireccion,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    r.when(
      onOk: (url) async {
        if (url != null) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            _showSnack('No se pudo abrir el navegador');
          }
        }
      },
      onError: (e) => _showSnack(e),
    );
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating)
  );

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
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  children: [
                    const SizedBox(height: AppDimensions.paddingM),

                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.payment_rounded, color: AppColors.primary, size: 36),
                    ),

                    const SizedBox(height: AppDimensions.paddingM),
                    Text('Método de pago', style: textTheme.displayMedium),
                    const SizedBox(height: 6),
                    Text('Selecciona cómo quieres pagar tu pedido', 
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant), 
                      textAlign: TextAlign.center),

                    const SizedBox(height: AppDimensions.paddingL),
                    _buildOrderSummary(context),
                    const SizedBox(height: AppDimensions.paddingL),

                    ..._methods.map((m) {
                      final isSelected = _selectedMethod == m.id;
                      return GestureDetector(
                        onTap: m.available ? () => setState(() => _selectedMethod = m.id) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM, vertical: AppDimensions.paddingM),
                          decoration: BoxDecoration(
                            color: m.available 
                                ? (isSelected ? AppColors.primary.withOpacity(0.05) : colorScheme.surface) 
                                : colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : colorScheme.outline, 
                              width: isSelected ? 2 : 1
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  color: m.available ? m.color.withOpacity(0.12) : colorScheme.outline.withOpacity(0.5), 
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusS)
                                ),
                                child: Icon(m.icon, color: m.available ? m.color : colorScheme.onSurfaceVariant, size: 22),
                              ),
                              const SizedBox(width: AppDimensions.paddingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.title, 
                                      style: textTheme.titleMedium?.copyWith(
                                        color: m.available ? colorScheme.onSurface : colorScheme.onSurfaceVariant
                                      )
                                    ),
                                    if (m.subtitle != null) 
                                      Text(m.subtitle!, 
                                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                m.available ? Icons.arrow_forward_rounded : Icons.lock_outline_rounded, 
                                color: m.available ? AppColors.primary : colorScheme.onSurfaceVariant, 
                                size: 20
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: AppDimensions.paddingL),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_rounded, color: colorScheme.onSurfaceVariant, size: 14),
                        const SizedBox(width: 4),
                        Text('Pago 100% seguro y encriptado', 
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)
                        ),
                      ],
                    ),

                    if (_selectedMethod != null) ...[
                      const SizedBox(height: AppDimensions.paddingL),
                      ElevatedButton(
                        onPressed: _loading ? null : _pagar,
                        child: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lock_rounded, size: 18), SizedBox(width: 8), Text('Proceder al pago')]),
                      ),
                    ],

                    const SizedBox(height: AppDimensions.paddingXXL),
                  ],
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
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM, vertical: AppDimensions.paddingS),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40, height: 40, 
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant, 
                borderRadius: BorderRadius.circular(AppDimensions.radiusM)
              ), 
              child: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface, size: 20)
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Text('Pago', style: textTheme.headlineLarge),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant, 
        borderRadius: BorderRadius.circular(AppDimensions.radiusM), 
        border: Border.all(color: colorScheme.outline)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen del pedido', style: textTheme.headlineMedium),
          const SizedBox(height: AppDimensions.paddingS),
          
          // Lista de productos - SOLO EL PRECIO CON DESCUENTO
          ..._productos.map((p) {
            final descuento = _descuentosPorProducto[p.id] ?? 0;
            final precioConDescuento = _getPrecioConDescuento(p);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${p.nombre} (x${p.cantidad})', 
                      style: textTheme.bodySmall, 
                      overflow: TextOverflow.ellipsis
                    ),
                  ),
                  Text(
                    Formatters.precio(precioConDescuento * p.cantidad),
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: descuento > 0 ? AppColors.success : null,
                    ),
                  ),
                ],
              ),
            );
          }),
          
          Divider(height: AppDimensions.paddingM, color: colorScheme.outline),
          
          // Total a pagar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total a pagar:', style: textTheme.titleMedium),
              Text(
                Formatters.precio(_totalConDescuento), 
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _tieneDescuento ? AppColors.success : null,
                ),
              ),
            ],
          ),
          
          // Badge de ahorro (opcional)
          if (_tieneDescuento) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_offer_rounded, size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'Estás ahorrando ${Formatters.precio(_ahorroTotal)}',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentMethod {
  final int id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool available;
  const _PaymentMethod({required this.id, required this.title, this.subtitle, required this.icon, required this.color, required this.available});
}