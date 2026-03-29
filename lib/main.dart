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
import 'screens/payment_success_screen.dart';
import 'screens/recuperar_contrasena_screen.dart';
import 'screens/nueva_contrasena_screen.dart';
import 'screens/perfil_screen.dart';

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

class DulceHogarApp extends StatefulWidget {
  const DulceHogarApp({super.key});

  @override
  State<DulceHogarApp> createState() => _DulceHogarAppState();
}

class _DulceHogarAppState extends State<DulceHogarApp>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) setState(() {});
      WidgetsBinding.instance.scheduleFrame();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullUrl = Uri.base.toString();
    final isPaymentSuccess = fullUrl.contains('checkout') ||
        fullUrl.contains('exitoso') ||
        fullUrl.contains('payment_id') ||
        fullUrl.contains('collection_id');

    final uri = Uri.parse(fullUrl);
    final pathSegments = uri.pathSegments;
    final isResetPassword = pathSegments.isNotEmpty &&
        pathSegments.first == 'reset-password' &&
        pathSegments.length >= 2;

    return MaterialApp(
      title: 'Dulce Hogar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: isResetPassword
          ? '${AppRoutes.resetPassword}/${pathSegments[1]}'
          : isPaymentSuccess
              ? AppRoutes.paymentSuccess
              : AppRoutes.login,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

class AppRoutes {
  AppRoutes._();

  static const String login               = '/login';
  static const String register            = '/register';
  static const String home                = '/';
  static const String cart                = '/cart';
  static const String productDetail       = '/product-detail';
  static const String favorites           = '/favorites';
  static const String deliveryAddress     = '/delivery-address';
  static const String payment             = '/payment';
  static const String paymentSuccess      = '/checkout/forma-entrega/pago/exitoso';
  static const String recuperarContrasena = '/recuperar-contrasena';
  static const String resetPassword       = '/reset-password';
  static const String perfil              = '/perfil';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '';
    final uri = Uri.tryParse(name);

    if (name.startsWith('/checkout')) {
      final paymentId = uri?.queryParameters['payment_id'] ??
          uri?.queryParameters['collection_id'];
      return MaterialPageRoute(
        settings: RouteSettings(
          name: name,
          arguments: paymentId != null
              ? {'payment_id': paymentId}
              : settings.arguments,
        ),
        builder: (_) => const PaymentSuccessScreen(),
      );
    }

    // Deep link: /reset-password/<jwt-token>
    if (name.startsWith('/reset-password/')) {
      final token = name.replaceFirst('/reset-password/', '');
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => NuevaContrasenaScreen(token: token),
      );
    }

    final builders = <String, WidgetBuilder>{
      login:               (_) => const LoginScreen(),
      register:            (_) => const RegisterScreen(),
      home:                (_) => const HomeScreen(),
      cart:                (_) => const CartScreen(),
      productDetail:       (_) => const ProductDetailScreen(),
      favorites:           (_) => const FavoritesScreen(),
      deliveryAddress:     (_) => const DeliveryAddressScreen(),
      payment:             (_) => const PaymentScreen(),
      paymentSuccess:      (_) => const PaymentSuccessScreen(),
      recuperarContrasena: (_) => const RecuperarContrasenaScreen(),
      perfil:              (_) => const PerfilScreen(),
    };

    final builder = builders[name];
    if (builder != null) {
      return MaterialPageRoute(settings: settings, builder: builder);
    }

    return null;
  }
}