// lib/screens/perfil_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Usuario? _usuario;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final r = await AuthService.getPerfil();
    if (!mounted) return;
    setState(() {
      _usuario = r.data;
      _loading = false;
    });
    if (!r.ok) {
      _snack(r.error ?? 'Error al cargar el perfil', error: true);
    }
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

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusXL)),
        title: const Text('Cerrar sesión', style: AppTextStyles.headlineMedium),
        content: Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const SharedBottomNav(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                _buildHeader(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    child: Column(
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: AppDimensions.paddingM),
                        _buildMenuCard(),
                        const SizedBox(height: AppDimensions.paddingM),
                        _buildLogoutButton(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final nombre = _usuario?.nombre ?? '';
    final apellido = _usuario?.apellido ?? '';
    final iniciales = '${nombre.isNotEmpty ? nombre[0] : ''}${apellido.isNotEmpty ? apellido[0] : ''}'.toUpperCase();

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(right: -30, top: -30,
                child: Container(width: 180, height: 180,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.07)))),
              Positioned(left: -20, bottom: -40,
                child: Container(width: 140, height: 140,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05)))),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      // Avatar con iniciales
                      Container(
                        width: 76, height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2.5),
                        ),
                        child: Center(
                          child: Text(
                            iniciales.isEmpty ? '?' : iniciales,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$nombre $apellido',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _usuario?.email ?? '',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Información personal',
              style: AppTextStyles.headlineMedium.copyWith(fontSize: 15)),
          const SizedBox(height: 14),
          _InfoRow(icon: Icons.badge_outlined, label: 'Cédula', value: _usuario?.cedula ?? '-'),
          const _Divider(),
          _InfoRow(icon: Icons.phone_outlined, label: 'Teléfono', value: _usuario?.telefono ?? 'No registrado'),
          const _Divider(),
          _InfoRow(icon: Icons.location_on_outlined, label: 'Dirección', value: _usuario?.direccion ?? 'No registrada'),
          const _Divider(),
          _InfoRow(icon: Icons.location_city_outlined, label: 'Ciudad', value: _usuario?.ciudad ?? 'No registrada'),
        ],
      ),
    );
  }

  Widget _buildMenuCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.edit_outlined,
            iconColor: AppColors.primary,
            iconBg: AppColors.primaryPale,
            label: 'Editar perfil',
            subtitle: 'Actualiza tu nombre, dirección y más',
            onTap: () async {
              final actualizado = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EditarPerfilScreen(usuario: _usuario!),
                ),
              );
              if (actualizado == true) _cargarPerfil();
            },
          ),
          const _MenuDivider(),
          _MenuItem(
            icon: Icons.favorite_outline_rounded,
            iconColor: AppColors.error,
            iconBg: const Color(0xFFFFF1F2),
            label: 'Mis favoritos',
            subtitle: 'Productos que has guardado',
            onTap: () => Navigator.of(context).pushNamed('/favorites'),
          ),
          const _MenuDivider(),
          _MenuItem(
            icon: Icons.shopping_cart_outlined,
            iconColor: AppColors.secondary,
            iconBg: AppColors.secondaryLight,
            label: 'Mi carrito',
            subtitle: 'Ver productos en tu carrito',
            onTap: () => Navigator.of(context).pushNamed('/cart'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _cerrarSesion,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          border: Border.all(color: AppColors.error.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Text('Cerrar sesión',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets internos ───────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint, fontSize: 11)),
                const SizedBox(height: 1),
                Text(value, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(color: AppColors.divider, height: 1, thickness: 1);
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
        child: Divider(color: AppColors.divider, height: 1, thickness: 1),
      );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Pantalla editar perfil (inline en el mismo archivo)
// ════════════════════════════════════════════════════════════════════════════

class EditarPerfilScreen extends StatefulWidget {
  final Usuario usuario;
  const EditarPerfilScreen({super.key, required this.usuario});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _ciudadCtrl;
  late final TextEditingController _telefonoCtrl;

  bool _loading = false;
  bool _nombreError    = false;
  bool _apellidoError  = false;
  bool _direccionError = false;
  bool _ciudadError    = false;
  bool _telefonoError  = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl    = TextEditingController(text: widget.usuario.nombre);
    _apellidoCtrl  = TextEditingController(text: widget.usuario.apellido);
    _direccionCtrl = TextEditingController(text: widget.usuario.direccion ?? '');
    _ciudadCtrl    = TextEditingController(text: widget.usuario.ciudad ?? '');
    _telefonoCtrl  = TextEditingController(text: widget.usuario.telefono ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _apellidoCtrl.dispose();
    _direccionCtrl.dispose(); _ciudadCtrl.dispose(); _telefonoCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {required bool error}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white, size: 20),
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

  bool _validar() {
    final regexTexto   = RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ\s]+$');
    final regexDir     = RegExp(r'^[A-Za-z0-9\s\-\#\.,]+$');
    final nombre    = _nombreCtrl.text.trim();
    final apellido  = _apellidoCtrl.text.trim();
    final direccion = _direccionCtrl.text.trim();
    final ciudad    = _ciudadCtrl.text.trim();
    final telefono  = _telefonoCtrl.text.trim();

    setState(() {
      _nombreError    = nombre.isEmpty || !regexTexto.hasMatch(nombre);
      _apellidoError  = apellido.isEmpty || !regexTexto.hasMatch(apellido);
      _direccionError = direccion.isNotEmpty && !regexDir.hasMatch(direccion);
      _ciudadError    = ciudad.isNotEmpty && !regexTexto.hasMatch(ciudad);
      _telefonoError  = telefono.isNotEmpty &&
          !RegExp(r'^\d{7,15}$').hasMatch(telefono.replaceAll(' ', ''));
    });

    if (_nombreError) {
      _snack('El nombre solo puede contener letras y no puede estar vacío', error: true);
      return false;
    }
    if (_apellidoError) {
      _snack('El apellido solo puede contener letras y no puede estar vacío', error: true);
      return false;
    }
    if (_ciudadError) {
      _snack('La ciudad solo puede contener letras', error: true);
      return false;
    }
    if (_direccionError) {
      _snack('La dirección tiene caracteres no válidos', error: true);
      return false;
    }
    if (_telefonoError) {
      _snack('El teléfono debe tener entre 7 y 15 dígitos', error: true);
      return false;
    }
    return true;
  }

  Future<void> _guardar() async {
    if (!_validar()) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusXL)),
        title: const Text('Confirmar cambios', style: AppTextStyles.headlineMedium),
        content: Text('¿Deseas guardar los cambios en tu perfil?',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _loading = true);

    final tel = _telefonoCtrl.text.trim();
    final res = await AuthService.updatePerfil(
      nombre:    _nombreCtrl.text.trim(),
      apellido:  _apellidoCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim().isEmpty ? null : _direccionCtrl.text.trim(),
      ciudad:    _ciudadCtrl.text.trim().isEmpty ? null : _ciudadCtrl.text.trim(),
      telefono:  tel.isEmpty ? null : tel,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.ok) {
      _snack('¡Perfil actualizado exitosamente!', error: false);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop(true); // devuelve true → recarga
    } else {
      _snack(res.error ?? 'Error al actualizar el perfil', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text('Editar perfil', style: AppTextStyles.headlineMedium.copyWith(fontSize: 18)),
        centerTitle: true,
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _guardar,
              child: Text('Guardar',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children: [
            // ── Card info bloqueada ───────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                const Icon(Icons.lock_outline_rounded, color: AppColors.textHint, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Cédula y email no se pueden modificar',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                )),
              ]),
            ),

            // ── Campos editables ──────────────────────────────────────────
            _buildCard(children: [
              _buildField(
                label: 'Nombre *',
                controller: _nombreCtrl,
                icon: Icons.person_outline_rounded,
                hasError: _nombreError,
                hint: 'Tu nombre',
                onChanged: (_) => setState(() => _nombreError = false),
              ),
              const SizedBox(height: AppDimensions.paddingM),
              _buildField(
                label: 'Apellido *',
                controller: _apellidoCtrl,
                icon: Icons.person_outline_rounded,
                hasError: _apellidoError,
                hint: 'Tu apellido',
                onChanged: (_) => setState(() => _apellidoError = false),
              ),
            ]),

            const SizedBox(height: AppDimensions.paddingM),

            _buildCard(children: [
              _buildField(
                label: 'Dirección',
                controller: _direccionCtrl,
                icon: Icons.location_on_outlined,
                hasError: _direccionError,
                hint: 'Ej: Calle 10 # 5-23',
                onChanged: (_) => setState(() => _direccionError = false),
              ),
              const SizedBox(height: AppDimensions.paddingM),
              _buildField(
                label: 'Ciudad',
                controller: _ciudadCtrl,
                icon: Icons.location_city_outlined,
                hasError: _ciudadError,
                hint: 'Tu ciudad',
                onChanged: (_) => setState(() => _ciudadError = false),
              ),
              const SizedBox(height: AppDimensions.paddingM),
              _buildField(
                label: 'Teléfono',
                controller: _telefonoCtrl,
                icon: Icons.phone_outlined,
                hasError: _telefonoError,
                hint: 'Ej: 3123456789',
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() => _telefonoError = false),
              ),
            ]),

            const SizedBox(height: AppDimensions.paddingL),

            // ── Campos bloqueados ─────────────────────────────────────────
            _buildCard(children: [
              _buildBlockedField(
                label: 'Cédula',
                value: widget.usuario.cedula,
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              _buildBlockedField(
                label: 'Email',
                value: widget.usuario.email,
                icon: Icons.email_outlined,
              ),
            ]),

            const SizedBox(height: AppDimensions.paddingL),

            ElevatedButton(
              onPressed: _loading ? null : _guardar,
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Guardar cambios'),
            ),

            const SizedBox(height: AppDimensions.paddingM),

            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool hasError,
    required String hint,
    TextInputType? keyboardType,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTextStyles.bodyMedium,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon,
                color: hasError ? AppColors.error : AppColors.textHint,
                size: AppDimensions.iconS),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                  color: hasError ? AppColors.error : AppColors.border,
                  width: hasError ? 1.5 : 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                  color: hasError ? AppColors.error : AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockedField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600, color: AppColors.textHint, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Icon(icon, color: AppColors.textHint, size: AppDimensions.iconS),
            const SizedBox(width: 12),
            Text(value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
          ]),
        ),
      ],
    );
  }
}