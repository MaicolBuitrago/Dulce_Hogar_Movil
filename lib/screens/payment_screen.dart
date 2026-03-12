// lib/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/stripe_service.dart';
import '../utils/formatters.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int? _selectedMethod;
  bool _loading = false;

  List<ProductoCheckout> _productos   = [];
  String                 _source      = 'carrito';
  int?                   _iddireccion;

  double get _total => _productos.fold(0, (s, p) => s + p.precio * p.cantidad);

  final List<_PaymentMethod> _methods = [
    _PaymentMethod(id: 0, title: 'Pagar con tarjeta (Stripe)', icon: Icons.credit_card_rounded, color: const Color(0xFF6772E5), available: true),
    _PaymentMethod(id: 1, title: 'Pagar con Nequi', subtitle: 'Próximamente', icon: Icons.phone_android_rounded, color: const Color(0xFF6B0F8C), available: false),
    _PaymentMethod(id: 2, title: 'Transferencia Bancolombia', subtitle: 'Próximamente', icon: Icons.account_balance_rounded, color: const Color(0xFFF5A623), available: false),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _productos   = (args['productos'] as List<ProductoCheckout>?) ?? [];
      _source      = args['source'] as String? ?? 'carrito';
      _iddireccion = args['iddireccion'] as int?;
    }
  }

  Future<void> _pagar() async {
    if (_selectedMethod != 0) return; // Solo Stripe activo
    setState(() => _loading = true);

    final r = await StripeService.crearSesion(
      productos:   _productos,
      source:      _source,
      iddireccion: _iddireccion,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    r.when(
      onOk: (url) async {
        if (url != null) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            _showSnack('No se pudo abrir el navegador');
          }
        }
      },
      onError: (e) => _showSnack(e),
    );
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  children: [
                    const SizedBox(height: AppDimensions.paddingM),

                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.payment_rounded, color: AppColors.primary, size: 36),
                    ),

                    const SizedBox(height: AppDimensions.paddingM),
                    const Text('Método de pago', style: AppTextStyles.displayMedium),
                    const SizedBox(height: 6),
                    Text('Selecciona cómo quieres pagar tu pedido', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),

                    const SizedBox(height: AppDimensions.paddingL),
                    _buildOrderSummary(),
                    const SizedBox(height: AppDimensions.paddingL),

                    ..._methods.map((m) {
                      final isSelected = _selectedMethod == m.id;
                      return GestureDetector(
                        onTap: m.available ? () => setState(() => _selectedMethod = m.id) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM, vertical: AppDimensions.paddingM),
                          decoration: BoxDecoration(
                            color: m.available ? (isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.surface) : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(color: m.available ? m.color.withOpacity(0.12) : AppColors.border.withOpacity(0.5), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
                                child: Icon(m.icon, color: m.available ? m.color : AppColors.textHint, size: 22),
                              ),
                              const SizedBox(width: AppDimensions.paddingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.title, style: AppTextStyles.titleMedium.copyWith(color: m.available ? AppColors.textPrimary : AppColors.textHint)),
                                    if (m.subtitle != null) Text(m.subtitle!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                                  ],
                                ),
                              ),
                              Icon(m.available ? Icons.arrow_forward_rounded : Icons.lock_outline_rounded, color: m.available ? AppColors.primary : AppColors.textHint, size: 20),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: AppDimensions.paddingL),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, color: AppColors.textHint, size: 14),
                        const SizedBox(width: 4),
                        Text('Pago 100% seguro y encriptado', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                      ],
                    ),

                    if (_selectedMethod != null) ...[
                      const SizedBox(height: AppDimensions.paddingL),
                      ElevatedButton(
                        onPressed: _loading ? null : _pagar,
                        child: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lock_rounded, size: 18), SizedBox(width: 8), Text('Proceder al pago')]),
                      ),
                    ],

                    const SizedBox(height: AppDimensions.paddingXXL),
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
    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM, vertical: AppDimensions.paddingS),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppDimensions.radiusM)), child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
        ),
        const SizedBox(width: AppDimensions.paddingM),
        const Text('Pago', style: AppTextStyles.headlineLarge),
      ],
    ),
  );

  Widget _buildOrderSummary() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppDimensions.paddingM),
    decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppDimensions.radiusM), border: Border.all(color: AppColors.border)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resumen del pedido', style: AppTextStyles.headlineMedium),
        const SizedBox(height: AppDimensions.paddingS),
        ..._productos.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('${p.nombre} (x${p.cantidad})', style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis)),
              Text(Formatters.precio(p.precio * p.cantidad), style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        )),
        const Divider(height: AppDimensions.paddingM, color: AppColors.divider),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total a pagar:', style: AppTextStyles.titleMedium),
            Text(Formatters.precio(_total), style: AppTextStyles.priceLarge),
          ],
        ),
      ],
    ),
  );
}

class _PaymentMethod {
  final int id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool available;
  const _PaymentMethod({required this.id, required this.title, this.subtitle, required this.icon, required this.color, required this.available});
}
