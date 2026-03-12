// lib/services/service_result.dart
// Wrapper genérico de resultado para todos los servicios

class ServiceResult<T> {
  final T? data;
  final String? error;
  final bool ok;

  const ServiceResult._({this.data, this.error, required this.ok});

  factory ServiceResult.ok(T? data) =>
      ServiceResult._(data: data, ok: true);

  factory ServiceResult.error(String message) =>
      ServiceResult._(error: message, ok: false);

  /// Ejecuta [onOk] si fue exitoso, [onError] si falló
  R when<R>({
    required R Function(T? data) onOk,
    required R Function(String error) onError,
  }) {
    if (ok) return onOk(data);
    return onError(error ?? 'Error desconocido');
  }
}
