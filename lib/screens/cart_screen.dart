// lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
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
  }

  Future<void> _updateQty(int idproducto, int cantidad) async {
    setState(() => _processingId = true);
    final r = await CartService.actualizar(idproducto: idproducto, cantidad: cantidad);
    if (!mounted) return;
    setState(() {
      _processingId = false;
      if (r.ok) _items = r.data ?? [];
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
    setState(() { _items = []; _loading = false; });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  double get _subtotal => _items.fold(0, (s, i) => s + i.totalCalculado);
  double get _shipping  => _subtotal > 1500000 ? 0 : 50000;
  double get _total     => _subtotal + _shipping;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            else if (_items.isEmpty)
              Expanded(child: _buildEmptyState())
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadCart,
                  color: AppColors.primary,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(AppDimensions.paddingM, AppDimensions.paddingM, AppDimensions.paddingM, 0),
                          child: Text('${_items.length} artículo${_items.length != 1 ? 's' : ''}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
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
                      if (_shipping > 0)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
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
                                Expanded(child: Text('Agrega ${Formatters.precio(1500000 - _subtotal)} más para envío gratis', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600))),
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

  Widget _buildAppBar(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM, vertical: AppDimensions.paddingS),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppDimensions.radiusM)), child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
        ),
        const SizedBox(width: AppDimensions.paddingM),
        const Expanded(child: Text('Mi Carrito', style: AppTextStyles.headlineLarge)),
        if (_items.isNotEmpty)
          GestureDetector(onTap: _vaciar, child: Text('Vaciar', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w600))),
      ],
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 100, height: 100, decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle), child: const Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.textHint)),
        const SizedBox(height: AppDimensions.paddingL),
        const Text('Tu carrito está vacío', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 8),
        const Text('Agrega productos para empezar', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppDimensions.paddingL),
        SizedBox(width: 200, child: ElevatedButton(onPressed: () => Navigator.of(context).pushReplacementNamed('/'), child: const Text('Ver productos'))),
      ],
    ),
  );

  Widget _buildCheckoutPanel(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppDimensions.paddingL),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -6))]),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _priceLine('Subtotal', Formatters.precio(_subtotal)),
        const SizedBox(height: 6),
        _priceLine('Envío', _shipping == 0 ? 'Gratis' : Formatters.precio(_shipping), valueColor: _shipping == 0 ? AppColors.success : null),
        const Divider(height: AppDimensions.paddingL, color: AppColors.divider),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: AppTextStyles.headlineMedium),
            Text(Formatters.precio(_total), style: AppTextStyles.priceLarge),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamed('/delivery-address', arguments: {'source': 'carrito', 'productos': _items.map((i) => ProductoCheckout(id: i.idproducto, nombre: i.nombre, precio: i.precio, cantidad: i.cantidad)).toList()}),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.payment_rounded, size: 20), SizedBox(width: 8), Text('Finalizar Compra')]),
        ),
      ],
    ),
  );

  Widget _priceLine(String label, String value, {Color? valueColor}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: AppTextStyles.bodyMedium),
      Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
    ],
  );
}

class _CartItemCard extends StatelessWidget {
  final CarritoItem item;
  final bool processing;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemCard({required this.item, required this.processing, required this.onIncrement, required this.onDecrement, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusM), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            child: SizedBox(
              width: 80, height: 80,
              child: item.imagenUrl != null
                  ? CachedNetworkImage(imageUrl: item.imagenUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.image_outlined, color: AppColors.textHint))
                  : Container(color: AppColors.surfaceVariant, child: const Icon(Icons.image_outlined, color: AppColors.textHint)),
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
                    Expanded(child: Text(item.nombre, style: AppTextStyles.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis)),
                    GestureDetector(
                      onTap: processing ? null : onRemove,
                      child: Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)), child: const Icon(Icons.close_rounded, size: 16, color: AppColors.error)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(Formatters.precio(item.precio), style: AppTextStyles.priceStyle),
                    QuantitySelector(quantity: item.cantidad, onIncrement: processing ? () {} : onIncrement, onDecrement: processing ? () {} : onDecrement),
                  ],
                ),
                if (item.cantidad > 1) ...[
                  const SizedBox(height: 4),
                  Text('Subtotal: ${Formatters.precio(item.totalCalculado)}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
