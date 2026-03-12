// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/delivery_address_screen.dart';
import 'screens/payment_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const DulceHogarApp());
}

class DulceHogarApp extends StatelessWidget {
  const DulceHogarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dulce Hogar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login, // ← flujo real: empieza en login
      routes: AppRoutes.routes,
    );
  }
}

class AppRoutes {
  AppRoutes._();

  static const String login           = '/login';
  static const String register        = '/register';
  static const String home            = '/';
  static const String cart            = '/cart';
  static const String productDetail   = '/product-detail';
  static const String favorites       = '/favorites';
  static const String deliveryAddress = '/delivery-address';
  static const String payment         = '/payment';

  static final Map<String, WidgetBuilder> routes = {
    login:           (_) => const LoginScreen(),
    register:        (_) => const RegisterScreen(),
    home:            (_) => const HomeScreen(),
    cart:            (_) => const CartScreen(),
    productDetail:   (_) => const ProductDetailScreen(),
    favorites:       (_) => const FavoritesScreen(),
    deliveryAddress: (_) => const DeliveryAddressScreen(),
    payment:         (_) => const PaymentScreen(),
  };
}
