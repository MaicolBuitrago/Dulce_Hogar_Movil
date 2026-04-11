import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

const _kOnboardingVisto = 'dulce_hogar_onboarding_visto';

// Llamado en main() para saber si mostrar onboarding
Future<bool> onboardingFueVisto() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingVisto) ?? false;
}

// Marcar como visto
Future<void> marcarOnboardingVisto() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingVisto, true);
}

// ══════════════════════════════════════════════════════════════
// Datos de cada slide
// ══════════════════════════════════════════════════════════════
class _Slide {
  final IconData icono;
  final Color    colorFondo;
  final Color    colorIcono;
  final String   titulo;
  final String   subtitulo;

  const _Slide({
    required this.icono,
    required this.colorFondo,
    required this.colorIcono,
    required this.titulo,
    required this.subtitulo,
  });
}

// ══════════════════════════════════════════════════════════════
// Pantalla
// ══════════════════════════════════════════════════════════════
class OnboardingScreen extends StatefulWidget {
  // La ruta a la que navegar al terminar (login o home)
  final String nextRoute;

  const OnboardingScreen({super.key, required this.nextRoute});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _paginaActual = 0;

  // Slides con colores dinámicos según el tema
  List<_Slide> get _slides {
    final colorScheme = Theme.of(context).colorScheme;
    return [
      _Slide(
        icono:       Icons.storefront_rounded,
        colorFondo:  colorScheme.primary.withOpacity(0.12),
        colorIcono:  colorScheme.primary,
        titulo:      'Bienvenido a Dulce Hogar',
        subtitulo:   'Encuentra electrodomésticos y artículos para el hogar con la mejor calidad y precio.',
      ),
      _Slide(
        icono:       Icons.favorite_rounded,
        colorFondo:  colorScheme.error.withOpacity(0.12),
        colorIcono:  colorScheme.error,
        titulo:      'Guarda tus favoritos',
        subtitulo:   'Agrega productos a favoritos para encontrarlos rápido y agregarlos al carrito cuando quieras.',
      ),
      _Slide(
        icono:       Icons.local_shipping_rounded,
        colorFondo:  colorScheme.secondary.withOpacity(0.12),
        colorIcono:  colorScheme.secondary,
        titulo:      'Compra fácil y seguro',
        subtitulo:   'Paga con MercadoPago, elige tu dirección de entrega y sigue el estado de tus pedidos.',
      ),
    ];
  }

  void _irSiguiente() {
    final slides = _slides;
    if (_paginaActual < slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _terminar();
    }
  }

  Future<void> _terminar() async {
    await marcarOnboardingVisto();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(widget.nextRoute);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final slides = _slides;
    final esUltima = _paginaActual == slides.length - 1;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Botón saltar (solo en las primeras páginas)
            Align(
              alignment: Alignment.topRight,
              child: AnimatedOpacity(
                opacity: esUltima ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: esUltima ? null : _terminar,
                  child: Text(
                    'Saltar',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _paginaActual = i),
                itemBuilder: (_, i) => _SlideWidget(slide: slides[i]),
              ),
            ),

            // Dots + botón
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.paddingL, 0,
                  AppDimensions.paddingL, AppDimensions.paddingL),
              child: Column(
                children: [
                  // Dots de progreso
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (i) {
                      final activo = i == _paginaActual;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width:  activo ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: activo
                              ? colorScheme.primary
                              : colorScheme.primary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),

                  // Botón principal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _irSiguiente,
                      child: Text(esUltima ? '¡Empezar!' : 'Siguiente'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Widget de cada slide individual
// ══════════════════════════════════════════════════════════════
class _SlideWidget extends StatelessWidget {
  final _Slide slide;
  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícono grande con fondo de color
          Container(
            width:  160,
            height: 160,
            decoration: BoxDecoration(
              color:  slide.colorFondo,
              shape:  BoxShape.circle,
            ),
            child: Icon(slide.icono, size: 80, color: slide.colorIcono),
          ),
          const SizedBox(height: AppDimensions.paddingXL),

          // Título
          Text(
            slide.titulo,
            style: textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // Subtítulo
          Text(
            slide.subtitulo,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}