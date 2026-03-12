// lib/models/product_model.dart

class ProductModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final String? badge;
  final bool isNew;
  final bool isFavorite;

  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.badge,
    this.isNew = false,
    this.isFavorite = false,
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  int get discountPercent {
    if (!hasDiscount) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }
}

class CartItemModel {
  final ProductModel product;
  int quantity;

  CartItemModel({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;
}

// Datos de muestra / mock data
class MockData {
  static const List<String> categories = [
    'Todo',
    'Neveras',
    'Televisores',
    'Lavadoras',
    'Camas',
    'Celulares',
  ];

  static final List<ProductModel> products = [
    ProductModel(
      id: '1',
      name: 'Lavadora Samsung',
      category: 'Lavadoras',
      price: 2000000,
      originalPrice: 2500000,
      imageUrl: 'https://picsum.photos/seed/lavadora/300/300',
      badge: 'Oferta',
      isNew: false,
    ),
    ProductModel(
      id: '2',
      name: 'Smart TV 55"',
      category: 'Televisores',
      price: 2000000,
      imageUrl: 'https://picsum.photos/seed/tv55/300/300',
      isNew: true,
    ),
    ProductModel(
      id: '3',
      name: 'Nevera 200 L',
      category: 'Neveras',
      price: 2000000,
      originalPrice: 2300000,
      imageUrl: 'https://picsum.photos/seed/nevera200/300/300',
    ),
    ProductModel(
      id: '4',
      name: 'Sofacama',
      category: 'Camas',
      price: 2000000,
      imageUrl: 'https://picsum.photos/seed/sofacama/300/300',
      isNew: true,
    ),
    ProductModel(
      id: '5',
      name: 'Estufa 4 Puestos',
      category: 'Todo',
      price: 1500000,
      imageUrl: 'https://picsum.photos/seed/estufa4/300/300',
    ),
    ProductModel(
      id: '6',
      name: 'Microondas Digital',
      category: 'Todo',
      price: 800000,
      originalPrice: 950000,
      imageUrl: 'https://picsum.photos/seed/microondas/300/300',
      badge: 'Hot',
    ),
  ];

  static final List<CartItemModel> cartItems = [
    CartItemModel(product: products[0], quantity: 1),
    CartItemModel(product: products[1], quantity: 2),
    CartItemModel(product: products[2], quantity: 1),
  ];
}
