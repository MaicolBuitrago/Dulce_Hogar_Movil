import '../models/models.dart';
import '../config/api_config.dart';  // ← AGREGAR ESTA IMPORTACIÓN
import 'api_client.dart';
import 'service_result.dart';

class AuthService {
  AuthService._();

  // ── Login ─────────────────────────────────────────────────────────────────
  static Future<ServiceResult<Usuario>> login({
    required String email,
    required String contrasena,
  }) async {
    // ✅ USAR ApiConfig.login
    final res = await ApiClient.post(ApiConfig.login, {
      'email':     email,
      'contrasena': contrasena,
    });

    if (!res.ok) return ServiceResult.error(res.error ?? 'Credenciales incorrectas');

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
    // ✅ USAR ApiConfig.registro
    final res = await ApiClient.post(ApiConfig.registro, {
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
    try {
      // ✅ USAR ApiConfig.logout
      await ApiClient.post(ApiConfig.logout, {});
    } catch (_) {}
    await ApiClient.limpiarSesion();
    return ServiceResult.ok(null);
  }

  // ── Perfil ────────────────────────────────────────────────────────────────
  static Future<ServiceResult<Usuario>> getPerfil() async {
    // ✅ USAR ApiConfig.perfil
    final res = await ApiClient.get(ApiConfig.perfil);
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
    // ✅ USAR ApiConfig.perfil
    final res = await ApiClient.put(ApiConfig.perfil, {
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
    // ✅ USAR ApiConfig.recuperar
    final res = await ApiClient.post(ApiConfig.recuperar, {'email': email});
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al enviar correo');
    return ServiceResult.ok(null);
  }

  // ── Verificar sesión al arrancar ──────────────────────────────────────────
  static Future<bool> checkSesionActiva() async {
    return ApiClient.initSession();
  }
}