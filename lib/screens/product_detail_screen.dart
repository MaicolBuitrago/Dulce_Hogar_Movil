import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../services/favorites_service.dart';
import '../utils/formatters.dart';
import '../widgets/app_widgets.dart';
import '../services/review_service.dart';
import '../services/auth_service.dart';
import '../services/service_result.dart';

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

  // ── Estado de reseñas ─────────────────────────────────────
  ResumenResenas _resumen      = ResumenResenas.vacio();
  bool           _loadingRes   = true;
  String?        _miCedula;   // cédula del usuario logueado

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
      _cargarResenas(p.idproducto);
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

  Future<void> _cargarResenas(int idproducto) async {
    setState(() => _loadingRes = true);
    
    final resResult = await ReviewService.getResenas(idproducto);
    final perfilResult = await AuthService.getPerfil();
    
    if (!mounted) return;
    
    setState(() {
      _loadingRes = false;
      if (resResult.ok) {
        _resumen = resResult.data ?? ResumenResenas.vacio();
      }
      if (perfilResult.ok && perfilResult.data != null) {
        _miCedula = perfilResult.data!.cedula;
      }
    });
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final p = _producto;
    
    if (p == null) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(child: Text('Producto no encontrado',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))),
      );
    }

    final images = p.imagenes.isNotEmpty ? p.imagenes : <String>[];

    return Scaffold(
      backgroundColor: colorScheme.background,
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
              _buildGallery(context, images),
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
                          _buildNameAndBadge(context, p),
                          const SizedBox(height: 14),
                          _buildPriceRow(context, p),
                          const SizedBox(height: 20),
                          if (p.descripcion != null) ...[
                            _buildDescriptionCard(context, p.descripcion!),
                            const SizedBox(height: 16),
                          ],
                          _buildStockAndQuantity(context, p),
                          const SizedBox(height: 16),
                          _buildPaymentCard(context),
                          const SizedBox(height: 16),
                          _ReviewSection(
                            resumen:    _resumen,
                            loading:    _loadingRes,
                            idproducto: p.idproducto,
                            miCedula:   _miCedula,
                            onResenaCambiada: () => _cargarResenas(p.idproducto),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomActions(context, p),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery(BuildContext context, List<String> images) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      height: 310,
      child: Stack(
        children: [
          Container(
            height: 310,
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: images.isEmpty
                ? Center(child: Icon(Icons.image_outlined, size: 72, color: colorScheme.onSurfaceVariant))
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
                          Center(child: Icon(Icons.image_outlined, size: 72, color: colorScheme.onSurfaceVariant)),
                    ),
                  ),
          ),
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
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: colorScheme.onSurface, size: 16),
              ),
            ),
          ),
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
                      : colorScheme.surface.withOpacity(0.92),
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
                        color: _isFavorite ? AppColors.error : colorScheme.onSurfaceVariant,
                        size: 19,
                      ),
              ),
            ),
          ),
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

  Widget _buildNameAndBadge(BuildContext context, Producto p) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          style: textTheme.displayLarge?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(BuildContext context, Producto p) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: p.disponible 
              ? [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)]
              : [colorScheme.surfaceVariant, colorScheme.surfaceVariant],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.disponible ? AppColors.primaryBorder : colorScheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Precio', style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w600,
                  color: p.disponible ? AppColors.primaryDark : colorScheme.onSurfaceVariant,
                )),
                const SizedBox(height: 2),
                Text(
                  Formatters.precio(p.precio),
                  style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 28, fontWeight: FontWeight.w800,
                    color: p.disponible ? AppColors.priceColor : colorScheme.onSurfaceVariant,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          if (p.disponible)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
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
                  Text('uds.', style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 10, color: colorScheme.onSurfaceVariant,
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context, String desc) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
              Text('Descripción', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: TextStyle(
              fontFamily: 'Nunito', fontSize: 14, color: colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockAndQuantity(BuildContext context, Producto p) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
              Text('Cantidad a comprar', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              )),
            ],
          ),
          if (p.disponible) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _buildQtyButton(context,
                  icon: Icons.remove_rounded,
                  onTap: _selectedQuantity > 1
                      ? () => setState(() => _selectedQuantity--)
                      : null,
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$_selectedQuantity',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildQtyButton(context,
                  icon: Icons.add_rounded,
                  onTap: _selectedQuantity < (p.stock > 10 ? 10 : p.stock)
                      ? () => setState(() => _selectedQuantity++)
                      : null,
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Subtotal', style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 11, color: colorScheme.onSurfaceVariant,
                    )),
                    Text(
                      Formatters.precio(p.precio * _selectedQuantity),
                      style: TextStyle(
                        fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text('Este producto no está disponible por el momento.',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.error)),
          ],
        ],
      ),
    );
  }

  Widget _buildQtyButton(BuildContext context, {required IconData icon, VoidCallback? onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primaryPale : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: onTap != null ? AppColors.primaryBorder : colorScheme.outline,
          ),
        ),
        child: Icon(icon, size: 18,
            color: onTap != null ? AppColors.primaryDark : colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
              Text('Medios de pago', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
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
  }

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

  Widget _buildBottomActions(BuildContext context, Producto p) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
}

