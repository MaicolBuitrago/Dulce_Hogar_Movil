// lib/screens/payment_success_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/mercadopago_service.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  _Estado _estado = _Estado.cargando;
  String _mensaje = '';

  @override
  void initState() {
    super.initState();
    _confirmarPedido();
  }

  Future<void> _confirmarPedido() async {
    String? paymentId;

    // 1. Leer desde Uri.base (funciona en Flutter Web con hash routing)
    // La URL real del navegador es: http://localhost:5173/#/pago/exitoso?payment_id=xxx
    // pero Uri.base captura todo incluyendo el fragment
    final fullUrl = Uri.base.toString();
    final uri = Uri.parse(fullUrl);

    // Intentar desde query params directos
    paymentId = uri.queryParameters['payment_id'] ??
                uri.queryParameters['collection_id'];

    // Si no, buscar en el fragment (#/ruta?payment_id=xxx)
    if (paymentId == null && uri.fragment.isNotEmpty) {
      final fragmentUri = Uri.tryParse('http://x/${uri.fragment}');
      paymentId = fragmentUri?.queryParameters['payment_id'] ??
                  fragmentUri?.queryParameters['collection_id'];
    }

    // 2. Leer desde arguments de navegación
    if (paymentId == null && mounted) {
      await Future.delayed(Duration.zero); // esperar frame
      if (mounted) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map) {
          paymentId = args['payment_id']?.toString() ??
                      args['collection_id']?.toString();
        } else if (args is String) {
          paymentId = args;
        }
      }
    }

    debugPrint('💳 payment_id capturado: $paymentId');
    debugPrint('🌐 URL completa: $fullUrl');

    if (paymentId == null || paymentId.isEmpty) {
      setState(() {
        _estado = _Estado.error;
        _mensaje = 'No se recibió el ID del pago. URL: $fullUrl';
      });
      return;
    }

    final result = await MercadoPagoService.confirmarPedido(paymentId);

    if (!mounted) return;

    result.when(
      onOk: (_) => setState(() => _estado = _Estado.exito),
      onError: (e) => setState(() {
        _estado = _Estado.error;
        _mensaje = e;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: switch (_estado) {
              _Estado.cargando => _buildCargando(context),
              _Estado.exito   => _buildExito(context),
              _Estado.error   => _buildError(context),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCargando(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: AppDimensions.paddingM),
        Text('Registrando tu pedido...', style: textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildExito(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: Color(0xFF4CAF50), size: 48),
        ),
        const SizedBox(height: AppDimensions.paddingL),
        Text('¡Pago exitoso!', style: textTheme.displayMedium),
        const SizedBox(height: AppDimensions.paddingS),
        Text(
          'Tu pedido fue registrado correctamente.',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.paddingXL),
        ElevatedButton(
          onPressed: () =>
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false),
          child: const Text('Volver al inicio'),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 48),
        ),
        const SizedBox(height: AppDimensions.paddingL),
        Text('Algo salió mal', style: textTheme.displayMedium),
        const SizedBox(height: AppDimensions.paddingS),
        Text(
          _mensaje.isNotEmpty
              ? _mensaje
              : 'No pudimos registrar tu pedido. Tu pago sí fue procesado.',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.paddingXL),
        ElevatedButton(
          onPressed: () =>
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false),
          child: const Text('Volver al inicio'),
        ),
      ],
    );
  }
}

enum _Estado { cargando, exito, error }