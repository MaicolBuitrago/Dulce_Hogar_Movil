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

  bool _emailError    = false;
  bool _passwordError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarMensajeArgumento();
      _checkAndRequestPermissions();
    });
  }

  void _mostrarMensajeArgumento() {
    if (!mounted) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['mensaje'] != null) {
      _snack(args['mensaje'] as String, error: true);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onKey(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final caps = HardwareKeyboard.instance.lockModesEnabled
          .contains(KeyboardLockMode.capsLock);
      if (caps != _capsLockOn) setState(() => _capsLockOn = caps);
    }
  }

  Future<void> _checkAndRequestPermissions() async {
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL)),
        backgroundColor: colorScheme.surface,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.security_rounded,
                color: colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text('Permisos de la app',
                  style: textTheme.titleMedium)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para brindarte la mejor experiencia, Dulce Hogar '
              'necesita los siguientes permisos:',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
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
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _permChannel.invokeMethod('requestPermissions');
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
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

  Widget _permRow(IconData icon, String titulo, String desc) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
              Text(desc,
                  style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  bool _esCorreoValido(String email) {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.(com|co|net|org|edu|gov|io|info|biz|[a-z]{2,})$',
      caseSensitive: false,
    );
    return regex.hasMatch(email.trim());
  }

  void _snack(String mensaje, {required bool error}) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
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
          backgroundColor: error ? colorScheme.error : colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: Duration(seconds: error ? 4 : 2),
          elevation: 8,
        ),
      );
  }

  Future<void> _login() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError    = false;
      _passwordError = false;
    });

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

    final result = await AuthService.login(email: email, contrasena: password);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      onOk: (_) {
        _snack('¡Bienvenido de nuevo!', error: false);
        Future.delayed(const Duration(milliseconds: 400), () {
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
        } else if (err.toLowerCase().contains('intentos') ||
            err.toLowerCase().contains('espera')) {
          msg = err;
          setState(() { _emailError = false; _passwordError = false; });
        }
        _snack(msg, error: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenH = MediaQuery.of(context).size.height;
    final topPad  = screenH < 600 ? 20.0 : AppDimensions.paddingXXL;
    final midPad  = screenH < 600 ? 16.0 : AppDimensions.paddingXXL;
    final logoSz  = screenH < 600 ? 48.0 : 64.0;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: colorScheme.background,
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
                      color: colorScheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusXL),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.1),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Inicio de sesión',
                            style: textTheme.displayMedium),
                        const SizedBox(height: 4),
                        Text('Bienvenido de nuevo',
                            style: textTheme.bodyMedium),
                        const SizedBox(height: AppDimensions.paddingL),

                        _label(context, 'Correo electrónico:'),
                        const SizedBox(height: 6),
                        TextField(
                          controller:      _emailController,
                          focusNode:       _emailFocus,
                          keyboardType:    TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style:           textTheme.bodyMedium,
                          onChanged: (_) {
                            if (_emailError)
                              setState(() => _emailError = false);
                          },
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                          decoration: InputDecoration(
                            hintText: 'usuario@correo.com',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: _emailError
                                  ? colorScheme.error
                                  : colorScheme.onSurfaceVariant,
                              size: AppDimensions.iconS,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM),
                              borderSide: BorderSide(
                                  color: _emailError
                                      ? colorScheme.error
                                      : colorScheme.outline,
                                  width: _emailError ? 1.5 : 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM),
                              borderSide: BorderSide(
                                  color: _emailError
                                      ? colorScheme.error
                                      : colorScheme.primary,
                                  width: 2),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppDimensions.paddingM),

                        _label(context, 'Contraseña:'),
                        const SizedBox(height: 6),
                        TextField(
                          controller:      _passwordController,
                          focusNode:       _passwordFocus,
                          obscureText:     _obscurePassword,
                          textInputAction: TextInputAction.done,
                          style:           textTheme.bodyMedium,
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
                                  ? colorScheme.error
                                  : colorScheme.onSurfaceVariant,
                              size: AppDimensions.iconS,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM),
                              borderSide: BorderSide(
                                  color: _passwordError
                                      ? colorScheme.error
                                      : colorScheme.outline,
                                  width: _passwordError ? 1.5 : 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM),
                              borderSide: BorderSide(
                                  color: _passwordError
                                      ? colorScheme.error
                                      : colorScheme.primary,
                                  width: 2),
                            ),
                            suffixIcon: GestureDetector(
                              onTap: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: colorScheme.onSurfaceVariant,
                                size: AppDimensions.iconS,
                              ),
                            ),
                          ),
                        ),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _capsLockOn
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withOpacity(0.12),
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
                                          style: textTheme.bodySmall?.copyWith(
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

                        Center(
                          child: Column(
                            children: [
                              _linkRow(context,
                                '¿Olvidaste tu contraseña? ',
                                'Recupérala aquí',
                                () => Navigator.of(context)
                                    .pushNamed('/recuperar-contrasena'),
                              ),
                              const SizedBox(height: 6),
                              _linkRow(context,
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

                  SizedBox(
                      height: screenH < 600 ? 16 : AppDimensions.paddingXXL),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Text(
      text,
      style: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface),
    );
  }

  Widget _linkRow(BuildContext context, String prefix, String link, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return RichText(
      text: TextSpan(
        style: textTheme.bodySmall,
        children: [
          TextSpan(text: prefix),
          WidgetSpan(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                link,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
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
}