// ══════════════════════════════════════════════════════════════
// SECCIÓN DE RESEÑAS — se agrega al final del detalle
// ══════════════════════════════════════════════════════════════
class _ReviewSection extends StatefulWidget {
  final ResumenResenas resumen;
  final bool           loading;
  final int            idproducto;
  final String?        miCedula;
  final VoidCallback   onResenaCambiada;

  const _ReviewSection({
    required this.resumen,
    required this.loading,
    required this.idproducto,
    required this.miCedula,
    required this.onResenaCambiada,
  });

  @override
  State<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<_ReviewSection> {
  bool _mostrarFormulario = false;

  // ── Helpers ──────────────────────────────────────────────────
  bool get _yaReseno => widget.miCedula != null &&
      widget.resumen.resenas.any((r) => r.cedula == widget.miCedula);

  Future<void> _eliminar(Resena r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL)),
        title: const Text('Eliminar reseña'),
        content: const Text('¿Seguro que quieres eliminar tu reseña?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await ReviewService.eliminar(r.idcomentario);
    if (!mounted) return;
    if (res.ok) {
      widget.onResenaCambiada();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Reseña eliminada'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado con promedio ─────────────────────────
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.star_rounded,
                    size: 16, color: AppColors.accent),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text('Reseñas',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant)),
              ),
              if (!widget.loading && widget.resumen.total > 0) ...[
                _StarDisplay(valor: widget.resumen.promedio, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${widget.resumen.promedio} (${widget.resumen.total})',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface),
                ),
              ],
            ],
          ),

          // ── Loading ─────────────────────────────────────────
          if (widget.loading) ...[
            const SizedBox(height: 20),
            const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2)),
            const SizedBox(height: 20),
          ]

          // ── Sin reseñas ──────────────────────────────────────
          else if (widget.resumen.total == 0 && !_mostrarFormulario) ...[
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(Icons.rate_review_outlined,
                      size: 40,
                      color: colorScheme.onSurfaceVariant
                          .withOpacity(0.4)),
                  const SizedBox(height: 8),
                  Text('Sin reseñas todavía',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('Sé el primero en opinar',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant
                              .withOpacity(0.6))),
                ],
              ),
            ),
          ]

          // ── Lista de reseñas ──────────────────────────────────
          else if (!_mostrarFormulario) ...[
            const SizedBox(height: 12),
            ...widget.resumen.resenas
                .take(3) // mostrar máx 3 — evita scroll infinito
                .map((r) => _ResenaCard(
                      resena:  r,
                      esMia:   r.cedula == widget.miCedula,
                      onEliminar: () => _eliminar(r),
                    )),
            if (widget.resumen.total > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Y ${widget.resumen.total - 3} reseña(s) más...',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant),
                ),
              ),
          ],

          // ── Formulario nueva reseña ───────────────────────────
          if (_mostrarFormulario)
            _NuevaResenaForm(
              idproducto: widget.idproducto,
              onPublicada: () {
                setState(() => _mostrarFormulario = false);
                widget.onResenaCambiada();
              },
              onCancelar: () => setState(() => _mostrarFormulario = false),
            ),

          // ── Botón dejar reseña ────────────────────────────────
          if (!widget.loading && !_mostrarFormulario) ...[
            const SizedBox(height: 14),
            if (widget.miCedula == null)
              Text('Inicia sesión para dejar una reseña',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant))
            else if (_yaReseno)
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 15, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text('Ya dejaste tu reseña',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant)),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _mostrarFormulario = true),
                  icon: const Icon(Icons.rate_review_outlined, size: 16),
                  label: const Text('Escribir una reseña'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusM)),
                    textStyle: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Card de una reseña individual ────────────────────────────
