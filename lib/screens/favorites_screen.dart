// lib/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/favorites_service.dart';
import '../services/cart_service.dart';
import '../utils/formatters.dart';
import '../widgets/app_widgets.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Favorito> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await FavoritesService.getFavoritos();
    if (!mounted) return;
    setState(() {
      _favorites = r.data ?? [];
      _loading = false;
    });
  }

  Future<void> _remove(int idproducto, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL)),
        title: const Row(
          children: [
            Icon(Icons.favorite_rounded, color: AppColors.error, size: 22),
            SizedBox(width: 8),
            Text('Quitar de favoritos'),
          ],
        ),
        content: Text('¿Seguro que quieres quitar "$nombre" de tus favoritos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, quitar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final r = await FavoritesService.eliminar(idproducto);
    if (!mounted) return;
    if (r.ok) {
      setState(() => _favorites.removeWhere((f) => f.idproducto == idproducto));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Producto quitado de favoritos'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.error ?? 'No se pudo quitar el favorito'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _addToCart(Favorito fav) async {
    final r = await CartService.agregar(idproducto: fav.idproducto, cantidad: 1);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(r.ok
          ? '${fav.nombre} agregado al carrito 🛒'
          : (r.error ?? 'No se pudo agregar al carrito')),
      backgroundColor: r.ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const SharedBottomNav(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (_loading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            else if (_favorites.isEmpty)
              Expanded(child: _buildEmptyState())
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                            AppDimensions.paddingM, AppDimensions.paddingM,
                            AppDimensions.paddingM, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _FavoriteCard(
                              fav: _favorites[i],
                              onRemove: () => _remove(
                                  _favorites[i].idproducto, _favorites[i].nombre),
                              onAddToCart: () => _addToCart(_favorites[i]),
                              onTap: () {},
                            ),
                            childCount: _favorites.length,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                          child: SizedBox(height: AppDimensions.paddingL)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM, vertical: AppDimensions.paddingM),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimary, size: 20)),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            const Icon(Icons.favorite_rounded, color: AppColors.error, size: 26),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    'Mis Favoritos${_favorites.isNotEmpty ? ' (${_favorites.length})' : ''}',
                    style: AppTextStyles.headlineLarge)),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    shape: BoxShape.circle),
                child: const Icon(Icons.favorite_border_rounded,
                    size: 48, color: AppColors.error)),
            const SizedBox(height: AppDimensions.paddingL),
            const Text('Sin favoritos aún', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            const Text('Guarda productos que te gusten', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppDimensions.paddingL),
            SizedBox(
                width: 200,
                child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                    child: const Text('Explorar productos'))),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// Card horizontal: imagen | info + badge stock + botones
// ─────────────────────────────────────────────────────────────
class _FavoriteCard extends StatefulWidget {
  final Favorito fav;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;

  const _FavoriteCard({
    required this.fav,
    required this.onRemove,
    required this.onAddToCart,
    required this.onTap,
  });

  @override
  State<_FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends State<_FavoriteCard> {
  bool _addingToCart = false;

  Future<void> _handleAddToCart() async {
    setState(() => _addingToCart = true);
    widget.onAddToCart();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _addingToCart = false);
  }

  @override
  Widget build(BuildContext context) {
    final fav = widget.fav;
    final img = fav.imagen;
    final hasStock = fav.stock > 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagen ──────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppDimensions.radiusL)),
              child: SizedBox(
                width: 110,
                height: 130,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    img != null
                        ? CachedNetworkImage(
                            imageUrl: img,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                                color: AppColors.surfaceVariant,
                                child: const Icon(Icons.image_outlined,
                                    color: AppColors.textHint, size: 36)),
                          )
                        : Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.image_outlined,
                                color: AppColors.textHint, size: 36)),
                    // Overlay sin stock sobre la imagen
                    if (!hasStock)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          color: Colors.black.withOpacity(0.55),
                          child: const Text(
                            'Sin stock',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Info + botones ───────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Text(
                      fav.nombre,
                      style: AppTextStyles.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // Badge disponibilidad
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: hasStock
                            ? AppColors.success.withOpacity(0.12)
                            : AppColors.error.withOpacity(0.10),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      child: Text(
                        hasStock ? 'Disponible' : 'Sin stock',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: hasStock
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Precio
                    Text(Formatters.precio(fav.precio),
                        style: AppTextStyles.priceStyle),

                    const SizedBox(height: 12),

                    // Botones
                    Row(
                      children: [
                        // Agregar al carrito
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: ElevatedButton.icon(
                              onPressed: hasStock && !_addingToCart
                                  ? _handleAddToCart
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusM),
                                ),
                              ),
                              icon: _addingToCart
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 15),
                              label: Text(
                                hasStock ? 'Agregar' : 'Sin stock',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Quitar de favoritos
                        SizedBox(
                          height: 36,
                          width: 36,
                          child: IconButton.outlined(
                            padding: EdgeInsets.zero,
                            onPressed: widget.onRemove,
                            style: IconButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.error, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusM),
                              ),
                            ),
                            icon: const Icon(Icons.favorite_rounded,
                                color: AppColors.error, size: 17),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}