// lib/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../services/favorites_service.dart';
import '../utils/formatters.dart';
import '../widgets/app_widgets.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  int  _currentImageIndex = 0;
  int  _selectedQuantity  = 1;
  bool _isFavorite        = false;
  bool _addingToCart      = false;
  bool _togglingFav       = false;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  final _pageController = PageController();
  Producto? _producto;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = ModalRoute.of(context)?.settings.arguments as Producto?;
    if (p != null && p.idproducto != _producto?.idproducto) {
      _producto = p;
      _checkFavorito();
      _animCtrl.forward(from: 0);
    }
  }

  Future<void> _checkFavorito() async {
    if (_producto == null) return;
    final r = await FavoritesService.getFavoritos();
    if (!mounted) return;
    if (r.ok && r.data != null) {
      setState(() {
        _isFavorite = r.data!.any((f) => f.idproducto == _producto!.idproducto);
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    if (_producto == null) return;
    setState(() => _addingToCart = true);
    final r = await CartService.agregar(
        idproducto: _producto!.idproducto, cantidad: _selectedQuantity);
    if (!mounted) return;
    setState(() => _addingToCart = false);
    _showSnack(r.ok ? '¡Agregado al carrito!' : (r.error ?? 'Error'), isError: !r.ok);
  }

  Future<void> _toggleFavorite() async {
    if (_producto == null) return;
    setState(() => _togglingFav = true);
    final agregando = !_isFavorite;
    final r = agregando
        ? await FavoritesService.agregar(_producto!.idproducto)
        : await FavoritesService.eliminar(_producto!.idproducto);
    if (!mounted) return;
    setState(() {
      _togglingFav = false;
      if (r.ok) _isFavorite = agregando;
    });
    _showSnack(
      r.ok ? (agregando ? 'Guardado en favoritos' : 'Eliminado de favoritos') : (r.error ?? 'Error'),
      isError: !r.ok,
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: Colors.white, size: 17),
        const SizedBox(width: 9),
        Expanded(child: Text(msg, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13))),
      ]),
      backgroundColor: isError ? AppColors.error : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = _producto;
    if (p == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: Text('Producto no encontrado',
            style: TextStyle(fontFamily: 'Nunito', color: AppColors.textSecondary))),
      );
    }

    final images = p.imagenes.isNotEmpty ? p.imagenes : <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: const SharedBottomNav(),
      body: Stack(
        children: [
          // Mancha decorativa fondo
          Positioned(
            bottom: 120, right: -80,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.05),
              ),
            ),
          ),

          Column(
            children: [
              // ── Galería (sin SafeArea para que vaya al borde) ──
              _buildGallery(context, images),

              // ── Contenido scrollable ──
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildNameAndBadge(p),
                          const SizedBox(height: 14),
                          _buildPriceRow(p),
                          const SizedBox(height: 20),
                          if (p.descripcion != null) ...[
                            _buildDescriptionCard(p.descripcion!),
                            const SizedBox(height: 16),
                          ],
                          _buildStockAndQuantity(p),
                          const SizedBox(height: 16),
                          _buildPaymentCard(),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Barra de acciones fija abajo ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomActions(p),
          ),
        ],
      ),
    );
  }

  // ─── Galería ──────────────────────────────────────────────────────────────
  Widget _buildGallery(BuildContext context, List<String> images) {
    return SizedBox(
      height: 310,
      child: Stack(
        children: [
          // Imagen / PageView
          Container(
            height: 310,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: images.isEmpty
                ? const Center(child: Icon(Icons.image_outlined, size: 72, color: AppColors.textHint))
                : PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: images[i],
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                      errorWidget: (_, __, ___) =>
                          const Center(child: Icon(Icons.image_outlined, size: 72, color: AppColors.textHint)),
                    ),
                  ),
          ),

          // Gradiente superior para botones
          Positioned(
            top: 0, left: 0, right: 0, height: 90,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.18), Colors.transparent],
                ),
              ),
            ),
          ),

          // Botón atrás
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 16),
              ),
            ),
          ),

          // Botón favorito
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: GestureDetector(
              onTap: _togglingFav ? null : _toggleFavorite,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _isFavorite
                      ? AppColors.error.withOpacity(0.12)
                      : Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                  border: Border.all(
                    color: _isFavorite ? AppColors.error.withOpacity(0.3) : Colors.transparent,
                  ),
                ),
                child: _togglingFav
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : Icon(
                        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isFavorite ? AppColors.error : AppColors.textSecondary,
                        size: 19,
                      ),
              ),
            ),
          ),

          // Dots indicadores
          if (images.length > 1)
            Positioned(
              bottom: 14, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentImageIndex == i ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == i ? AppColors.primary : Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(100),
                  ),
                )),
              ),
            ),

          // Contador de imágenes (esquina)
          if (images.length > 1)
            Positioned(
              bottom: 14, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${images.length}',
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 11,
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Nombre y badge ───────────────────────────────────────────────────────
  Widget _buildNameAndBadge(Producto p) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Badge disponibilidad
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: p.disponible ? AppColors.primaryPale : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: p.disponible ? AppColors.primaryBorder : AppColors.error.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.disponible ? AppColors.primary : AppColors.error,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              p.disponible ? 'En stock' : 'Sin stock',
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700,
                color: p.disponible ? AppColors.primaryDark : AppColors.error,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Text(
        p.nombre,
        style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 26, fontWeight: FontWeight.w800,
          color: AppColors.textPrimary, height: 1.15, letterSpacing: -0.5,
        ),
      ),
    ],
  );

  // ─── Precio ───────────────────────────────────────────────────────────────
  Widget _buildPriceRow(Producto p) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.primaryBorder),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Precio', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              )),
              const SizedBox(height: 2),
              Text(
                Formatters.precio(p.precio),
                style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 28, fontWeight: FontWeight.w800,
                  color: AppColors.priceColor, letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        // Stock badge
        if (p.disponible)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.primary),
                const SizedBox(height: 2),
                Text('${p.stock}', style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                )),
                const Text('uds.', style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 10, color: AppColors.textSecondary,
                )),
              ],
            ),
          ),
      ],
    ),
  );

  // ─── Descripción ─────────────────────────────────────────────────────────
  Widget _buildDescriptionCard(String desc) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description_outlined, size: 14, color: AppColors.secondary),
            ),
            const SizedBox(width: 9),
            const Text('Descripción', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          desc,
          style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 14, color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    ),
  );

  // ─── Stock + Cantidad ─────────────────────────────────────────────────────
  Widget _buildStockAndQuantity(Producto p) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 9),
            const Text('Cantidad a comprar', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            )),
          ],
        ),
        if (p.disponible) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              // Botón –
              _buildQtyButton(
                icon: Icons.remove_rounded,
                onTap: _selectedQuantity > 1
                    ? () => setState(() => _selectedQuantity--)
                    : null,
              ),
              const SizedBox(width: 16),
              // Número
              SizedBox(
                width: 36,
                child: Text(
                  '$_selectedQuantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Botón +
              _buildQtyButton(
                icon: Icons.add_rounded,
                onTap: _selectedQuantity < (p.stock > 10 ? 10 : p.stock)
                    ? () => setState(() => _selectedQuantity++)
                    : null,
              ),
              const Spacer(),
              // Subtotal
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Subtotal', style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 11, color: AppColors.textHint,
                  )),
                  Text(
                    Formatters.precio(p.precio * _selectedQuantity),
                    style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800,
                      color: AppColors.priceColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 10),
          const Text('Este producto no está disponible por el momento.',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.error)),
        ],
      ],
    ),
  );

  Widget _buildQtyButton({required IconData icon, VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: onTap != null ? AppColors.primaryPale : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: onTap != null ? AppColors.primaryBorder : AppColors.border,
            ),
          ),
          child: Icon(icon, size: 18,
              color: onTap != null ? AppColors.primaryDark : AppColors.textHint),
        ),
      );

  // ─── Medios de pago ───────────────────────────────────────────────────────
  Widget _buildPaymentCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.payment_rounded, size: 14, color: AppColors.accent),
            ),
            const SizedBox(width: 9),
            const Text('Medios de pago', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            )),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildPaymentChip('VISA', const Color(0xFF1A1F71)),
            const SizedBox(width: 8),
            _buildPaymentChip('MC', const Color(0xFFEB001B)),
            const SizedBox(width: 8),
            _buildPaymentChip('AMEX', const Color(0xFF2E77BC)),
            const SizedBox(width: 8),
            _buildPaymentChip('JCB', const Color(0xFF003087)),
          ],
        ),
      ],
    ),
  );

  Widget _buildPaymentChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Text(label, style: TextStyle(
      fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w800, color: color,
    )),
  );

  // ─── Acciones inferiores ──────────────────────────────────────────────────
  Widget _buildBottomActions(Producto p) => Container(
    padding: EdgeInsets.fromLTRB(
        20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, -4)),
      ],
    ),
    child: Row(
      children: [
        // Comprar ahora
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: p.disponible ? () {
              Navigator.of(context).pushNamed('/delivery-address', arguments: {
                'productos': [ProductoCheckout(
                  id: p.idproducto, nombre: p.nombre,
                  precio: p.precio, cantidad: _selectedQuantity,
                )]
              });
            } : null,
            child: AnimatedOpacity(
              opacity: p.disponible ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: p.disponible ? [
                    BoxShadow(color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12, offset: const Offset(0, 4)),
                  ] : [],
                ),
                child: const Center(
                  child: Text('Comprar ahora', style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Agregar al carrito
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: (p.disponible && !_addingToCart) ? _addToCart : null,
            child: AnimatedOpacity(
              opacity: p.disponible ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                ),
                child: Center(
                  child: _addingToCart
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary))
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 17, color: AppColors.secondary),
                            SizedBox(width: 6),
                            Text('Carrito', style: TextStyle(
                              fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            )),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}