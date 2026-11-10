import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../domain/fridge_detected_item.dart';

/// Encapsulates the result of a refrigerator photo detection request.
class FridgeDetectionResult {
  const FridgeDetectionResult({
    required this.success,
    this.summary,
    this.items = const [],
    this.errorMessage,
  });

  final bool success;
  final String? summary;
  final List<FridgeDetectedItem> items;
  final String? errorMessage;

  bool get hasItems => items.isNotEmpty;
  int get selectedCount => items.where((it) => it.isSelected).length;
}

/// Service that communicates with the backend proxy `/api/detect-fridge`
/// to analyze refrigerator or pantry photos.
class FridgeVisionService {
  FridgeVisionService({
    http.Client? client,
    this.proxyBaseUrl = '/api/detect-fridge',
  })  : _client = client ?? http.Client();

  final http.Client _client;
  final String proxyBaseUrl;

  /// Analyzes a photo of a refrigerator/pantry by sending it to `/api/detect-fridge`.
  Future<FridgeDetectionResult> detectFridgeIngredients(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    if (imageBytes.isEmpty) {
      return const FridgeDetectionResult(
        success: false,
        errorMessage: 'La imagen seleccionada está vacía.',
      );
    }

    final base64Image = base64Encode(imageBytes);
    final candidateUris = _buildCandidateUris();
    http.Response? lastResponse;
    Object? lastError;

    for (final uri in candidateUris) {
      try {
        final response = await _client
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'image': base64Image,
                'mimeType': mimeType,
              }),
            )
            .timeout(const Duration(seconds: 35));

        if (response.statusCode == 200) {
          final Map<String, dynamic> body =
              jsonDecode(response.body) as Map<String, dynamic>;
          final rawItems = body['items'] as List<dynamic>? ?? [];

          final items = rawItems
              .map((it) =>
                  FridgeDetectedItem.fromJson(it as Map<String, dynamic>))
              .toList();

          return FridgeDetectionResult(
            success: true,
            summary: body['summary']?.toString() ??
                'Productos identificados en el refrigerador',
            items: items,
          );
        }

        lastResponse = response;
      } catch (e) {
        lastError = e;
      }
    }

    if (lastResponse != null) {
      try {
        final Map<String, dynamic> errBody =
            jsonDecode(lastResponse.body) as Map<String, dynamic>;
        final message = errBody['error']?.toString();
        if (message != null && message.isNotEmpty) {
          return FridgeDetectionResult(
            success: false,
            errorMessage: message,
          );
        }
      } catch (_) {}

      return FridgeDetectionResult(
        success: false,
        errorMessage:
            'Error al analizar la foto (código HTTP ${lastResponse.statusCode}). Puedes reintentar o ingresar tus ingredientes manualmente.',
      );
    }

    if (lastError != null) {
      return const FridgeDetectionResult(
        success: false,
        errorMessage:
            'No se pudo conectar con el servicio de análisis visual o se agotó el tiempo. Verifica tu conexión o ingresa tus ingredientes manualmente.',
      );
    }

    return const FridgeDetectionResult(
      success: false,
      errorMessage: 'No se pudo procesar la fotografía.',
    );
  }

  /// Builds candidate URIs for dev server and production.
  List<Uri> _buildCandidateUris() {
    final rawUri = Uri.parse(proxyBaseUrl);
    if (rawUri.hasScheme) {
      return [rawUri];
    }

    if (kIsWeb) {
      final host = Uri.base.host;
      final isLocalhost = host == 'localhost' || host == '127.0.0.1';
      if (isLocalhost && Uri.base.port != 3000) {
        final localUri = Uri.parse(
            'http://localhost:3000${proxyBaseUrl.startsWith('/') ? '' : '/'}$proxyBaseUrl');
        return [localUri, rawUri];
      }
      return [rawUri];
    }

    return [
      Uri.parse(
          'http://localhost:3000${proxyBaseUrl.startsWith('/') ? '' : '/'}$proxyBaseUrl'),
      Uri.parse(
          'http://localhost:8080${proxyBaseUrl.startsWith('/') ? '' : '/'}$proxyBaseUrl'),
    ];
  }
}
