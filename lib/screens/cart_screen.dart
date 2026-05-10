import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../services/promocion_service.dart';
import '../utils/formatters.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CarritoItem> _items = [];
  bool _loading            = true;
  bool _processingId       = false;
  Map<int, double> _descuentosPorProducto = {}; // Mapa de descuentos

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _loading = true);
    final r = await CartService.getCarrito();
    if (!mounted) return;
    setState(() {
      _items   = r.data ?? [];
      _loading = false;
    });
    // Después de cargar los items, cargar promociones
    if (_items.isNotEmpty) {
      await _cargarPromociones();
    }
  }

  // Cargar promociones y aplicarlas a los productos del carrito
  Future<void> _cargarPromociones() async {
    print('🔵 [PROMOCIONES CARRITO] Iniciando carga de promociones');
    print('🔵 [PROMOCIONES CARRITO] Items en carrito: ${_items.length}');
    
    final result = await PromocionService.getPromociones();
    print('🔵 [PROMOCIONES CARRITO] Resultado ok: ${result.ok}, data length: ${result.data?.length}');
    
    if (result.ok && result.data != null) {
      final Map<int, double> descuentos = {};
      
      // Primero, obtener todos los productos con sus categorías
      final Map<int, int?> categoriasPorProducto = {};
      for (final item in _items) {
        // Aquí necesitamos la categoría de cada producto
        // Si CarritoItem no tiene idcategoria, necesitamos obtenerlo
        // Por ahora asumimos que podemos obtenerlo del producto
        // Si no está disponible, solo aplicamos promociones por producto o globales
        categoriasPorProducto[item.idproducto] = item.idcategoria;
      }
      
      for (final promo in result.data!) {
        print('🔵 [PROMOCIONES CARRITO] Procesando promo: ${promo.nombre} - scope: ${promo.scope}');
        
        if (promo.scope == 'producto' && promo.idproducto != null) {
          // Promoción específica de producto
          descuentos[promo.idproducto!] = promo.porcentaje;
          print('🔵 [PROMOCIONES CARRITO] Producto ${promo.idproducto} → ${promo.porcentaje * 100}% descuento');
          
        } else if (promo.scope == 'categoria' && promo.idcategoria != null) {
          // Promoción por categoría - aplicar a todos los productos de esa categoría
          for (final item in _items) {
            if (item.idcategoria == promo.idcategoria) {
              descuentos[item.idproducto] = promo.porcentaje;
              print('🔵 [PROMOCIONES CARRITO] Producto ${item.idproducto} (cat ${promo.idcategoria}) → ${promo.porcentaje * 100}% descuento');
            }
          }
          
        } else if (promo.scope == 'global') {
          // Promoción global - aplicar a todos los productos
          for (final item in _items) {
            // Solo aplicar si no tiene ya un descuento específico mayor
            if (!descuentos.containsKey(item.idproducto) || 
                (descuentos[item.idproducto] ?? 0) < promo.porcentaje) {
              descuentos[item.idproducto] = promo.porcentaje;
              print('🔵 [PROMOCIONES CARRITO] Producto ${item.idproducto} (global) → ${promo.porcentaje * 100}% descuento');
            }
          }
        }
      }
      
      setState(() {
        _descuentosPorProducto = descuentos;
      });
      print('🔵 [PROMOCIONES CARRITO] Total descuentos aplicados: ${_descuentosPorProducto.length}');
    }
  }

  // Calcular precio con descuento
  double _getPrecioConDescuento(CarritoItem item) {
    final descuento = _descuentosPorProducto[item.idproducto];
    if (descuento != null && descuento > 0) {
      return item.precio * (1 - descuento);
    }
    return item.precio;
  }

  // Calcular subtotal con descuento
  double _getSubtotalConDescuento(CarritoItem item) {
    final precioConDescuento = _getPrecioConDescuento(item);
    return precioConDescuento * item.cantidad;
  }

  Future<void> _updateQty(int idproducto, int cantidad) async {
    setState(() => _processingId = true);

    // Guardar las URLs de imagen actuales antes de actualizar
    final imageCache = {
      for (final item in _items)
        if (item.imagenUrl != null) item.idproducto: item.imagenUrl!
    };
    
    // También guardar las categorías
    final categoriaCache = {
      for (final item in _items)
        if (item.idcategoria != null) item.idproducto: item.idcategoria!
    };

    final r = await CartService.actualizar(idproducto: idproducto, cantidad: cantidad);
    if (!mounted) return;

    setState(() {
      _processingId = false;
      if (r.ok) {
        // El backend no devuelve imagenUrl en el PUT — reinyectarla desde el cache
        _items = (r.data ?? []).map((item) {
          return CarritoItem(
            idproducto: item.idproducto,
            nombre:     item.nombre,
            precio:     item.precio,
            cantidad:   item.cantidad,
            subtotal:   item.subtotal,
            imagenUrl:  imageCache[item.idproducto],
            idcategoria: categoriaCache[item.idproducto], // Reinyectar categoría
          );
        }).toList();
        
        // Recargar promociones después de actualizar el carrito
        _cargarPromociones();
      }
    });

    if (!r.ok) _showSnack(r.error ?? 'Error');
  }

  Future<void> _vaciar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Estás seguro de que quieres vaciar el carrito?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Vaciar', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    await CartService.vaciar();
    if (!mounted) return;
    setState(() { 
      _items = []; 
      _loading = false;
      _descuentosPorProducto = {};
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  // Calcular subtotal total con descuentos aplicados
  double get _subtotalConDescuento => _items.fold(0, (s, i) => s + _getSubtotalConDescuento(i));
  double get _subtotalOriginal => _items.fold(0, (s, i) => s + (i.precio * i.cantidad));
  double get _ahorroTotal => _subtotalOriginal - _subtotalConDescuento;
  double get _shipping => _subtotalConDescuento > 1500000 ? 0 : 50000;
  double get _total => _subtotalConDescuento + _shipping;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            else if (_items.isEmpty)
              Expanded(child: _buildEmptyState(context))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadCart();
                  },
                  color: AppColors.primary,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(AppDimensions.paddingM, AppDimensions.paddingM, AppDimensions.paddingM, 0),
                          child: Text('${_items.length} artículo${_items.length != 1 ? 's' : ''}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(AppDimensions.paddingM),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => Padding(
                              padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
                              child: _CartItemCard(
                                item: _items[i],
                                descuento: _descuentosPorProducto[_items[i].idproducto],
                                processing: _processingId,
                                onIncrement: () => _updateQty(_items[i].idproducto, _items[i].cantidad + 1),
                                onDecrement: () => _updateQty(_items[i].idproducto, _items[i].cantidad - 1),
                                onRemove:    () => _updateQty(_items[i].idproducto, 0),
                              ),
                            ),
                            childCount: _items.length,
                          ),
                        ),
                      ),
                      // Mostrar resumen de ahorros
                      if (_ahorroTotal > 0)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
                            padding: const EdgeInsets.all(AppDimensions.paddingM),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                              border: Border.all(color: AppColors.success.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_offer_rounded, color: AppColors.success, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '¡Ahorro total!',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Estás ahorrando ${Formatters.precio(_ahorroTotal)}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_shipping > 0)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM, vertical: AppDimensions.paddingS),
                            padding: const EdgeInsets.all(AppDimensions.paddingM),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(child: Text('Agrega ${Formatters.precio(1500000 - _subtotalConDescuento)} más para envío gratis', style: textTheme.bodySmall?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600))),
                              ],
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.paddingM)),
                    ],
                  ),
                ),
              ),
            if (_items.isNotEmpty) _buildCheckoutPanel(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM, vertical: AppDimensions.paddingS),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40, 
              height: 40, 
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant, 
                borderRadius: BorderRadius.circular(AppDimensions.radiusM)
              ), 
              child: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface, size: 20)
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(child: Text('Mi Carrito', style: textTheme.headlineLarge)),
          if (_items.isNotEmpty)
            GestureDetector(
              onTap: _vaciar, 
              child: Text('Vaciar', style: textTheme.bodySmall?.copyWith(color: AppColors.error, fontWeight: FontWeight.w600))
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, 
            height: 100, 
            decoration: BoxDecoration(color: colorScheme.surfaceVariant, shape: BoxShape.circle), 
            child: Icon(Icons.shopping_cart_outlined, size: 48, color: colorScheme.onSurfaceVariant)
          ),
          const SizedBox(height: AppDimensions.paddingL),
          Text('Tu carrito está vacío', style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Agrega productos para empezar', style: textTheme.bodyMedium),
          const SizedBox(height: AppDimensions.paddingL),
          SizedBox(
            width: 200, 
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/'), 
              child: const Text('Ver productos')
            )
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutPanel(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -6))]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mostrar subtotal original tachado si hay descuento
          if (_ahorroTotal > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal original', style: textTheme.bodyMedium),
                Text(
                  Formatters.precio(_subtotalOriginal),
                  style: textTheme.bodyMedium?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          if (_ahorroTotal > 0) const SizedBox(height: 6),
          _priceLine(context, 'Subtotal con descuento', Formatters.precio(_subtotalConDescuento), valueColor: AppColors.success),
          const SizedBox(height: 6),
          _priceLine(context, 'Envío', _shipping == 0 ? 'Gratis' : Formatters.precio(_shipping), valueColor: _shipping == 0 ? AppColors.success : null),
          Divider(height: AppDimensions.paddingL, color: colorScheme.outline),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: textTheme.headlineMedium),
              Text(Formatters.precio(_total), style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed('/delivery-address', arguments: {'source': 'carrito', 'productos': _items.map((i) => ProductoCheckout(
              id: i.idproducto, 
              nombre: i.nombre, 
              precio: _getPrecioConDescuento(i), // Enviar precio con descuento
              cantidad: i.cantidad
            )).toList()}),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.payment_rounded, size: 20), SizedBox(width: 8), Text('Finalizar Compra')]),
          ),
        ],
      ),
    );
  }

  Widget _priceLine(BuildContext context, String label, String value, {Color? valueColor}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyMedium),
        Text(value, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: valueColor ?? colorScheme.onSurface)),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CarritoItem item;
  final double? descuento;
  final bool processing;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item, 
    required this.descuento,
    required this.processing, 
    required this.onIncrement, 
    required this.onDecrement, 
    required this.onRemove
  });

  double get _precioConDescuento => descuento != null && descuento! > 0 
      ? item.precio * (1 - descuento!) 
      : item.precio;
      
  double get _subtotalConDescuento => _precioConDescuento * item.cantidad;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final hayDescuento = descuento != null && descuento! > 0;
    
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(AppDimensions.radiusM), 
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))]
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            child: Container(
              width: 80, height: 80,
              color: colorScheme.surfaceVariant,
              child: item.imagenUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imagenUrl!,
                      fit: BoxFit.contain,
                      width: 80,
                      height: 80,
                      placeholder: (_, __) => const Center(
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.image_outlined, color: colorScheme.onSurfaceVariant),
                    )
                  : Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(item.nombre, style: textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis)),
                    GestureDetector(
                      onTap: processing ? null : onRemove,
                      child: Container(
                        width: 28, height: 28, 
                        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)), 
                        child: const Icon(Icons.close_rounded, size: 16, color: AppColors.error)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hayDescuento) ...[
                          Text(
                            Formatters.precio(item.precio),
                            style: textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            Formatters.precio(_precioConDescuento),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${((descuento ?? 0) * 100).toStringAsFixed(0)}% OFF',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ] else ...[
                          Text(
                            Formatters.precio(item.precio),
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ],
                    ),
                    QuantitySelector(
                      quantity: item.cantidad, 
                      onIncrement: processing ? () {} : onIncrement, 
                      onDecrement: processing ? () {} : onDecrement,
                    ),
                  ],
                ),
                if (item.cantidad > 1 && hayDescuento) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Subtotal: ${Formatters.precio(_subtotalConDescuento)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else if (item.cantidad > 1) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Subtotal: ${Formatters.precio(item.totalCalculado)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}