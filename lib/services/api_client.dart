import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// ─── Claves de almacenamiento seguro ──────────────────────────────────────
const _kToken        = 'dulce_hogar_token';
const _kRefreshToken = 'dulce_hogar_refresh_token';
const _kExpiresAt    = 'dulce_hogar_expires_at'; // epoch millis en String

class ApiClient {
  ApiClient._();

  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  // ⚠️ Actualiza esta URL cuando cambies el túnel ngrok
  static const String baseUrl =
      'https://broderick-peristomatic-nonalphabetically.ngrok-free.dev/api';

  static const Duration _timeout        = Duration(seconds: 15);
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Navegador global para redirigir al login sin contexto
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Estado en memoria (espejo de lo almacenado)
  static String?   _token;
  static String?   _refreshToken;
  static DateTime? _expiresAt;

  // ── Estado público ────────────────────────────────────────────────────────
  bool get estaAutenticado {
    if (_token == null || _token!.isEmpty) return false;
    if (_expiresAt == null) return false;
    // Consideramos autenticado si aún quedan más de 30 segundos
    return _expiresAt!.isAfter(DateTime.now().add(const Duration(seconds: 30)));
  }

  // ── Inicialización al arrancar la app ─────────────────────────────────────
  /// Llama esto en main() antes de runApp().
  /// Recupera el token guardado y devuelve true si la sesión sigue activa.
  static Future<bool> initSession() async {
    try {
      final token        = await _storage.read(key: _kToken);
      final refreshToken = await _storage.read(key: _kRefreshToken);
      final expiresStr   = await _storage.read(key: _kExpiresAt);

      if (token == null || refreshToken == null || expiresStr == null) {
        return false;
      }

      _token        = token;
      _refreshToken = refreshToken;
      _expiresAt    = DateTime.fromMillisecondsSinceEpoch(int.parse(expiresStr));

      // Si el access token ya expiró, intentar refresh antes de decir "autenticado"
      if (_instance.estaAutenticado) return true;

      // Access token expirado → intentar renovar con el refresh token
      final renovado = await _instance._intentarRefresh();
      return renovado;
    } catch (_) {
      return false;
    }
  }

  // ── Guardar / limpiar sesión ──────────────────────────────────────────────
  static Future<void> guardarSesion({
    required String token,
    required String refreshToken,
    required int expiresIn, // segundos
  }) async {
    _token        = token;
    _refreshToken = refreshToken;
    _expiresAt    = DateTime.now().add(Duration(seconds: expiresIn));

    await _storage.write(key: _kToken,        value: token);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
    await _storage.write(
      key:   _kExpiresAt,
      value: _expiresAt!.millisecondsSinceEpoch.toString(),
    );
  }

  static Future<void> limpiarSesion() async {
    _token        = null;
    _refreshToken = null;
    _expiresAt    = null;
    await _storage.deleteAll();
  }

