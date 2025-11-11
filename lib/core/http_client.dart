import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ✅ Como retry.dart está en la MISMA carpeta 'core', usa import relativo con alias:
import 'retry.dart' as r;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class SafeHttpClient {
  final http.Client _inner;
  final Duration timeout;

  SafeHttpClient({
    http.Client? inner,
    this.timeout = const Duration(seconds: 8),
  }) : _inner = inner ?? http.Client();

  Future<Map<String, dynamic>> getJson(
    Uri uri, {
    Map<String, String>? headers,
  }) {
    // ✅ Llama con alias r.retry(...)
    return r.retry<Map<String, dynamic>>(
      () async {
        final resp = await _inner.get(uri, headers: headers).timeout(timeout);

        if (resp.statusCode == 200) {
          try {
            return (jsonDecode(resp.body) as Map).cast<String, dynamic>();
          } catch (_) {
            throw ApiException(
              'Respuesta inválida del servidor',
              statusCode: resp.statusCode,
            );
          }
        }

        if (resp.statusCode == 429) {
          throw ApiException(
            'Límite de peticiones excedido (429). Intenta más tarde.',
            statusCode: 429,
          );
        }
        if (resp.statusCode >= 500) {
          throw ApiException(
            'Error del servidor (${resp.statusCode}).',
            statusCode: resp.statusCode,
          );
        }

        throw ApiException(
          'Error ${resp.statusCode}: ${resp.reasonPhrase}',
          statusCode: resp.statusCode,
        );
      },
      shouldRetry: (e, _) {
        if (e is ApiException) {
          return e.statusCode == 429 ||
              (e.statusCode != null && e.statusCode! >= 500);
        }
        return e is SocketException ||
            e is HttpException ||
            e is FormatException;
      },
      maxAttempts: 3,
      baseDelay: const Duration(milliseconds: 500),
      maxDelay: const Duration(seconds: 3),
    );
  }
}
