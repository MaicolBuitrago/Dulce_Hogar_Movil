// lib/services/http_client.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Wrapper centralizado para todas las peticiones HTTP.
/// Maneja cookies de sesión (token JWT httpOnly) automáticamente.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  // Cookie de sesión recibida del backend
  String? _sessionCookie;

  // Headers base
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_sessionCookie != null) 'Cookie': _sessionCookie!,
      };

  /// Guarda la cookie de sesión que devuelve el backend tras el login
  void _guardarCookie(http.Response response) {
    final raw = response.headers['set-cookie'];
    if (raw != null && raw.isNotEmpty) {
      // Extrae solo "token=xxxxx" (el backend usa cookie httpOnly)
      final match = RegExp(r'token=[^;]+').firstMatch(raw);
      if (match != null) {
        _sessionCookie = match.group(0);
      }
    }
  }

  /// Borra la cookie (logout)
  void limpiarSesion() => _sessionCookie = null;

  bool get estaAutenticado => _sessionCookie != null;

  // ─────────────────────────────────────────────
  // GET
  // ─────────────────────────────────────────────
  Future<ApiResponse> get(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 15));
      return _procesar(response);
    } on SocketException {
      return ApiResponse.error('Sin conexión al servidor. Verifica que el backend esté corriendo.');
    } on HttpException {
      return ApiResponse.error('Error de red.');
    } catch (e) {
      return ApiResponse.error('Error inesperado: $e');
    }
  }

  // ─────────────────────────────────────────────
  // POST
  // ─────────────────────────────────────────────
  Future<ApiResponse> post(String url, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      _guardarCookie(response);
      return _procesar(response);
    } on SocketException {
      return ApiResponse.error('Sin conexión al servidor.');
    } catch (e) {
      return ApiResponse.error('Error inesperado: $e');
    }
  }

  // ─────────────────────────────────────────────
  // PUT
  // ─────────────────────────────────────────────
  Future<ApiResponse> put(String url, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _procesar(response);
    } on SocketException {
      return ApiResponse.error('Sin conexión al servidor.');
    } catch (e) {
      return ApiResponse.error('Error inesperado: $e');
    }
  }

  // ─────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────
  Future<ApiResponse> delete(String url) async {
    try {
      final response = await http
          .delete(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 15));
      return _procesar(response);
    } on SocketException {
      return ApiResponse.error('Sin conexión al servidor.');
    } catch (e) {
      return ApiResponse.error('Error inesperado: $e');
    }
  }

  // ─────────────────────────────────────────────
  // PATCH
  // ─────────────────────────────────────────────
  Future<ApiResponse> patch(String url, Map<String, dynamic> body) async {
    try {
      final response = await http
          .patch(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _procesar(response);
    } on SocketException {
      return ApiResponse.error('Sin conexión al servidor.');
    } catch (e) {
      return ApiResponse.error('Error inesperado: $e');
    }
  }

  // ─────────────────────────────────────────────
  // Procesar respuesta
  // ─────────────────────────────────────────────
  ApiResponse _procesar(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final ok = response.statusCode >= 200 && response.statusCode < 300;

      return ApiResponse(
        ok: ok,
        statusCode: response.statusCode,
        data: ok ? body : null,
        error: ok ? null : _extraerMensaje(body),
      );
    } catch (_) {
      return ApiResponse(
        ok: false,
        statusCode: response.statusCode,
        error: 'Respuesta inválida del servidor (${response.statusCode})',
      );
    }
  }

  String _extraerMensaje(dynamic body) {
    if (body is Map) {
      return body['message']?.toString() ??
          body['error']?.toString() ??
          'Error desconocido';
    }
    return body.toString();
  }
}

/// Resultado tipado de una petición HTTP
class ApiResponse {
  final bool ok;
  final int statusCode;
  final dynamic data;
  final String? error;

  const ApiResponse({
    required this.ok,
    required this.statusCode,
    this.data,
    this.error,
  });

  factory ApiResponse.error(String message) => ApiResponse(
        ok: false,
        statusCode: 0,
        error: message,
      );
}
