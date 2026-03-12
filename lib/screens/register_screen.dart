// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _acceptTerms     = false;
  bool _loading         = false;

  final _cedulaController    = TextEditingController();
  final _nombreController    = TextEditingController();
  final _apellidoController  = TextEditingController();
  final _emailController     = TextEditingController();
  final _passwordController  = TextEditingController();
  final _confirmController   = TextEditingController();

  @override
  void dispose() {
    _cedulaController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final cedula   = _cedulaController.text.trim();
    final nombre   = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm  = _confirmController.text.trim();

    if (cedula.isEmpty || nombre.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnack('Todos los campos son obligatorios');
      return;
    }
    if (password != confirm) {
      _showSnack('Las contraseñas no coinciden');
      return;
    }
    if (password.length < 6) {
      _showSnack('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => _loading = true);

    final result = await AuthService.registro(
      cedula: cedula,
      nombre: nombre,
      apellido: apellido,
      email: email,
      contrasena: password,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      onOk: (_) {
        _showSnack('¡Cuenta creada! Inicia sesión');
        Navigator.of(context).pushReplacementNamed('/login');
      },
      onError: (e) => _showSnack(e),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: msg.contains('creada') ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

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
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimensions.paddingL),
                    const Text('Regístrate en\nDulce Hogar', style: AppTextStyles.displayLarge),
                    const SizedBox(height: 8),
                    const Text('Crea tu cuenta para empezar a comprar', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppDimensions.paddingL),

                    Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField('Cédula *', 'Número de cédula', Icons.badge_outlined, _cedulaController, TextInputType.number),
                          const SizedBox(height: AppDimensions.paddingM),
                          _buildField('Nombre *', 'Tu nombre', Icons.person_outline_rounded, _nombreController, TextInputType.name),
                          const SizedBox(height: AppDimensions.paddingM),
                          _buildField('Apellido *', 'Tu apellido', Icons.person_outline_rounded, _apellidoController, TextInputType.name),
                          const SizedBox(height: AppDimensions.paddingM),
                          _buildField('E-mail *', 'correo@gmail.com', Icons.email_outlined, _emailController, TextInputType.emailAddress),
                          const SizedBox(height: AppDimensions.paddingM),

                          _buildLabel('Contraseña *:'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: AppTextStyles.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Mínimo 6 caracteres',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textHint, size: AppDimensions.iconS),
                              suffixIcon: GestureDetector(
                                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                child: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textHint, size: AppDimensions.iconS),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppDimensions.paddingM),

                          _buildLabel('Confirmar contraseña *:'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            style: AppTextStyles.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Repite tu contraseña',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textHint, size: AppDimensions.iconS),
                              suffixIcon: GestureDetector(
                                onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                child: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textHint, size: AppDimensions.iconS),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimensions.paddingM),

                    // Términos
                    GestureDetector(
                      onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 20, height: 20,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: _acceptTerms ? AppColors.primary : Colors.transparent,
                              border: Border.all(color: _acceptTerms ? AppColors.primary : AppColors.border, width: 2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _acceptTerms ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(child: Text('Acepto los Términos y Condiciones y la Política de Privacidad', style: AppTextStyles.bodySmall)),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimensions.paddingL),

                    ElevatedButton(
                      onPressed: (_acceptTerms && !_loading) ? _register : null,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Crear cuenta'),
                    ),

                    const SizedBox(height: AppDimensions.paddingM),

                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodySmall,
                            children: [
                              const TextSpan(text: '¿Ya tienes cuenta? '),
                              TextSpan(text: 'Inicia sesión', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                            ],
                          ),
                        ),
                      ),
                    ),

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
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
            child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
          ),
        ),
      ],
    ),
  );

  Widget _buildLabel(String text) => Text(text, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary));

  Widget _buildField(String label, String hint, IconData icon, TextEditingController ctrl, TextInputType type) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildLabel(label),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: type,
        textCapitalization: type == TextInputType.name ? TextCapitalization.words : TextCapitalization.none,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.textHint, size: AppDimensions.iconS),
        ),
      ),
    ],
  );
}