  // ── Headers ───────────────────────────────────────────────────────────────
  Map<String, String> get _headers => {
        'Content-Type':              'application/json',
        'Accept':                    'application/json',
        'ngrok-skip-browser-warning':'true',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Refresh interno ───────────────────────────────────────────────────────
  /// Intenta renovar el access token usando el refresh token guardado.
  /// Devuelve true si tuvo éxito.
  Future<bool> _intentarRefresh() async {
    if (_refreshToken == null) return false;

    try {
      final client = http.Client();
      try {
        final res = await client
            .post(
              Uri.parse('$baseUrl/refresh'),
              headers: {
                'Content-Type':              'application/json',
                'ngrok-skip-browser-warning':'true',
              },
              body: jsonEncode({'refreshToken': _refreshToken}),
            )
            .timeout(_timeout);

        if (res.statusCode == 200) {
          final body = jsonDecode(utf8.decode(res.bodyBytes));
          await guardarSesion(
            token:        body['token'] as String,
            refreshToken: body['refreshToken'] as String,
            expiresIn:    (body['expiresIn'] as num?)?.toInt() ?? 3600,
          );
          return true;
        }
      } finally {
        client.close();
      }
    } catch (_) {}

    // Refresh fallido → limpiar y mandar al login
    await limpiarSesion();
    _redirigirAlLogin();
    return false;
  }

  /// Redirige al login con aviso de sesión expirada (sin contexto).
  void _redirigirAlLogin() {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.pushNamedAndRemoveUntil(
      '/login',
      (_) => false,
      arguments: {'mensaje': 'Tu sesión expiró. Inicia sesión de nuevo.'},
    );
  }

  // ── Ejecutor central con refresh automático ───────────────────────────────
  /// Ejecuta [llamada]. Si recibe 401 con `expired: true`, renueva el token
  /// y reintenta una vez. Si vuelve a fallar, limpia la sesión y redirige.
  Future<ApiResponse> _ejecutar(
    Future<http.Response> Function(Map<String, String> headers) llamada, {
    bool esRefresh = false,
  }) async {
    // Si el token está próximo a expirar (<5 min), refrescamos antes
    if (!esRefresh && _expiresAt != null) {
      final tiempoRestante = _expiresAt!.difference(DateTime.now());
      if (tiempoRestante.inMinutes < 5 && _refreshToken != null) {
        await _intentarRefresh();
      }
    }

    try {
      final res = await llamada(_headers).timeout(_timeout);
      final respuesta = _procesar(res);

      // 401 con expired:true → intentar refresh y reintentar UNA vez
      if (respuesta.statusCode == 401 && respuesta.expired && !esRefresh) {
        final renovado = await _intentarRefresh();
        if (renovado) {
          final res2 = await llamada(_headers).timeout(_timeout);
          return _procesar(res2);
        }
        return ApiResponse(
          ok: false,
          statusCode: 401,
          expired: true,
          error: 'Tu sesión expiró. Inicia sesión de nuevo.',
        );
      }

      return respuesta;
    } catch (e) {
      return ApiResponse.networkError('$e');
    }
  }

  // ── Métodos HTTP públicos ─────────────────────────────────────────────────

  static Future<ApiResponse> get(String path) async {
    final client = _instance.http_client();
    try {
      return await _instance._ejecutar(
        (h) => client.get(Uri.parse('$baseUrl$path'), headers: h),
      );
    } finally {
      client.close();
    }
  }

  static Future<ApiResponse> post(String path, Map<String, dynamic> body) async {
    final client = _instance.http_client();
    final encoded = jsonEncode(body);
    try {
      final respuesta = await _instance._ejecutar(
        (h) => client.post(Uri.parse('$baseUrl$path'), headers: h, body: encoded),
      );
      // Captura automática de tokens en la respuesta de login
      if (respuesta.ok && respuesta.data is Map) {
        final d = respuesta.data as Map;
        if (d['token'] != null) {
          await guardarSesion(
            token:        d['token'] as String,
            refreshToken: (d['refreshToken'] as String?) ?? _refreshToken ?? '',
            expiresIn:    (d['expiresIn'] as num?)?.toInt() ?? 3600,
          );
        }
      }
      return respuesta;
    } finally {
      client.close();
    }
  }

  static Future<ApiResponse> put(String path, Map<String, dynamic> body) async {
    final client = _instance.http_client();
    final encoded = jsonEncode(body);
    try {
      return await _instance._ejecutar(
        (h) => client.put(Uri.parse('$baseUrl$path'), headers: h, body: encoded),
      );
    } finally {
      client.close();
    }
  }

  static Future<ApiResponse> patch(String path, Map<String, dynamic> body) async {
    final client = _instance.http_client();
    final encoded = jsonEncode(body);
    try {
      return await _instance._ejecutar(
        (h) => client.patch(Uri.parse('$baseUrl$path'), headers: h, body: encoded),
      );
    } finally {
      client.close();
    }
  }

  static Future<ApiResponse> delete(String path) async {
    final client = _instance.http_client();
    try {
      return await _instance._ejecutar(
        (h) => client.delete(Uri.parse('$baseUrl$path'), headers: h),
      );
    } finally {
      client.close();
    }
  }

  static Future<ApiResponse> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
  }) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
      req.headers['ngrok-skip-browser-warning'] = 'true';
      if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
      req.fields.addAll(fields);
      req.files.addAll(files);
      final streamed = await req.send().timeout(_timeout);
      final res = await http.Response.fromStream(streamed);
      return _instance._procesar(res);
    } catch (e) {
      return ApiResponse.networkError('$e');
    }
  }

  // ── Helpers internos ──────────────────────────────────────────────────────
  http.Client http_client() => http.Client();

  ApiResponse _procesar(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final ok   = response.statusCode >= 200 && response.statusCode < 300;
      // Leer campo "expired" que el backend envía en 401
      final expired = !ok &&
          response.statusCode == 401 &&
          body is Map &&
          (body['expired'] == true);

      return ApiResponse(
        ok:         ok,
        statusCode: response.statusCode,
        expired:    expired,
        data:       ok ? body : null,
        error:      ok ? null : _extraerMensaje(body),
      );
    } catch (_) {
      return ApiResponse(
        ok:         false,
        statusCode: response.statusCode,
        error:      'Respuesta inválida del servidor (${response.statusCode})',
      );
    }
  }

  String _extraerMensaje(dynamic body) {
    String raw = '';
    if (body is Map) {
      raw = body['message']?.toString() ??
          body['error']?.toString() ??
          'Error desconocido';
    } else {
      raw = body.toString();
    }

    final lower = raw.toLowerCase();
    if (lower.contains('duplicate key') || lower.contains('unique constraint')) {
      if (lower.contains('email'))  return 'Este correo ya está registrado. ¿Ya tienes cuenta?';
      if (lower.contains('cedula')) return 'Esta cédula ya está registrada.';
      return 'Este dato ya está registrado.';
    }
    if (lower.contains('foreign key') || lower.contains('violates')) {
      return 'Error de datos. Verifica la información ingresada.';
    }
    if (lower.contains('not null') || lower.contains('null value')) {
      return 'Faltan campos obligatorios.';
    }
    if (lower.contains('invalid input syntax')) {
      return 'Formato de datos inválido.';
    }
    if (lower.contains('connection') || lower.contains('timeout')) {
      return 'Sin conexión con el servidor. Intenta de nuevo.';
    }
    if (lower.contains('expiró') || lower.contains('expired')) {
      return 'Tu sesión ha expirado. Inicia sesión de nuevo.';
    }

    return raw;
  }
}

// ─── Modelo de respuesta ─────────────────────────────────────────────────────
class ApiResponse {
  final bool    ok;
  final int     statusCode;
  final dynamic data;
  final String? error;
  final bool    expired; // true cuando el backend indica token expirado

  const ApiResponse({
    required this.ok,
    required this.statusCode,
    this.data,
    this.error,
    this.expired = false,
  });

  factory ApiResponse.networkError(String message) => ApiResponse(
        ok:         false,
        statusCode: 0,
        error:      'Error de red: $message',
      );
}

typedef MultipartFile = http.MultipartFile;