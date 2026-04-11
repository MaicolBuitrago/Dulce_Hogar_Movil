// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _acceptTerms     = false;
  bool _loading         = false;

  late final AnimationController _animCtrl;
  late final Animation<double>    _fadeAnim;
  late final Animation<Offset>    _slideAnim;

  final _cedulaController    = TextEditingController();
  final _nombreController    = TextEditingController();
  final _apellidoController  = TextEditingController();
  final _emailController     = TextEditingController();
  final _passwordController  = TextEditingController();
  final _confirmController   = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
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
      _showSnack('Todos los campos son obligatorios', isError: true);
      return;
    }
    if (password != confirm) {
      _showSnack('Las contraseñas no coinciden', isError: true);
      return;
    }
    if (password.length < 6) {
      _showSnack('La contraseña debe tener al menos 6 caracteres', isError: true);
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
      onError: (e) => _showSnack(e, isError: true),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13))),
        ],
      ),
      backgroundColor: isError ? AppColors.error : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Stack(
        children: [
          // Decoración de fondo — manchas de color suaves
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  center: Alignment.center,
                  radius: 0.8,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFF4A7FB5), Color(0xFF2C5F8A)],
                  center: Alignment.center,
                  radius: 0.8,
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFF5B732), Color(0xFFD97706)],
                  center: Alignment.center,
                  radius: 0.8,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeadline(context),
                            const SizedBox(height: 28),
                            _buildCard(context),
                            const SizedBox(height: 20),
                            _buildTermsRow(context),
                            const SizedBox(height: 24),
                            _buildSubmitButton(context),
                            const SizedBox(height: 20),
                            _buildLoginLink(context),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: colorScheme.onSurface, size: 17),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Paso 1 de 1',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadline(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crea tu\ncuenta',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Completa los datos para empezar a comprar',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _buildSection(
            context,
            icon: Icons.person_rounded,
            iconColor: AppColors.secondary,
            iconBg: AppColors.secondaryLight,
            label: 'Información personal',
            children: [
              _buildField(context, 'Cédula', 'Número de identificación', Icons.badge_outlined,
                  _cedulaController, TextInputType.number),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildField(context, 'Nombre', 'Tu nombre',
                      Icons.person_outline_rounded, _nombreController, TextInputType.name)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField(context, 'Apellido', 'Tu apellido',
                      Icons.person_outline_rounded, _apellidoController, TextInputType.name)),
                ],
              ),
              const SizedBox(height: 14),
              _buildField(context, 'Correo electrónico', 'ejemplo@correo.com',
                  Icons.alternate_email_rounded, _emailController, TextInputType.emailAddress),
            ],
          ),

          Divider(height: 1, color: colorScheme.outline.withOpacity(0.6)),

          _buildSection(
            context,
            icon: Icons.shield_outlined,
            iconColor: AppColors.primaryDark,
            iconBg: AppColors.primaryPale,
            label: 'Seguridad',
            children: [
              _buildPasswordField(context,
                label: 'Contraseña',
                hint: 'Mínimo 6 caracteres',
                controller: _passwordController,
                obscure: _obscurePassword,
                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 14),
              _buildPasswordField(context,
                label: 'Confirmar contraseña',
                hint: 'Repite tu contraseña',
                controller: _confirmController,
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.3,
              )),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(BuildContext context, String label, String hint, IconData icon,
      TextEditingController ctrl, TextInputType type) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        )),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          textCapitalization: type == TextInputType.name
              ? TextCapitalization.words
              : TextCapitalization.none,
          style: TextStyle(
            fontFamily: 'Nunito', fontSize: 14,
            fontWeight: FontWeight.w500, color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Nunito', fontSize: 13, color: colorScheme.onSurfaceVariant,
            ),
            prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant, size: 17),
            filled: true,
            fillColor: colorScheme.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        )),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(
            fontFamily: 'Nunito', fontSize: 14,
            fontWeight: FontWeight.w500, color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Nunito', fontSize: 13, color: colorScheme.onSurfaceVariant,
            ),
            prefixIcon: Icon(Icons.lock_outline_rounded, color: colorScheme.onSurfaceVariant, size: 17),
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: colorScheme.onSurfaceVariant, size: 17,
              ),
            ),
            filled: true,
            fillColor: colorScheme.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsRow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: () => setState(() => _acceptTerms = !_acceptTerms),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _acceptTerms ? AppColors.primaryPale : colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _acceptTerms ? AppColors.primaryBorder : colorScheme.outline,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: _acceptTerms ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: _acceptTerms ? AppColors.primary : colorScheme.outline,
                  width: 1.8,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _acceptTerms
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 13, color: colorScheme.onSurfaceVariant,
                  ),
                  children: [
                    const TextSpan(text: 'Acepto los '),
                    TextSpan(
                      text: 'Términos y Condiciones',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' y la '),
                    TextSpan(
                      text: 'Política de Privacidad',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AnimatedOpacity(
      opacity: _acceptTerms ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: (_acceptTerms && !_loading) ? _register : null,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: _acceptTerms
                ? const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : LinearGradient(colors: [colorScheme.outline, colorScheme.outline]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _acceptTerms
                ? [BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 16, offset: const Offset(0, 6))]
                : [],
          ),
          child: Center(
            child: _loading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Crear cuenta', style: TextStyle(
                        fontFamily: 'Nunito', fontSize: 15,
                        fontWeight: FontWeight.w700, color: Colors.white,
                        letterSpacing: 0.3,
                      )),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Text.rich(
          TextSpan(
            style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: colorScheme.onSurfaceVariant),
            children: [
              const TextSpan(text: '¿Ya tienes cuenta?  '),
              TextSpan(
                text: 'Inicia sesión',
                style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}