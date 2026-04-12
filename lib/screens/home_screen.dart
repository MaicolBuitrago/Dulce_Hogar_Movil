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
  int _selectedNavIndex = 0;
  int _selectedCatIndex = 0;
  int? _selectedCatId;

  List<Categoria> _categorias = [];
  List<Producto>  _productos  = [];
  List<Marca>     _marcas     = [];
  bool _loadingCats  = true;
  bool _loadingProds = true;

  FiltrosProducto _filtros = const FiltrosProducto();

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategorias();
    _loadMarcas();
    _loadProductos();
    _syncCartCount();
    _syncFavorites();
  }

  Future<void> _syncCartCount() async => CartService.getCarrito();
  Future<void> _syncFavorites() async => FavoritesService.getFavoritos();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    final r = await ProductService.getCategorias();
    if (!mounted) return;
    setState(() {
      _categorias  = r.data ?? [];
      _loadingCats = false;
    });
  }

  Future<void> _loadMarcas() async {
    final r = await ProductService.getMarcas();
    if (!mounted) return;
    setState(() => _marcas = r.data ?? []);
  }

  Future<void> _loadProductos() async {
    setState(() => _loadingProds = true);

    try {
      final result = await ProductService.getProductos(filtros: _filtros);
      
      if (!mounted) return;
      setState(() {
        _productos    = result.data ?? [];
        _loadingProds = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _productos    = [];
        _loadingProds = false;
      });
      print('❌ Error cargando productos: $e');
    }
  }

  void _onCategoryTap(int index, int? idCat) {
    setState(() {
      _selectedCatIndex = index;
      _selectedCatId    = idCat;
    });
    _loadProductos();
  }

  void _onSearch(String q) {
    setState(() {
      _filtros = FiltrosProducto(
        search: q.isEmpty ? null : q,
        precioMin: _filtros.precioMin,
        precioMax: _filtros.precioMax,
        idMarca: _filtros.idMarca,
        idCategoria: _filtros.idCategoria,
        orden: _filtros.orden,
      );
    });
    _loadProductos();
  }

  Future<void> _abrirFiltros() async {
    final nuevos = await showModalBottomSheet<FiltrosProducto>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        filtrosActuales: _filtros,
        marcas:          _marcas,
      ),
    );
    if (nuevos != null && mounted) {
      setState(() {
        _filtros = FiltrosProducto(
          search: _filtros.search,
          precioMin: nuevos.precioMin,
          precioMax: nuevos.precioMax,
          idMarca: nuevos.idMarca,
          idCategoria: _filtros.idCategoria,
          orden: nuevos.orden,
        );
      });
      _loadProductos();
    }
  }

  void _goToProductDetail(Producto p) =>
      Navigator.of(context).pushNamed('/product-detail', arguments: p);

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
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(r.ok ? '${p.nombre} agregado al carrito' : (r.error ?? 'Error')),
      backgroundColor: r.ok ? colorScheme.primary : colorScheme.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _toggleFavorite(Producto p) async {
    final wasFav = FavoritesService.favoriteIds.value.contains(p.idproducto);
    final updated = Set<int>.from(FavoritesService.favoriteIds.value);
    wasFav ? updated.remove(p.idproducto) : updated.add(p.idproducto);
    FavoritesService.favoriteIds.value = updated;

    final r = wasFav
        ? await FavoritesService.eliminar(p.idproducto)
        : await FavoritesService.agregar(p.idproducto);
    if (!mounted) return;

    if (!r.ok) {
      final reverted = Set<int>.from(FavoritesService.favoriteIds.value);
      wasFav ? reverted.add(p.idproducto) : reverted.remove(p.idproducto);
      FavoritesService.favoriteIds.value = reverted;
    }

    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(r.ok
          ? (wasFav ? 'Quitado de favoritos' : 'Guardado en favoritos ❤️')
          : (r.error ?? 'No se pudo actualizar favoritos')),
      backgroundColor: r.ok ? colorScheme.primary : colorScheme.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  void _limpiarFiltros() {
    setState(() {
      _filtros = const FiltrosProducto();
    });
    _loadProductos();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadProductos,
                color: colorScheme.primary,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildCategoryBar(context)),
                    SliverToBoxAdapter(child: _buildPromoBanner(context)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppDimensions.paddingM, AppDimensions.paddingM,
                          AppDimensions.paddingM, 0),
                      sliver: SliverToBoxAdapter(
                        child: _buildSectionHeader(context),
                      ),
                    ),
                    if (_loadingProds)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
                        ),
                      )
                    else if (_productos.isEmpty)
                      SliverToBoxAdapter(child: _buildEmptyState(context))
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
                                  name:        p.nombre,
                                  price:       p.precio,
                                  imageUrl:    p.imagenPrincipal ?? '',
                                  isFavorite:  favIds.contains(p.idproducto),
                                  stock:       p.stock,
                                  onTap:       () => _goToProductDetail(p),
                                  onAddToCart: () => _addToCart(p),
                                  onFavorite:  () => _toggleFavorite(p),
                                ),
                              );
                            },
                            childCount: _productos.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(
                        child: SizedBox(height: AppDimensions.paddingM)),
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
          cartCount:    count,
          onTap:        _goToNav,
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;
    final filtrosActivos = _filtros.cantidadActivos;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM, vertical: AppDimensions.paddingS),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged:  _onSearch,
              style:      textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText:   'Buscar productos...',
                prefixIcon: Icon(Icons.search_rounded,
                    color: colorScheme.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingS),

          GestureDetector(
            onTap: _abrirFiltros,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: filtrosActivos > 0
                        ? colorScheme.primary
                        : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: filtrosActivos > 0
                        ? Colors.white
                        : colorScheme.onSurface,
                    size: 22,
                  ),
                ),
                if (filtrosActivos > 0)
                  Positioned(
                    right: -4, top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                          color: colorScheme.error, shape: BoxShape.circle),
                      child: Text(
                        '$filtrosActivos',
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),
              ],
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
                    decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusS)),
                    child: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.white, size: 22),
                  ),
                  if (count > 0)
                    Positioned(
                      right: -4, top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            color: colorScheme.error, shape: BoxShape.circle),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
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

  Widget _buildCategoryBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labels = ['Todos', ..._categorias.map((c) => c.descripcion)];
    if (_loadingCats) {
      return SizedBox(
          height: 52,
          child: Center(
              child: CircularProgressIndicator(
                  color: colorScheme.primary, strokeWidth: 2)));
    }
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM),
          separatorBuilder: (_, __) =>
              const SizedBox(width: AppDimensions.paddingS),
          itemCount: labels.length,
          itemBuilder: (ctx, i) => CategoryChip(
            label:      labels[i],
            isSelected: _selectedCatIndex == i,
            onTap: () => _onCategoryTap(
                i, i == 0 ? null : _categorias[i - 1].idcategoria),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final titulo = _selectedCatIndex == 0
        ? 'Todos los productos'
        : (_categorias.isNotEmpty
            ? _categorias[_selectedCatIndex - 1].descripcion
            : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$titulo (${_productos.length})',
                style: textTheme.headlineMedium,
              ),
            ),
            if (_filtros.cantidadActivos > 0)
              GestureDetector(
                onTap: _limpiarFiltros,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.10),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close_rounded,
                          size: 13, color: colorScheme.error),
                      const SizedBox(width: 4),
                      Text('Limpiar filtros',
                          style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.error)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (_filtros.cantidadActivos > 0) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (_filtros.precioMin != null || _filtros.precioMax != null)
                  _ActiveFilterChip(
                    label: _filtros.precioMin != null && _filtros.precioMax != null
                        ? '${Formatters.precio(_filtros.precioMin!)} – ${Formatters.precio(_filtros.precioMax!)}'
                        : _filtros.precioMin != null
                            ? 'Desde ${Formatters.precio(_filtros.precioMin!)}'
                            : 'Hasta ${Formatters.precio(_filtros.precioMax!)}',
                    onRemove: () {
                      setState(() {
                        _filtros = FiltrosProducto(
                          search: _filtros.search,
                          precioMin: null,
                          precioMax: null,
                          idMarca: _filtros.idMarca,
                          idCategoria: _filtros.idCategoria,
                          orden: _filtros.orden,
                        );
                      });
                      _loadProductos();
                    },
                  ),
                if (_filtros.idMarca != null) ...[
                  const SizedBox(width: 6),
                  _ActiveFilterChip(
                    label: _marcas
                            .where((m) => m.idmarca == _filtros.idMarca)
                            .firstOrNull
                            ?.descripcion ??
                        'Marca',
                    onRemove: () {
                      setState(() {
                        _filtros = FiltrosProducto(
                          search: _filtros.search,
                          precioMin: _filtros.precioMin,
                          precioMax: _filtros.precioMax,
                          idMarca: null,
                          idCategoria: _filtros.idCategoria,
                          orden: _filtros.orden,
                        );
                      });
                      _loadProductos();
                    },
                  ),
                ],
                if (_filtros.orden != OrdenProducto.recientes) ...[
                  const SizedBox(width: 6),
                  _ActiveFilterChip(
                    label: _filtros.orden.label,
                    onRemove: () {
                      setState(() {
                        _filtros = FiltrosProducto(
                          search: _filtros.search,
                          precioMin: _filtros.precioMin,
                          precioMax: _filtros.precioMax,
                          idMarca: _filtros.idMarca,
                          idCategoria: _filtros.idCategoria,
                          orden: OrdenProducto.recientes,
                        );
                      });
                      _loadProductos();
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
              right: -20,
              top: -20,
              child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.07)))),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_offer_rounded,
                          color: Colors.white, size: 11),
                      SizedBox(width: 4),
                      Text('Oferta especial',
                          style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Hasta 30% OFF\nen electrodomésticos',
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2)),
                const SizedBox(height: 8),
                const Row(children: [
                  Text('Ver ofertas',
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      color: Colors.white70, size: 16),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 60, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              _filtros.cantidadActivos > 0
                  ? 'Sin resultados con estos filtros'
                  : 'No se encontraron productos',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _limpiarFiltros,
              child: const Text('Ver todos'),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Chip pequeño que muestra un filtro activo con botón de cierre
// ──────────────────────────────────────────────────────────────
class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveFilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border:
            Border.all(color: colorScheme.primary.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded,
                size: 14, color: colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Bottom sheet de filtros
// ──────────────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final FiltrosProducto filtrosActuales;
  final List<Marca>     marcas;

  const _FilterSheet({
    required this.filtrosActuales,
    required this.marcas,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late OrdenProducto _orden;
  late RangeValues    _rango;
  int? _idMarca;

  static const double _maxPrecio = 5000000;

  @override
  void initState() {
    super.initState();
    _orden   = widget.filtrosActuales.orden;
    _idMarca = widget.filtrosActuales.idMarca;
    _rango   = RangeValues(
      widget.filtrosActuales.precioMin ?? 0,
      widget.filtrosActuales.precioMax ?? _maxPrecio,
    );
  }

  bool get _rangoPorDefecto =>
      _rango.start == 0 && _rango.end == _maxPrecio;

  void _aplicar() {
    Navigator.of(context).pop(FiltrosProducto(
      precioMin: _rangoPorDefecto ? null : _rango.start,
      precioMax: _rangoPorDefecto ? null : _rango.end,
      idMarca:   _idMarca,
      orden:     _orden,
    ));
  }

  void _limpiar() {
    setState(() {
      _orden   = OrdenProducto.recientes;
      _idMarca = null;
      _rango   = const RangeValues(0, _maxPrecio);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cantActivos = FiltrosProducto(
            precioMin: _rangoPorDefecto ? null : _rango.start,
            precioMax: _rangoPorDefecto ? null : _rango.end,
            idMarca:   _idMarca,
            orden:     _orden)
        .cantidadActivos;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXL)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.paddingL,
        AppDimensions.paddingM,
        AppDimensions.paddingL,
        AppDimensions.paddingL +
            MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),

          Row(
            children: [
              Icon(Icons.tune_rounded,
                  color: colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Filtros',
                    style: textTheme.headlineMedium),
              ),
              if (cantActivos > 0)
                TextButton(
                  onPressed: _limpiar,
                  child: Text('Limpiar todo',
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: colorScheme.error,
                          fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),

          Text('Ordenar por', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: OrdenProducto.values.map((o) {
              final sel = _orden == o;
              return GestureDetector(
                onTap: () => setState(() => _orden = o),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel
                        ? colorScheme.primary
                        : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull),
                    border: sel
                        ? null
                        : Border.all(
                            color: colorScheme.onSurfaceVariant
                                .withOpacity(0.2)),
                  ),
                  child: Text(o.label,
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel
                              ? Colors.white
                              : colorScheme.onSurface)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.paddingM),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rango de precio',
                  style: textTheme.titleMedium),
              Text(
                _rangoPorDefecto
                    ? 'Cualquier precio'
                    : '${Formatters.precio(_rango.start)} – ${Formatters.precio(_rango.end)}',
                style: textTheme.bodySmall?.copyWith(
                    color: _rangoPorDefecto
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.primary,
                    fontWeight: _rangoPorDefecto
                        ? FontWeight.w400
                        : FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor:
                  colorScheme.primary.withOpacity(0.15),
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withOpacity(0.12),
              rangeThumbShape:
                  const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: RangeSlider(
              values: _rango,
              min:    0,
              max:    _maxPrecio,
              divisions: 100,
              onChanged: (v) => setState(() => _rango = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$0',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              Text('\$5.000.000',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),

          if (widget.marcas.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.paddingM),

            Text('Marca', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _idMarca = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _idMarca == null
                          ? colorScheme.primary
                          : colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull),
                    ),
                    child: Text('Todas',
                        style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _idMarca == null
                                ? Colors.white
                                : colorScheme.onSurface)),
                  ),
                ),
                ...widget.marcas.map((m) {
                  final sel = _idMarca == m.idmarca;
                  return GestureDetector(
                    onTap: () => setState(() => _idMarca = m.idmarca),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel
                            ? colorScheme.primary
                            : colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull),
                        border: sel
                            ? null
                            : Border.all(
                                color: colorScheme.onSurfaceVariant
                                    .withOpacity(0.2)),
                      ),
                      child: Text(m.descripcion,
                          style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : colorScheme.onSurface)),
                    ),
                  );
                }),
              ],
            ),
          ],

          const SizedBox(height: AppDimensions.paddingL),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _aplicar,
              child: Text(
                cantActivos > 0
                    ? 'Aplicar filtros ($cantActivos)'
                    : 'Aplicar',
              ),
            ),
          ),
        ],
      ),
    );
  }
}