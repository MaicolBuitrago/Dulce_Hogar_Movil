import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_client.dart';

class NuevaContrasenaScreen extends StatefulWidget {
  final String token;
  const NuevaContrasenaScreen({super.key, required this.token});

  @override
  State<NuevaContrasenaScreen> createState() => _NuevaContrasenaScreenState();
}

class _NuevaContrasenaScreenState extends State<NuevaContrasenaScreen> {
  final _nuevaController    = TextEditingController();
  final _confirmarController = TextEditingController();
  final _nuevaFocus          = FocusNode();
  final _confirmarFocus      = FocusNode();

  bool _loading          = false;
  bool _exitoso          = false;
  bool _obscureNueva     = true;
  bool _obscureConfirmar = true;
  bool _nuevaError       = false;
  bool _confirmarError   = false;
  String? _errorMsg;

  @override
  void dispose() {
    _nuevaController.dispose();
    _confirmarController.dispose();
    _nuevaFocus.dispose();
    _confirmarFocus.dispose();
    super.dispose();
  }

  void _snack(String msg, {required bool error}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: Colors.white, size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(msg,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: Duration(seconds: error ? 4 : 3),
        elevation: 8,
      ));
  }

  Future<void> _guardar() async {
    final nueva    = _nuevaController.text.trim();
    final confirmar = _confirmarController.text.trim();

    setState(() {
      _nuevaError    = false;
      _confirmarError = false;
      _errorMsg      = null;
    });

    if (nueva.isEmpty) {
      setState(() { _nuevaError = true; _errorMsg = 'Ingresa tu nueva contraseña'; });
      _snack('Ingresa tu nueva contraseña', error: true);
      _nuevaFocus.requestFocus();
      return;
    }

    if (nueva.length < 6) {
      setState(() { _nuevaError = true; _errorMsg = 'Mínimo 6 caracteres'; });
      _snack('La contraseña debe tener al menos 6 caracteres', error: true);
      _nuevaFocus.requestFocus();
      return;
    }

    if (confirmar.isEmpty) {
      setState(() { _confirmarError = true; _errorMsg = 'Confirma tu nueva contraseña'; });
      _snack('Confirma tu nueva contraseña', error: true);
      _confirmarFocus.requestFocus();
      return;
    }

    if (nueva != confirmar) {
      setState(() { _confirmarError = true; _errorMsg = 'Las contraseñas no coinciden'; });
      _snack('Las contraseñas no coinciden', error: true);
      _confirmarFocus.requestFocus();
      return;
    }

    setState(() => _loading = true);

    final res = await ApiClient.post('/api/auth/restablecer', {
      'token': widget.token,
      'nuevaContrasena': nueva,
    });

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.ok) {
      setState(() => _exitoso = true);
      _snack('¡Contraseña actualizada exitosamente!', error: false);
    } else {
      String msg = res.error ?? 'Error al restablecer la contraseña';
      if (msg.toLowerCase().contains('expirado') ||
          msg.toLowerCase().contains('expired') ||
          msg.toLowerCase().contains('invalid')) {
        msg = 'El enlace expiró o no es válido. Solicita uno nuevo.';
      }
      setState(() { _nuevaError = true; _errorMsg = msg; });
      _snack(msg, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppDimensions.paddingM),

                // ── Ícono ────────────────────────────────────────────────────
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.primary, size: 40),
                ),

                const SizedBox(height: AppDimensions.paddingM),

                Text('Nueva contraseña',
                    style: textTheme.displayMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  'Elige una contraseña segura\npara tu cuenta.',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimensions.paddingXL),

                // ── Card ─────────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _exitoso ? _buildExito(context) : _buildForm(context),
                ),

                const SizedBox(height: AppDimensions.paddingXXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Campo nueva contraseña ──────────────────────────────────────────
        Text('Nueva contraseña:',
            style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
        const SizedBox(height: 6),
        TextField(
          controller: _nuevaController,
          focusNode: _nuevaFocus,
          obscureText: _obscureNueva,
          textInputAction: TextInputAction.next,
          style: textTheme.bodyMedium,
          onChanged: (_) {
            if (_nuevaError) setState(() { _nuevaError = false; _errorMsg = null; });
          },
          onSubmitted: (_) => _confirmarFocus.requestFocus(),
          decoration: InputDecoration(
            hintText: 'Mínimo 6 caracteres',
            prefixIcon: Icon(Icons.lock_outline_rounded,
                color: _nuevaError ? AppColors.error : colorScheme.onSurfaceVariant,
                size: AppDimensions.iconS),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNueva ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: colorScheme.onSurfaceVariant, size: AppDimensions.iconS,
              ),
              onPressed: () => setState(() => _obscureNueva = !_obscureNueva),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                  color: _nuevaError ? AppColors.error : colorScheme.outline,
                  width: _nuevaError ? 1.5 : 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                  color: _nuevaError ? AppColors.error : AppColors.primary, width: 2),
            ),
          ),
        ),

        // Error nueva
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _nuevaError && _errorMsg != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.error, size: 13),
                    const SizedBox(width: 4),
                    Expanded(child: Text(_errorMsg!,
                        style: textTheme.bodySmall?.copyWith(color: AppColors.error, fontSize: 11))),
                  ]),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: AppDimensions.paddingM),

        // ── Campo confirmar ─────────────────────────────────────────────────
        Text('Confirmar contraseña:',
            style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmarController,
          focusNode: _confirmarFocus,
          obscureText: _obscureConfirmar,
          textInputAction: TextInputAction.done,
          style: textTheme.bodyMedium,
          onChanged: (_) {
            if (_confirmarError) setState(() { _confirmarError = false; _errorMsg = null; });
          },
          onSubmitted: (_) => _guardar(),
          decoration: InputDecoration(
            hintText: 'Repite tu nueva contraseña',
            prefixIcon: Icon(Icons.lock_outline_rounded,
                color: _confirmarError ? AppColors.error : colorScheme.onSurfaceVariant,
                size: AppDimensions.iconS),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmar ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: colorScheme.onSurfaceVariant, size: AppDimensions.iconS,
              ),
              onPressed: () => setState(() => _obscureConfirmar = !_obscureConfirmar),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                  color: _confirmarError ? AppColors.error : colorScheme.outline,
                  width: _confirmarError ? 1.5 : 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                  color: _confirmarError ? AppColors.error : AppColors.primary,
                  width: 2),
            ),
          ),
        ),

        // Error confirmar
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _confirmarError && _errorMsg != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.error, size: 13),
                    const SizedBox(width: 4),
                    Expanded(child: Text(_errorMsg!,
                        style: textTheme.bodySmall?.copyWith(color: AppColors.error, fontSize: 11))),
                  ]),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: AppDimensions.paddingL),

        // ── Botón guardar ───────────────────────────────────────────────────
        ElevatedButton(
          onPressed: _loading ? null : _guardar,
          child: _loading
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Text('Guardar nueva contraseña'),
        ),

        const SizedBox(height: AppDimensions.paddingM),

        Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
            child: Text('Volver al inicio de sesión',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                )),
          ),
        ),
      ],
    );
  }

  Widget _buildExito(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      children: [
        const SizedBox(height: AppDimensions.paddingM),

        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.success, size: 32),
        ),

        const SizedBox(height: AppDimensions.paddingM),

        Text('¡Contraseña actualizada!',
            style: textTheme.headlineMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: 8),

        Text(
          'Ya puedes iniciar sesión\ncon tu nueva contraseña.',
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.5),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppDimensions.paddingL),

        ElevatedButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
          child: const Text('Ir al inicio de sesión'),
        ),

        const SizedBox(height: AppDimensions.paddingM),
      ],
    );
  }
}