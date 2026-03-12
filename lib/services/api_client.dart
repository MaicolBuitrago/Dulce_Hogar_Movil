// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient._();

  // ── Cambia por tu IP/dominio ─────────────────────────────────
  static const String baseUrl = 'http://localhost:4000/api';
  // Emulador Android → 10.0.2.2
  // Dispositivo físico → 192.168.X.X:4000
  // Producción → https://tudominio.com/api

  static const String _tokenKey = 'auth_token';
  static const Duration _timeout = Duration(seconds: 15);

  // ── Token ────────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ── Headers ──────────────────────────────────────────────────
  // ── Headers ──────────────────────────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── HTTP Methods ─────────────────────────────────────────────
  static Future<ApiResponse> get(String path) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl$path'), headers: await _headers())
          .timeout(_timeout);
      return ApiResponse.from(res);
    } catch (e) {
      return ApiResponse.networkError(e.toString());
    }
  }

  static Future<ApiResponse> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl$path'),
              headers: await _headers(), body: jsonEncode(body))
          .timeout(_timeout);
      return ApiResponse.from(res);
    } catch (e) {
      return ApiResponse.networkError(e.toString());
    }
  }

  static Future<ApiResponse> put(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .put(Uri.parse('$baseUrl$path'),
              headers: await _headers(), body: jsonEncode(body))
          .timeout(_timeout);
      return ApiResponse.from(res);
    } catch (e) {
      return ApiResponse.networkError(e.toString());
    }
  }

  static Future<ApiResponse> patch(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .patch(Uri.parse('$baseUrl$path'),
              headers: await _headers(), body: jsonEncode(body))
          .timeout(_timeout);
      return ApiResponse.from(res);
    } catch (e) {
      return ApiResponse.networkError(e.toString());
    }
  }

  static Future<ApiResponse> delete(String path) async {
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl$path'), headers: await _headers())
          .timeout(_timeout);
      return ApiResponse.from(res);
    } catch (e) {
      return ApiResponse.networkError(e.toString());
    }
  }

  /// Multipart para subir imágenes (admin)
  static Future<ApiResponse> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<MultipartFile> files,
  }) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
      final token = await getToken();
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      req.fields.addAll(fields);
      req.files.addAll(files);
      final streamed = await req.send().timeout(_timeout);
      final res = await http.Response.fromStream(streamed);
      return ApiResponse.from(res);
    } catch (e) {
      return ApiResponse.networkError(e.toString());
    }
  }
}

// ── Respuesta genérica ───────────────────────────────────────
class ApiResponse {
  final int statusCode;
  final dynamic data;
  final String? error;
  final bool ok;

  const ApiResponse._({
    required this.statusCode,
    required this.data,
    this.error,
    required this.ok,
  });

  factory ApiResponse.from(http.Response res) {
    dynamic parsed;
    try {
      parsed = jsonDecode(res.body);
    } catch (_) {
      parsed = res.body;
    }
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    return ApiResponse._(
      statusCode: res.statusCode,
      data: ok ? parsed : null,
      error: ok ? null : (parsed is Map ? parsed['message'] ?? 'Error' : 'Error'),
      ok: ok,
    );
  }

  factory ApiResponse.networkError(String msg) => ApiResponse._(
        statusCode: 0,
        data: null,
        error: 'Error de red: $msg',
        ok: false,
      );
}

// ── Alias para claridad ──────────────────────────────────────
typedef MultipartFile = http.MultipartFile;
