import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../models/models.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import '../services/favorites_service.dart';
import '../utils/formatters.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex      = 0;
  int _selectedCatIndex      = 0;
  int? _selectedCatId;

  List<Categoria> _categorias  = [];
  List<Producto>  _productos   = [];
  bool _loadingCats            = true;
  bool _loadingProds           = true;
  String _searchQuery          = '';

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategorias();
    _loadProductos();
    _syncCartCount();
    _syncFavorites();
  }

  Future<void> _syncCartCount() async {
    await CartService.getCarrito();
  }

  Future<void> _syncFavorites() async {
    await FavoritesService.getFavoritos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    final r = await ProductService.getCategorias();
    if (!mounted) return;
    setState(() {
      _categorias = r.data ?? [];
      _loadingCats = false;
    });
  }

  Future<void> _loadProductos({String? search, int? idCat}) async {
    setState(() => _loadingProds = true);
    final r = idCat != null
        ? await ProductService.getProductosByCategoria(idCat)
        : await ProductService.getProductos(search: search);
    if (!mounted) return;
    setState(() {
      _productos   = r.data ?? [];
      _loadingProds = false;
    });
  }

  void _onCategoryTap(int index, int? idCat) {
    setState(() {
      _selectedCatIndex = index;
      _selectedCatId    = idCat;
    });
    _loadProductos(idCat: idCat);
  }

  void _onSearch(String q) {
    _searchQuery = q;
    _loadProductos(search: q.isEmpty ? null : q);
  }

  void _goToProductDetail(Producto p) {
    Navigator.of(context).pushNamed('/product-detail', arguments: p);
  }

  void _goToNav(int i) {
    setState(() => _selectedNavIndex = i);
    switch (i) {
      case 1: Navigator.of(context).pushNamed('/favorites'); break;
      case 2: Navigator.of(context).pushNamed('/cart'); break;
      case 3: Navigator.of(context).pushNamed('/perfil'); break;
    }
  }

  Future<void> _addToCart(Producto p) async {
    final r = await CartService.agregar(idproducto: p.idproducto, cantidad: 1);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(r.ok ? '${p.nombre} agregado al carrito' : (r.error ?? 'Error')),
      backgroundColor: r.ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _toggleFavorite(Producto p) async {
    final wasFav = FavoritesService.favoriteIds.value.contains(p.idproducto);

    // Optimistic update — cambia el set ANTES de llamar la API
    // Usamos agregar/eliminar directamente para no depender del toggle
    // que lee favoriteIds internamente (ya modificado)
    final updatedIds = Set<int>.from(FavoritesService.favoriteIds.value);
    if (wasFav) {
      updatedIds.remove(p.idproducto);
    } else {
      updatedIds.add(p.idproducto);
    }
    FavoritesService.favoriteIds.value = updatedIds;

    // Llamar agregar o eliminar directamente (no toggle) para evitar
    // que lea el set ya modificado y tome la decisión al revés
    final r = wasFav
        ? await FavoritesService.eliminar(p.idproducto)
        : await FavoritesService.agregar(p.idproducto);
    if (!mounted) return;

    if (!r.ok) {
      // Revertir si falló
      final revertIds = Set<int>.from(FavoritesService.favoriteIds.value);
      if (wasFav) {
        revertIds.add(p.idproducto);
      } else {
        revertIds.remove(p.idproducto);
      }
      FavoritesService.favoriteIds.value = revertIds;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(r.ok
          ? (wasFav ? 'Quitado de favoritos' : 'Guardado en favoritos \u2764\ufe0f')
          : (r.error ?? 'No se pudo actualizar favoritos')),
      backgroundColor: r.ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadProductos(idCat: _selectedCatId, search: _searchQuery.isEmpty ? null : _searchQuery),
                color: AppColors.primary,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildCategoryBar()),
                    SliverToBoxAdapter(child: _buildPromoBanner()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppDimensions.paddingM, AppDimensions.paddingM, AppDimensions.paddingM, 0),
                      sliver: SliverToBoxAdapter(
                        child: SectionHeader(
                          title: _selectedCatIndex == 0 ? 'Todos los productos' : (_categorias.isNotEmpty ? _categorias[_selectedCatIndex - 1].descripcion : ''),
                          actionLabel: _selectedCatIndex != 0 ? 'Ver todos' : '',
                          onAction: _selectedCatIndex != 0 ? () {
                            _onCategoryTap(0, null);
                          } : () {},
                        ),
                      ),
                    ),
                    if (_loadingProds)
                      const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator(color: AppColors.primary))))
                    else if (_productos.isEmpty)
                      SliverToBoxAdapter(child: _buildEmptyState())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(AppDimensions.paddingM),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final p = _productos[i];
                              return ValueListenableBuilder<Set<int>>(
                                valueListenable: FavoritesService.favoriteIds,
                                builder: (context, favIds, _) => ProductCard(
                                  name: p.nombre,
                                  price: p.precio,
                                  imageUrl: p.imagenPrincipal ?? '',
                                  isFavorite: favIds.contains(p.idproducto),
                                  stock: p.stock,
                                  onTap: () => _goToProductDetail(p),
                                  onAddToCart: () => _addToCart(p),
                                  onFavorite: () => _toggleFavorite(p),
                                ),
                              );
                            },
                            childCount: _productos.length,
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
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: CartService.cartCount,
        builder: (context, count, _) => AppBottomNav(
          currentIndex: _selectedNavIndex,
          cartCount: count,
          onTap: _goToNav,
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM, vertical: AppDimensions.paddingS),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
            child: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 22),
          ),
          const SizedBox(width: AppDimensions.paddingS),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: AppTextStyles.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textHint),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingS),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/cart'),
            child: ValueListenableBuilder<int>(
              valueListenable: CartService.cartCount,
              builder: (context, count, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
                    child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 22),
                  ),
                  if (count > 0)
                    Positioned(
                      right: -4, top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    final labels = ['Todos', ..._categorias.map((c) => c.descripcion)];
    if (_loadingCats) {
      return const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)));
    }
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
          separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.paddingS),
          itemCount: labels.length,
          itemBuilder: (ctx, i) => CategoryChip(
            label: labels[i],
            isSelected: _selectedCatIndex == i,
            onTap: () => _onCategoryTap(i, i == 0 ? null : _categorias[i - 1].idcategoria),
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      height: 140,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Stack(
        children: [
          Positioned(right: -20, top: -20, child: Container(width: 140, height: 140, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)))),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_offer_rounded, color: Colors.white, size: 11),
                      SizedBox(width: 4),
                      Text('Oferta especial', style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Hasta 30% OFF\nen electrodomésticos', style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2)),
                const SizedBox(height: 8),
                const Row(children: [
                  Text('Ver ofertas', style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondaryLight)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: AppColors.secondaryLight, size: 16),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 60, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text('No se encontraron productos', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () { _searchController.clear(); _loadProductos(); }, child: const Text('Ver todos')),
          ],
        ),
      ),
    );
  }
}