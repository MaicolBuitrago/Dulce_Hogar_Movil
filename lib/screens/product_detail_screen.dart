// lib/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../services/favorites_service.dart';
import '../utils/formatters.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int  _currentImageIndex = 0;
  int  _selectedQuantity  = 1;
  bool _isFavorite        = false;
  bool _addingToCart      = false;
  bool _togglingFav       = false;

  final _pageController = PageController();
  Producto? _producto;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _producto = ModalRoute.of(context)?.settings.arguments as Producto?;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    if (_producto == null) return;
    setState(() => _addingToCart = true);
    final r = await CartService.agregar(idproducto: _producto!.idproducto, cantidad: _selectedQuantity);
    if (!mounted) return;
    setState(() => _addingToCart = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(r.ok ? '¡Agregado al carrito!' : (r.error ?? 'Error')),
      backgroundColor: r.ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _toggleFavorite() async {
    if (_producto == null) return;
    setState(() => _togglingFav = true);
    final r = _isFavorite
        ? await FavoritesService.eliminar(_producto!.idproducto)
        : await FavoritesService.agregar(_producto!.idproducto);
    if (!mounted) return;
    setState(() {
      _togglingFav = false;
      if (r.ok) _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _producto;
    if (p == null) {
      return const Scaffold(body: Center(child: Text('Producto no encontrado')));
    }

    final images = p.imagenes.isNotEmpty ? p.imagenes : <String>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Galería ──
                    _buildGallery(context, images),

                    // ── Info ──
                    Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nombre, style: AppTextStyles.displayMedium),
                          const SizedBox(height: 6),
                          if (p.descripcion != null)
                            Text(p.descripcion!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),

                          const SizedBox(height: AppDimensions.paddingM),
                          const Divider(color: AppColors.divider),
                          const SizedBox(height: AppDimensions.paddingM),

                          // Precio
                          Text(
                            Formatters.precio(p.precio),
                            style: AppTextStyles.priceLarge.copyWith(fontSize: 26),
                          ),

                          const SizedBox(height: AppDimensions.paddingM),

                          // Stock
                          Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                p.disponible ? 'Disponibles: ${p.stock}' : 'Sin stock',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: p.disponible ? AppColors.textPrimary : AppColors.error,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppDimensions.paddingM),

                          // Cantidad
                          if (p.disponible) Row(
                            children: [
                              Text('Cantidad:', style: AppTextStyles.titleMedium),
                              const SizedBox(width: AppDimensions.paddingM),
                              _buildQuantityDropdown(p.stock),
                            ],
                          ),

                          const SizedBox(height: AppDimensions.paddingM),
                          const Divider(color: AppColors.divider),
                          const SizedBox(height: AppDimensions.paddingM),

                          // Medios de pago
                          Text('Medios de pago', style: AppTextStyles.titleMedium),
                          const SizedBox(height: 10),
                          _buildPaymentLogos(),

                          const SizedBox(height: AppDimensions.paddingXL),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomActions(p),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery(BuildContext context, List<String> images) {
    return Stack(
      children: [
        Container(
          height: 300,
          color: AppColors.surfaceVariant,
          child: images.isEmpty
              ? const Center(child: Icon(Icons.image_outlined, size: 80, color: AppColors.textHint))
              : PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _currentImageIndex = i),
                  itemBuilder: (_, i) => CachedNetworkImage(
                    imageUrl: images[i],
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                    errorWidget: (_, __, ___) => const Center(child: Icon(Icons.image_outlined, size: 80, color: AppColors.textHint)),
                  ),
                ),
        ),

        // Botón atrás
        Positioned(
          top: AppDimensions.paddingM, left: AppDimensions.paddingM,
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8)]),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
            ),
          ),
        ),

        // Favorito
        Positioned(
          top: AppDimensions.paddingM, right: AppDimensions.paddingM,
          child: GestureDetector(
            onTap: _togglingFav ? null : _toggleFavorite,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8)]),
              child: _togglingFav
                  ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : Icon(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _isFavorite ? AppColors.error : AppColors.textSecondary, size: 20),
            ),
          ),
        ),

        // Dots
        if (images.length > 1)
          Positioned(
            bottom: AppDimensions.paddingS, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentImageIndex == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentImageIndex == i ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              )),
            ),
          ),
      ],
    );
  }

  Widget _buildQuantityDropdown(int stock) {
    final max = stock > 10 ? 10 : stock;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusS), border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedQuantity,
          style: AppTextStyles.bodyMedium,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          items: List.generate(max, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1} unidad${i > 0 ? 'es' : ''}'))),
          onChanged: (v) => setState(() => _selectedQuantity = v ?? 1),
        ),
      ),
    );
  }

  Widget _buildPaymentLogos() {
    final logos  = ['VISA', 'MC', 'AMEX', 'JCB'];
    final colors = [const Color(0xFF1A1F71), const Color(0xFFEB001B), const Color(0xFF2E77BC), const Color(0xFF003087)];
    return Row(
      children: List.generate(logos.length, (i) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusS), border: Border.all(color: AppColors.border)),
        child: Text(logos[i], style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 11, fontWeight: FontWeight.w800, color: colors[i])),
      )),
    );
  }

  Widget _buildBottomActions(Producto p) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(color: AppColors.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))]),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: p.disponible ? () {
                Navigator.of(context).pushNamed('/delivery-address', arguments: {'productos': [ProductoCheckout(id: p.idproducto, nombre: p.nombre, precio: p.precio, cantidad: _selectedQuantity)]});
              } : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
              child: const Text('Comprar Ahora'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: (p.disponible && !_addingToCart) ? _addToCart : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: AppColors.textPrimary),
              child: _addingToCart
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.textPrimary, strokeWidth: 2))
                  : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_cart_outlined, size: 18), SizedBox(width: 6), Text('Al carrito')]),
            ),
          ),
        ],
      ),
    );
  }
}
