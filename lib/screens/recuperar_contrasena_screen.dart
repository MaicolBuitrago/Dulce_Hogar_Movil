// lib/screens/recuperar_contrasena_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../services/auth_service.dart';

class RecuperarContrasenaScreen extends StatefulWidget {
  const RecuperarContrasenaScreen({super.key});
  @override
  State<RecuperarContrasenaScreen> createState() =>
      _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState
    extends State<RecuperarContrasenaScreen> {
  final _emailController = TextEditingController();
  final _emailFocus      = FocusNode();

  bool    _loading       = false;
  bool    _enviado       = false;   // muestra el estado de éxito
  bool    _emailError    = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  // ─── Validación igual que login ───────────────────────────────────────────
  bool _esCorreoValido(String email) {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.(com|co|net|org|edu|gov|io|info|biz|[a-z]{2,})$',
      caseSensitive: false,
    );
    return regex.hasMatch(email.trim());
  }

  // ─── SnackBar ─────────────────────────────────────────────────────────────
  void _snack(String msg, {required bool error}) {
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
                  msg,
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

  // ─── Enviar solicitud → POST /api/auth/recuperar ──────────────────────────
  Future<void> _enviar() async {
    final email = _emailController.text.trim();

    setState(() {
      _emailError = false;
      _errorMsg   = null;
    });

    if (email.isEmpty) {
      setState(() { _emailError = true; _errorMsg = 'Ingresa tu correo electrónico'; });
      _snack('Ingresa tu correo electrónico', error: true);
      _emailFocus.requestFocus();
      return;
    }

    if (!email.contains('@')) {
      setState(() { _emailError = true; _errorMsg = 'El correo debe contener "@"'; });
      _snack('El correo debe contener "@"  →  usuario@correo.com', error: true);
      _emailFocus.requestFocus();
      return;
    }

    if (!_esCorreoValido(email)) {
      setState(() {
        _emailError = true;
        _errorMsg   = 'Formato inválido. Ej: usuario@correo.com o .co';
      });
      _snack('Correo inválido. Formato: usuario@dominio.com o .co', error: true);
      _emailFocus.requestFocus();
      return;
    }

    setState(() => _loading = true);

    // Llama AuthService → POST /api/auth/recuperar (Brevo envía el correo)
    final result = await AuthService.recuperarContrasena(email);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.ok) {
      setState(() => _enviado = true);
      _snack('¡Correo enviado! Revisa tu bandeja de entrada', error: false);
    } else {
      String msg = result.error ?? 'Error al enviar el correo';
      if (msg.toLowerCase().contains('no encontrado') ||
          msg.toLowerCase().contains('not found') ||
          msg.contains('404')) {
        msg = 'No encontramos una cuenta con ese correo';
      } else if (msg.toLowerCase().contains('red') ||
          msg.toLowerCase().contains('timeout')) {
        msg = 'Sin conexión al servidor. Verifica tu red';
      }
      setState(() { _emailError = true; _errorMsg = msg; });
      _snack(msg, error: true);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppDimensions.paddingM),

                // ── Ícono grande ───────────────────────────────────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      color: AppColors.primary, size: 40),
                ),

                const SizedBox(height: AppDimensions.paddingM),

                const Text(
                  'Recuperar contraseña',
                  style: AppTextStyles.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Te enviaremos un enlace a tu correo\npara restablecer tu contraseña.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimensions.paddingXL),

                // ── Card ───────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _enviado
                      ? _buildExitoContent()
                      : _buildFormContent(),
                ),

                const SizedBox(height: AppDimensions.paddingXXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Contenido del formulario ─────────────────────────────────────────────
  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo correo
        Text(
          'Correo electrónico:',
          style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          style: AppTextStyles.bodyMedium,
          onChanged: (_) {
            if (_emailError)
              setState(() { _emailError = false; _errorMsg = null; });
          },
          onSubmitted: (_) => _enviar(),
          decoration: InputDecoration(
            hintText: 'usuario@correo.com',
            prefixIcon: Icon(
              Icons.email_outlined,
              color: _emailError ? AppColors.error : AppColors.textHint,
              size: AppDimensions.iconS,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                  color: _emailError ? AppColors.error : AppColors.border,
                  width: _emailError ? 1.5 : 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                  color: _emailError ? AppColors.error : AppColors.primary,
                  width: 2),
            ),
          ),
        ),

        // Mensaje de error bajo el campo
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _emailError && _errorMsg != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.error, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: AppDimensions.paddingL),

        // Botón enviar
        ElevatedButton(
          onPressed: _loading ? null : _enviar,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Text('Enviar enlace de recuperación'),
        ),

        const SizedBox(height: AppDimensions.paddingM),

        // Volver al login
        Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'Volver al inicio de sesión',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Contenido cuando se envió exitosamente ───────────────────────────────
  Widget _buildExitoContent() {
    return Column(
      children: [
        const SizedBox(height: AppDimensions.paddingM),

        // Ícono éxito
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: AppColors.success, size: 32),
        ),

        const SizedBox(height: AppDimensions.paddingM),

        const Text(
          '¡Correo enviado!',
          style: AppTextStyles.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary, height: 1.5),
            children: [
              const TextSpan(
                  text: 'Enviamos un enlace de recuperación a\n'),
              TextSpan(
                text: _emailController.text.trim(),
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
              const TextSpan(
                  text: '\n\nRevisa tu bandeja de entrada y también '
                      'la carpeta de spam.'),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.paddingL),

        // Info nota
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
                color: AppColors.secondary.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  color: AppColors.secondaryDark, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'El enlace expira en 30 minutos.',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondaryDark,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.paddingL),

        // Botón volver
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver al inicio de sesión'),
        ),

        const SizedBox(height: AppDimensions.paddingM),

        // Reenviar
        Center(
          child: GestureDetector(
            onTap: () => setState(() {
              _enviado    = false;
              _emailError = false;
              _errorMsg   = null;
            }),
            child: Text(
              '¿No llegó? Intentar con otro correo',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
      ],
    );
  }
}
