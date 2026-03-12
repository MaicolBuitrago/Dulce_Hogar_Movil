// lib/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/favorites_service.dart';
import '../utils/formatters.dart';

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
    setState(() { _favorites = r.data ?? []; _loading = false; });
  }

  Future<void> _remove(int idproducto) async {
    final r = await FavoritesService.eliminar(idproducto);
    if (!mounted) return;
    if (r.ok) setState(() => _favorites.removeWhere((f) => f.idproducto == idproducto));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
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
                        padding: const EdgeInsets.all(AppDimensions.paddingM),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _FavoriteCard(
                              fav: _favorites[i],
                              onRemove: () => _remove(_favorites[i].idproducto),
                              onTap: () {},
                            ),
                            childCount: _favorites.length,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.paddingM)),
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
    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM, vertical: AppDimensions.paddingM),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppDimensions.radiusM)), child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
        ),
        const SizedBox(width: AppDimensions.paddingM),
        const Icon(Icons.favorite_rounded, color: AppColors.error, size: 26),
        const SizedBox(width: 8),
        Expanded(child: Text('Mis Favoritos${_favorites.isNotEmpty ? ' (${_favorites.length})' : ''}', style: AppTextStyles.headlineLarge)),
      ],
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.favorite_border_rounded, size: 48, color: AppColors.error)),
        const SizedBox(height: AppDimensions.paddingL),
        const Text('Sin favoritos aún', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 8),
        const Text('Guarda productos que te gusten', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppDimensions.paddingL),
        SizedBox(width: 200, child: ElevatedButton(onPressed: () => Navigator.of(context).pushReplacementNamed('/'), child: const Text('Explorar productos'))),
      ],
    ),
  );
}

class _FavoriteCard extends StatefulWidget {
  final Favorito fav;
  final VoidCallback onRemove;
  final VoidCallback onTap;
  const _FavoriteCard({required this.fav, required this.onRemove, required this.onTap});
  @override
  State<_FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends State<_FavoriteCard> {
  bool _showOverlay = false;

  @override
  Widget build(BuildContext context) {
    final img = widget.fav.imagen;
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () => setState(() => _showOverlay = !_showOverlay),
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusM), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusM)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: img != null
                        ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppColors.surfaceVariant, child: const Icon(Icons.image_outlined, color: AppColors.textHint, size: 40)))
                        : Container(color: AppColors.surfaceVariant, child: const Icon(Icons.image_outlined, color: AppColors.textHint, size: 40)),
                  ),
                ),
                AnimatedOpacity(
                  opacity: _showOverlay ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusM)),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        color: Colors.black.withOpacity(0.55),
                        child: Center(
                          child: GestureDetector(
                            onTap: widget.onRemove,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline_rounded, color: Colors.white, size: 30),
                                SizedBox(height: 4),
                                Text('Eliminar', style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: widget.onRemove,
                    child: Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.surface.withOpacity(0.9), shape: BoxShape.circle), child: const Icon(Icons.favorite_rounded, size: 15, color: AppColors.error)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.fav.nombre, style: AppTextStyles.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(Formatters.precio(widget.fav.precio), style: AppTextStyles.priceStyle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
