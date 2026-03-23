// lib/services/api_client.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient._();

  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  static const String baseUrl =
      'https://broderick-peristomatic-nonalphabetically.ngrok-free.dev/api';

  static const Duration _timeout = Duration(seconds: 15);

  // Token en memoria — persiste mientras la app esté abierta
  static String? _token;

  bool get estaAutenticado => _token != null && _token!.isNotEmpty;

  void guardarToken(String token) => _token = token;
  void limpiarSesion() => _token = null;

  http.Client _makeClient() => http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── GET ──────────────────────────────────────────────────────
  static Future<ApiResponse> get(String path) async {
    final client = _instance._makeClient();
    try {
      final res = await client
          .get(Uri.parse('$baseUrl$path'), headers: _instance._headers)
          .timeout(_timeout);
      return _instance._procesar(res);
    } catch (e) {
      return ApiResponse.networkError('$e');
    } finally {
      client.close();
    }
  }

  // ── POST ─────────────────────────────────────────────────────
  static Future<ApiResponse> post(String path, Map<String, dynamic> body) async {
    final client = _instance._makeClient();
    try {
      final res = await client
          .post(Uri.parse('$baseUrl$path'),
              headers: _instance._headers, body: jsonEncode(body))
          .timeout(_timeout);
      _instance._capturarToken(res);
      return _instance._procesar(res);
    } catch (e) {
      return ApiResponse.networkError('$e');
    } finally {
      client.close();
    }
  }

  // ── PUT ──────────────────────────────────────────────────────
  static Future<ApiResponse> put(String path, Map<String, dynamic> body) async {
    final client = _instance._makeClient();
    try {
      final res = await client
          .put(Uri.parse('$baseUrl$path'),
              headers: _instance._headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _instance._procesar(res);
    } catch (e) {
      return ApiResponse.networkError('$e');
    } finally {
      client.close();
    }
  }

  // ── PATCH ────────────────────────────────────────────────────
  static Future<ApiResponse> patch(String path, Map<String, dynamic> body) async {
    final client = _instance._makeClient();
    try {
      final res = await client
          .patch(Uri.parse('$baseUrl$path'),
              headers: _instance._headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _instance._procesar(res);
    } catch (e) {
      return ApiResponse.networkError('$e');
    } finally {
      client.close();
    }
  }

  // ── DELETE ───────────────────────────────────────────────────
  static Future<ApiResponse> delete(String path) async {
    final client = _instance._makeClient();
    try {
      final res = await client
          .delete(Uri.parse('$baseUrl$path'), headers: _instance._headers)
          .timeout(_timeout);
      return _instance._procesar(res);
    } catch (e) {
      return ApiResponse.networkError('$e');
    } finally {
      client.close();
    }
  }

  // ── Multipart ────────────────────────────────────────────────
  static Future<ApiResponse> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
  }) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
      req.headers['ngrok-skip-browser-warning'] = 'true';
      if (_token != null) {
        req.headers['Authorization'] = 'Bearer $_token';
      }
      req.fields.addAll(fields);
      req.files.addAll(files);
      final streamed = await req.send().timeout(_timeout);
      final res = await http.Response.fromStream(streamed);
      return _instance._procesar(res);
    } catch (e) {
      return ApiResponse.networkError('$e');
    }
  }

  void _capturarToken(http.Response response) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['token'] != null) {
          _token = body['token'].toString();
        }
      }
    } catch (_) {}
  }

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

  factory ApiResponse.networkError(String message) => ApiResponse(
        ok: false,
        statusCode: 0,
        error: 'Error de red: $message',
      );
}

typedef MultipartFile = http.MultipartFile;
