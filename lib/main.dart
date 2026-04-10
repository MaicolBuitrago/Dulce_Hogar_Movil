// lib/main.dart
//
// Cambios:
//  • Llama a AuthService.checkSesionActiva() antes de arrancar
//  • Si hay sesión activa → va directo al home (sin pasar por login)
//  • Pasa navigatorKey a MaterialApp para que ApiClient pueda redirigir
//    al login cuando el refresh token expira (sin contexto)
//  • LoginScreen recibe argumento opcional 'mensaje' para mostrar snackbar
//    de "sesión expirada"

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
import 'services/api_client.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:        Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Verificar sesión guardada ────────────────────────────────────────────
  // Si hay token válido o refresh exitoso → irá al home
  // Si no → irá al login normalmente
  final sesionActiva = await AuthService.checkSesionActiva();

  runApp(DulceHogarApp(sesionActiva: sesionActiva));
}

class DulceHogarApp extends StatefulWidget {
  final bool sesionActiva;
  const DulceHogarApp({super.key, required this.sesionActiva});

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
        fullUrl.contains('exitoso')     ||
        fullUrl.contains('payment_id')  ||
        fullUrl.contains('collection_id');

    final uri          = Uri.parse(fullUrl);
    final pathSegments = uri.pathSegments;
    final isResetPassword = pathSegments.isNotEmpty &&
        pathSegments.first == 'reset-password' &&
        pathSegments.length >= 2;

    // Ruta inicial: si hay sesión activa, home; si no, login
    final String initialRoute = isResetPassword
        ? '${AppRoutes.resetPassword}/${pathSegments[1]}'
        : isPaymentSuccess
            ? AppRoutes.paymentSuccess
            : widget.sesionActiva
                ? AppRoutes.home
                : AppRoutes.login;

    return MaterialApp(
      title:                  'Dulce Hogar',
      debugShowCheckedModeBanner: false,
      theme:                  AppTheme.lightTheme,
      // navigatorKey permite a ApiClient redirigir al login sin contexto
      navigatorKey:           ApiClient.navigatorKey,
      initialRoute:           initialRoute,
      onGenerateRoute:        AppRoutes.onGenerateRoute,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
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
    final uri  = Uri.tryParse(name);

    if (name.startsWith('/checkout')) {
      final paymentId = uri?.queryParameters['payment_id'] ??
          uri?.queryParameters['collection_id'];
      return MaterialPageRoute(
        settings: RouteSettings(
          name:      name,
          arguments: paymentId != null
              ? {'payment_id': paymentId}
              : settings.arguments,
        ),
        builder: (_) => const PaymentSuccessScreen(),
      );
    }

    if (name.startsWith('/reset-password/')) {
      final token = name.replaceFirst('/reset-password/', '');
      return MaterialPageRoute(
        settings: settings,
        builder:  (_) => NuevaContrasenaScreen(token: token),
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