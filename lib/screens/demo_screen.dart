// lib/screens/demo_screen.dart
// SOLO PARA DESARROLLO — eliminar en producción
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.paddingL),

              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'DH',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dulce Hogar', style: AppTextStyles.headlineLarge),
                      Text(
                        'Vista previa de pantallas',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.paddingL),

              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(color: AppColors.secondary),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.secondaryDark, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pantalla solo para desarrollo. Eliminar antes de producción.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.secondaryDark),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.paddingL),

              const Text('Pantallas', style: AppTextStyles.headlineMedium),
              const SizedBox(height: AppDimensions.paddingM),

              Expanded(
                child: ListView(
                  children: [
                    _DemoCard(
                      icon: Icons.home_rounded,
                      title: 'Home',
                      subtitle: 'Búsqueda · Categorías · Productos',
                      route: '/',
                    ),
                    const SizedBox(height: 12),
                    _DemoCard(
                      icon: Icons.login_rounded,
                      title: 'Inicio de sesión',
                      subtitle: 'Email · Contraseña · Google',
                      route: '/login',
                    ),
                    const SizedBox(height: 12),
                    _DemoCard(
                      icon: Icons.person_add_rounded,
                      title: 'Registro',
                      subtitle: 'Formulario · Google · Términos',
                      route: '/register',
                    ),
                    const SizedBox(height: 12),
                    _DemoCard(
                      icon: Icons.shopping_cart_rounded,
                      title: 'Carrito',
                      subtitle: 'Items · Cantidades · Checkout',
                      route: '/cart',
                    ),
                    const SizedBox(height: 12),
                    _DemoCard(
                      icon: Icons.inventory_2_rounded,
                      title: 'Detalle de producto',
                      subtitle: 'Galería · Precio · Medios de pago',
                      route: '/product-detail',
                    ),
                    const SizedBox(height: 12),
                    _DemoCard(
                      icon: Icons.favorite_rounded,
                      title: 'Mis favoritos',
                      subtitle: 'Grid · Overlay · Eliminar',
                      route: '/favorites',
                    ),
                    const SizedBox(height: 12),
                    _DemoCard(
                      icon: Icons.local_shipping_rounded,
                      title: 'Dirección de entrega',
                      subtitle: 'Domicilios · Mapa · GPS',
                      route: '/delivery-address',
                    ),
                    const SizedBox(height: 12),
                    _DemoCard(
                      icon: Icons.payment_rounded,
                      title: 'Método de pago',
                      subtitle: 'Stripe · Nequi · Bancolombia',
                      route: '/payment',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _DemoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(route),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textHint,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
