// lib/services/auth_service.dart
//
// Cambios:
//  • login() guarda los tokens con ApiClient.guardarSesion()
//  • logout() limpia almacenamiento seguro además de memoria
//  • Nuevo método checkSesionActiva() para usarse en main()

import '../models/models.dart';
import 'api_client.dart';
import 'service_result.dart';

class AuthService {
  AuthService._();

  // ── Login ─────────────────────────────────────────────────────────────────
  static Future<ServiceResult<Usuario>> login({
    required String email,
    required String contrasena,
  }) async {
    final res = await ApiClient.post('/login', {
      'email':     email,
      'contrasena': contrasena,
    });

    if (!res.ok) return ServiceResult.error(res.error ?? 'Credenciales incorrectas');

    // ApiClient.post() ya guardó los tokens automáticamente al detectar
    // que la respuesta contenía el campo "token". Solo necesitamos
    // extraer el usuario.
    final usuarioJson = res.data['usuario'] as Map<String, dynamic>?;
    if (usuarioJson == null) {
      return ServiceResult.error('Respuesta inválida del servidor');
    }

    return ServiceResult.ok(Usuario.fromJson(usuarioJson));
  }

  // ── Registro ──────────────────────────────────────────────────────────────
  static Future<ServiceResult<Usuario>> registro({
    required String cedula,
    required String nombre,
    required String apellido,
    required String email,
    required String contrasena,
    String? direccion,
    String? ciudad,
  }) async {
    final res = await ApiClient.post('/usuario', {
      'cedula':    cedula,
      'nombre':    nombre,
      'apellido':  apellido,
      'email':     email,
      'contrasena': contrasena,
      if (direccion != null) 'direccion': direccion,
      if (ciudad    != null) 'ciudad':    ciudad,
      'rol': 'cliente',
    });
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al registrar');
    return ServiceResult.ok(Usuario.fromJson(res.data['usuario'] ?? res.data));
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  static Future<ServiceResult<void>> logout() async {
    // Intentar avisar al servidor (puede fallar si no hay red — no importa)
    try {
      await ApiClient.post('/logout', {});
    } catch (_) {}
    await ApiClient.limpiarSesion();
    return ServiceResult.ok(null);
  }

  // ── Perfil ────────────────────────────────────────────────────────────────
  static Future<ServiceResult<Usuario>> getPerfil() async {
    final res = await ApiClient.get('/usuario/perfil');
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al obtener perfil');
    return ServiceResult.ok(Usuario.fromJson(res.data));
  }

  static Future<ServiceResult<Usuario>> updatePerfil({
    required String nombre,
    required String apellido,
    String? direccion,
    String? ciudad,
    String? telefono,
  }) async {
    final res = await ApiClient.put('/usuario/perfil', {
      'nombre':   nombre,
      'apellido': apellido,
      if (direccion != null) 'direccion': direccion,
      if (ciudad    != null) 'ciudad':    ciudad,
      if (telefono  != null) 'telefono':  telefono,
    });
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al actualizar perfil');
    return ServiceResult.ok(Usuario.fromJson(res.data['usuario']));
  }

  // ── Recuperar contraseña ──────────────────────────────────────────────────
  static Future<ServiceResult<void>> recuperarContrasena(String email) async {
    final res = await ApiClient.post('/auth/recuperar', {'email': email});
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al enviar correo');
    return ServiceResult.ok(null);
  }

  // ── Verificar sesión al arrancar ──────────────────────────────────────────
  /// Devuelve true si hay sesión válida (o renovada con refresh token).
  /// Llamar desde main() antes de runApp().
  static Future<bool> checkSesionActiva() async {
    return ApiClient.initSession();
  }
}