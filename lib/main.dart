import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import 'services/theme_service.dart';
import 'services/auth_service.dart';
import 'screens/orders_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/support_screen.dart';
import 'screens/support_chat_screen.dart';

// Variable global para saber la ruta después del onboarding
String _nextRouteAfterOnboarding = '/login';

// ═══════════════════════════════════════════════════════════════════════════
// CONFIGURACIÓN DE SUPABASE - CAMBIA ESTOS VALORES POR LOS TUYOS
// ═══════════════════════════════════════════════════════════════════════════
const String _supabaseUrl = 'https://dxmuoslfugzyrjozvnsn.supabase.co';    
const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR4bXVvc2xmdWd6eXJqb3p2bnNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NjYxNjIsImV4cCI6MjA3ODU0MjE2Mn0.jCaMMw6JRzV9ju2XpSwnNQI3loGSlvbCZFC-pc-sQEw';                    

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Inicializar Supabase primero
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

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

  await ThemeService.init();

  final sesionActiva = await AuthService.checkSesionActiva();
  final onboardingVisto = await onboardingFueVisto();

  _nextRouteAfterOnboarding = sesionActiva ? '/' : '/login';

  runApp(DulceHogarApp(
    sesionActiva: sesionActiva,
    onboardingVisto: onboardingVisto,
  ));
}

class DulceHogarApp extends StatefulWidget {
  final bool sesionActiva;
  final bool onboardingVisto;
  const DulceHogarApp({super.key, required this.sesionActiva, required this.onboardingVisto});

  @override
  State<DulceHogarApp> createState() => _DulceHogarAppState();
}

class _DulceHogarAppState extends State<DulceHogarApp> with WidgetsBindingObserver {
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

    final String initialRoute = isResetPassword
        ? '${AppRoutes.resetPassword}/${pathSegments[1]}'
        : isPaymentSuccess
            ? AppRoutes.paymentSuccess
            : !widget.onboardingVisto
                ? AppRoutes.onboarding
                : widget.sesionActiva
                    ? AppRoutes.home
                    : AppRoutes.login;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeMode,
      builder: (context, themeMode, _) => MaterialApp(
        title: 'Dulce Hogar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        navigatorKey: ApiClient.navigatorKey,
        initialRoute: initialRoute,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String cart = '/cart';
  static const String productDetail = '/product-detail';
  static const String favorites = '/favorites';
  static const String deliveryAddress = '/delivery-address';
  static const String payment = '/payment';
  static const String paymentSuccess = '/checkout/forma-entrega/pago/exitoso';
  static const String recuperarContrasena = '/recuperar-contrasena';
  static const String resetPassword = '/reset-password';
  static const String perfil = '/perfil';
  static const String misPedidos = '/mis-pedidos';
  static const String onboarding = '/onboarding';
  static const String soporte = '/soporte';

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

    if (name.startsWith('/reset-password/')) {
      final token = name.replaceFirst('/reset-password/', '');
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => NuevaContrasenaScreen(token: token),
      );
    }

    final builders = <String, WidgetBuilder>{
      login: (_) => const LoginScreen(),
      register: (_) => const RegisterScreen(),
      home: (_) => const HomeScreen(),
      cart: (_) => const CartScreen(),
      productDetail: (_) => const ProductDetailScreen(),
      favorites: (_) => const FavoritesScreen(),
      deliveryAddress: (_) => const DeliveryAddressScreen(),
      payment: (_) => const PaymentScreen(),
      paymentSuccess: (_) => const PaymentSuccessScreen(),
      recuperarContrasena: (_) => const RecuperarContrasenaScreen(),
      perfil: (_) => const PerfilScreen(),
      misPedidos: (_) => const OrdersScreen(),
      '/soporte': (_) => const SupportScreen(),
      onboarding: (_) => OnboardingScreen(nextRoute: _nextRouteAfterOnboarding),
    };

    final builder = builders[name];
    if (builder != null) {
      return MaterialPageRoute(settings: settings, builder: builder);
    }

    return null;
  }
}