class _ResenaCard extends StatelessWidget {
  final Resena       resena;
  final bool         esMia;
  final VoidCallback onEliminar;

  const _ResenaCard({
    required this.resena,
    required this.esMia,
    required this.onEliminar,
  });

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar inicial
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    resena.autor.isNotEmpty
                        ? resena.autor[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(resena.autor,
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface)),
                        if (esMia) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPale,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Tú',
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(_formatFecha(resena.fecha),
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              _StarDisplay(valor: resena.calificacion.toDouble(), size: 13),
              if (esMia) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onEliminar,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline_rounded,
                        size: 17,
                        color: colorScheme.onSurfaceVariant
                            .withOpacity(0.5)),
                  ),
                ),
              ],
            ],
          ),
          if (resena.comentario.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(resena.comentario,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    height: 1.5,
                    color: colorScheme.onSurface)),
          ],
        ],
      ),
    );
  }
}

// ── Formulario para nueva reseña ─────────────────────────────
class _NuevaResenaForm extends StatefulWidget {
  final int          idproducto;
  final VoidCallback onPublicada;
  final VoidCallback onCancelar;

  const _NuevaResenaForm({
    required this.idproducto,
    required this.onPublicada,
    required this.onCancelar,
  });

  @override
  State<_NuevaResenaForm> createState() => _NuevaResenaFormState();
}

class _NuevaResenaFormState extends State<_NuevaResenaForm> {
  int    _stars     = 0;
  bool   _enviando  = false;
  final  _ctrl      = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona una calificación'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _enviando = true);
    final r = await ReviewService.crear(
      idproducto:   widget.idproducto,
      calificacion: _stars,
      comentario:   _ctrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _enviando = false);
    if (r.ok) {
      widget.onPublicada();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('¡Reseña publicada! Gracias por tu opinión'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.error ?? 'No se pudo publicar'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
        Text('Tu calificación',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface)),
        const SizedBox(height: 10),

        // Estrellas interactivas
        Row(
          children: List.generate(5, (i) {
            final llena = i < _stars;
            return GestureDetector(
              onTap: () => setState(() => _stars = i + 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  llena ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 34,
                  color: llena ? AppColors.accent : colorScheme.onSurfaceVariant.withOpacity(0.3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),

        // Campo de comentario
        TextField(
          controller: _ctrl,
          maxLines:   4,
          maxLength:  500,
          decoration: InputDecoration(
            hintText:    'Cuéntanos tu experiencia con este producto (opcional)',
            hintStyle:   TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 13),
        ),
        const SizedBox(height: 12),

        // Botones
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: OutlinedButton(
                  onPressed: _enviando ? null : widget.onCancelar,
                  child: const Text('Cancelar'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _publicar,
                  child: _enviando
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Publicar reseña'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Widget de estrellas de solo lectura ───────────────────────
class _StarDisplay extends StatelessWidget {
  final double valor; // 0.0 - 5.0
  final double size;

  const _StarDisplay({required this.valor, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final llena   = i < valor.floor();
        final parcial = !llena && i < valor;
        return Icon(
          llena
              ? Icons.star_rounded
              : parcial
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          size:  size,
          color: AppColors.accent,
        );
      }),
    );
  }
}