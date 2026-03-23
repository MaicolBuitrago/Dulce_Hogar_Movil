// lib/screens/login_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../services/auth_service.dart';

const _permChannel = MethodChannel('dulce_hogar/permissions');

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _loading         = false;
  bool _capsLockOn      = false;

  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus         = FocusNode();
  final _passwordFocus      = FocusNode();

  // Para resaltar campos con error
  bool _emailError    = false;
  bool _passwordError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestPermissions();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ─── Caps Lock ────────────────────────────────────────────────────────────
  void _onKey(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final caps = HardwareKeyboard.instance.lockModesEnabled
          .contains(KeyboardLockMode.capsLock);
      if (caps != _capsLockOn) setState(() => _capsLockOn = caps);
    }
  }

  // ─── Permisos Android 13+ ─────────────────────────────────────────────────
  Future<void> _checkAndRequestPermissions() async {
    // defaultTargetPlatform funciona en web y nativo sin crashear
    if (kIsWeb) return;
    if (Theme.of(context).platform != TargetPlatform.android) return;
    bool mostrar = true;
    try {
      final sdk = await _permChannel.invokeMethod<int>('getSdkVersion') ?? 33;
      mostrar = sdk >= 33;
    } catch (_) {}
    if (mostrar && mounted) _showPermisosDialog();
  }

  void _showPermisosDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL)),
        backgroundColor: AppColors.surface,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.security_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
              child: Text('Permisos de la app',
                  style: AppTextStyles.titleMedium)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para brindarte la mejor experiencia, Dulce Hogar '
              'necesita los siguientes permisos:',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            _permRow(Icons.notifications_outlined, 'Notificaciones',
                'Recibe alertas de pedidos en tiempo real'),
            const SizedBox(height: 10),
            _permRow(Icons.photo_library_outlined, 'Galería',
                'Comparte y visualiza imágenes de productos'),
            const SizedBox(height: 10),
            _permRow(Icons.location_on_outlined, 'Ubicación (opcional)',
                'Facilita el ingreso de tu dirección de entrega'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Ahora no',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _permChannel.invokeMethod('requestPermissions');
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
            ),
            child: const Text('Permitir'),
          ),
        ],
      ),
    );
  }

  Widget _permRow(IconData icon, String titulo, String desc) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(desc,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      );

  // ─── Validación de correo ─────────────────────────────────────────────────
  // Acepta: texto@algo.com | texto@algo.co | texto@algo.com.co | etc.
  bool _esCorreoValido(String email) {
    // Debe tener @ y dominio con extensión de 2+ letras
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.(com|co|net|org|edu|gov|io|info|biz|[a-z]{2,})$',
      caseSensitive: false,
    );
    return regex.hasMatch(email.trim());
  }

  // ─── SnackBar emergente ───────────────────────────────────────────────────
  void _snack(String mensaje, {required bool error}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mensaje,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: error ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          duration: Duration(seconds: error ? 4 : 3),
          elevation: 8,
        ),
      );
  }

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<void> _login() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    // Resetear errores visuales
    setState(() {
      _emailError    = false;
      _passwordError = false;
    });

    // Validaciones con snackbars emergentes
    if (email.isEmpty && password.isEmpty) {
      setState(() { _emailError = true; _passwordError = true; });
      _snack('Completa tu correo y contraseña para continuar', error: true);
      _emailFocus.requestFocus();
      return;
    }

    if (email.isEmpty) {
      setState(() => _emailError = true);
      _snack('Ingresa tu correo electrónico', error: true);
      _emailFocus.requestFocus();
      return;
    }

    if (!email.contains('@')) {
      setState(() => _emailError = true);
      _snack('El correo debe contener "@"  →  ejemplo@correo.com', error: true);
      _emailFocus.requestFocus();
      return;
    }

    if (!_esCorreoValido(email)) {
      setState(() => _emailError = true);
      _snack(
        'Correo inválido. Debe tener el formato: usuario@dominio.com o .co',
        error: true,
      );
      _emailFocus.requestFocus();
      return;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = true);
      _snack('Ingresa tu contraseña', error: true);
      _passwordFocus.requestFocus();
      return;
    }

    if (password.length < 6) {
      setState(() => _passwordError = true);
      _snack('La contraseña debe tener mínimo 6 caracteres', error: true);
      _passwordFocus.requestFocus();
      return;
    }

    setState(() => _loading = true);

    // POST /api/login
    final result = await AuthService.login(email: email, contrasena: password);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      onOk: (_) {
        _snack('¡Bienvenido de nuevo! Iniciando sesión...', error: false);
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) Navigator.of(context).pushReplacementNamed('/');
        });
      },
      onError: (err) {
        setState(() { _emailError = true; _passwordError = true; });
        String msg = 'Correo o contraseña incorrectos';
        if (err.toLowerCase().contains('red') ||
            err.toLowerCase().contains('timeout') ||
            err.toLowerCase().contains('socket')) {
          msg = 'Sin conexión al servidor. Verifica tu red e intenta de nuevo';
          setState(() { _emailError = false; _passwordError = false; });
        } else if (err.toLowerCase().contains('bloqueado') ||
            err.toLowerCase().contains('inactivo')) {
          msg = 'Tu cuenta está suspendida. Contacta soporte';
        }
        _snack(msg, error: true);
      },
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    // En pantallas pequeñas reducimos los espacios verticales
    final topPad  = screenH < 600 ? 20.0 : AppDimensions.paddingXXL;
    final midPad  = screenH < 600 ? 16.0 : AppDimensions.paddingXXL;
    final logoSz  = screenH < 600 ? 48.0 : 64.0;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: topPad),
                  DulceHogarLogo(size: logoSz),
                  SizedBox(height: midPad),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.paddingL),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusXL),
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
                        const Text('Inicio de sesión',
                            style: AppTextStyles.displayMedium),
                        const SizedBox(height: 4),
                        const Text('Bienvenido de nuevo',
                            style: AppTextStyles.bodyMedium),
                        const SizedBox(height: AppDimensions.paddingL),

                        // ── Correo ──────────────────────────────────────
                        _label('Correo electrónico:'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: AppTextStyles.bodyMedium,
                          onChanged: (_) {
                            if (_emailError) setState(() => _emailError = false);
                          },
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                          decoration: InputDecoration(
                            hintText: 'usuario@correo.com',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: _emailError
                                  ? AppColors.error
                                  : AppColors.textHint,
                              size: AppDimensions.iconS,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM),
                              borderSide: BorderSide(
                                  color: _emailError
                                      ? AppColors.error
                                      : AppColors.border,
                                  width: _emailError ? 1.5 : 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM),
                              borderSide: BorderSide(
                                  color: _emailError
                                      ? AppColors.error
                                      : AppColors.primary,
                                  width: 2),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppDimensions.paddingM),

                        // ── Contraseña ──────────────────────────────────
                        _label('Contraseña:'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          style: AppTextStyles.bodyMedium,
                          onChanged: (_) {
                            if (_passwordError)
                              setState(() => _passwordError = false);
                          },
                          onSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: _passwordError
                                  ? AppColors.error
                                  : AppColors.textHint,
                              size: AppDimensions.iconS,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM),
                              borderSide: BorderSide(
                                  color: _passwordError
                                      ? AppColors.error
                                      : AppColors.border,
                                  width: _passwordError ? 1.5 : 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM),
                              borderSide: BorderSide(
                                  color: _passwordError
                                      ? AppColors.error
                                      : AppColors.primary,
                                  width: 2),
                            ),
                            suffixIcon: GestureDetector(
                              onTap: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textHint,
                                size: AppDimensions.iconS,
                              ),
                            ),
                          ),
                        ),

                        // ── Aviso Caps Lock ─────────────────────────────
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _capsLockOn
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.warning.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusM),
                                      border: Border.all(
                                          color: AppColors.warning
                                              .withOpacity(0.5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                            Icons.keyboard_capslock_rounded,
                                            color: AppColors.warning,
                                            size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Bloq Mayús activado',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                            color: AppColors.warning,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        const SizedBox(height: AppDimensions.paddingL),

                        // ── Botón Ingresar ──────────────────────────────
                        ElevatedButton(
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text('Ingresar'),
                        ),

                        const SizedBox(height: AppDimensions.paddingM),

                        // ── Links ────────────────────────────────────────
                        Center(
                          child: Column(
                            children: [
                              _linkRow(
                                '¿Olvidaste tu contraseña? ',
                                'Recupérala aquí',
                                () => Navigator.of(context)
                                    .pushNamed('/recuperar-contrasena'),
                              ),
                              const SizedBox(height: 6),
                              _linkRow(
                                '¿No tienes cuenta? ',
                                'Regístrate',
                                () => Navigator.of(context)
                                    .pushNamed('/register'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenH < 600 ? 16 : AppDimensions.paddingXXL),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      );

  Widget _linkRow(String prefix, String link, VoidCallback onTap) =>
      RichText(
        text: TextSpan(
          style: AppTextStyles.bodySmall,
          children: [
            TextSpan(text: prefix),
            WidgetSpan(
              child: GestureDetector(
                onTap: onTap,
                child: Text(
                  link,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
