// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../services/auth_service.dart';
import '../services/service_result.dart';
import '../services/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _loading = false;

  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Por favor ingresa tu correo y contraseña');
      return;
    }

    setState(() => _loading = true);

    final result = await AuthService.login(
      email: email,
      contrasena: password,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      onOk: (usuario) {
        // Guardar token si el backend lo devuelve en el body
        // (en este backend el token va en cookie httpOnly, pero guardamos cedula)
        Navigator.of(context).pushReplacementNamed('/');
      },
      onError: (error) => _showSnack(error),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: msg.contains('exitoso') ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppDimensions.paddingXXL),
                const DulceHogarLogo(size: 64),
                const SizedBox(height: AppDimensions.paddingXXL),

                // Card de login
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Inicio de sesión', style: AppTextStyles.displayMedium),
                      const SizedBox(height: 4),
                      const Text('Bienvenido de nuevo', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: AppDimensions.paddingL),

                      // Email
                      _buildLabel('E-mail:'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTextStyles.bodyMedium,
                        decoration: const InputDecoration(
                          hintText: 'correo@gmail.com',
                          prefixIcon: Icon(Icons.email_outlined, color: AppColors.textHint, size: AppDimensions.iconS),
                        ),
                      ),

                      const SizedBox(height: AppDimensions.paddingM),

                      // Contraseña
                      _buildLabel('Contraseña:'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: AppTextStyles.bodyMedium,
                        onSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textHint, size: AppDimensions.iconS),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                            child: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textHint,
                              size: AppDimensions.iconS,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppDimensions.paddingL),

                      // Botón ingresar
                      ElevatedButton(
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Ingresar'),
                      ),

                      const SizedBox(height: AppDimensions.paddingM),

                      // Links
                      Center(
                        child: Column(
                          children: [
                            _buildLinkRow('¿Olvidaste tu contraseña? ', 'Recupérala aquí', () {}),
                            const SizedBox(height: 6),
                            _buildLinkRow('¿No tienes cuenta? ', 'Regístrate', () {
                              Navigator.of(context).pushNamed('/register');
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.paddingXXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
  );

  Widget _buildLinkRow(String prefix, String link, VoidCallback onTap) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.bodySmall,
        children: [
          TextSpan(text: prefix),
          WidgetSpan(
            child: GestureDetector(
              onTap: onTap,
              child: Text(link, style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              )),
            ),
          ),
        ],
      ),
    );
  }
}
