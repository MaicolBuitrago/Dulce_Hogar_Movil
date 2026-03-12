// lib/services/auth_service.dart
import '../models/models.dart';
import 'api_client.dart';
import 'service_result.dart';

class AuthService {
  AuthService._();

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
      'cedula': cedula, 'nombre': nombre, 'apellido': apellido,
      'email': email, 'contrasena': contrasena,
      if (direccion != null) 'direccion': direccion,
      if (ciudad != null) 'ciudad': ciudad,
      'rol': 'cliente',
    });
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al registrar');
    return ServiceResult.ok(Usuario.fromJson(res.data['usuario'] ?? res.data));
  }

  static Future<ServiceResult<Usuario>> login({
    required String email,
    required String contrasena,
  }) async {
    final res = await ApiClient.post('/login', {
      'email': email,
      'contrasena': contrasena,
    });
    if (!res.ok) return ServiceResult.error(res.error ?? 'Credenciales incorrectas');

    // El backend usa cookies httpOnly. En Flutter guardamos el token
    // si viene en el body; si no, el cliente maneja la sesión via cookie header.
    final token = res.data['token'] as String?;
    if (token != null) await ApiClient.saveToken(token);

    final usuarioJson = res.data['usuario'] as Map<String, dynamic>?;
    if (usuarioJson == null) return ServiceResult.error('Respuesta inválida del servidor');
    return ServiceResult.ok(Usuario.fromJson(usuarioJson));
  }

  static Future<ServiceResult<void>> logout() async {
    await ApiClient.post('/logout', {});
    await ApiClient.deleteToken();
    return ServiceResult.ok(null);
  }

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
      'nombre': nombre, 'apellido': apellido,
      if (direccion != null) 'direccion': direccion,
      if (ciudad != null) 'ciudad': ciudad,
      if (telefono != null) 'telefono': telefono,
    });
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al actualizar perfil');
    return ServiceResult.ok(Usuario.fromJson(res.data['usuario']));
  }

  static Future<ServiceResult<void>> recuperarContrasena(String email) async {
    final res = await ApiClient.post('/auth/recuperar', {'email': email});
    if (!res.ok) return ServiceResult.error(res.error ?? 'Error al enviar correo');
    return ServiceResult.ok(null);
  }
}
