import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../domain/receipt_food_item.dart';

/// Result of a supermarket receipt parse operation.
class ReceiptParseResult {
  const ReceiptParseResult({
    required this.success,
    this.supermarket,
    this.date,
    this.totalFacturaGtq,
    this.totalAlimentosGtq,
    this.summary,
    this.items = const [],
    this.errorMessage,
  });

  final bool success;
  final String? supermarket;
  final String? date;
  final double? totalFacturaGtq;
  final double? totalAlimentosGtq;
  final String? summary;
  final List<ReceiptFoodItem> items;
  final String? errorMessage;

  bool get hasItems => items.isNotEmpty;
  int get selectedCount => items.where((it) => it.isSelected).length;

  String? get formattedTotalFactura =>
      totalFacturaGtq != null ? 'Q ${totalFacturaGtq!.toStringAsFixed(2)}' : null;

  String? get formattedTotalAlimentos =>
      totalAlimentosGtq != null ? 'Q ${totalAlimentosGtq!.toStringAsFixed(2)}' : null;
}

/// Service that communicates with `/api/parse-receipt` to extract food items
/// from Guatemalan supermarket receipts.
class ReceiptParserService {
  ReceiptParserService({
    http.Client? client,
    this.proxyBaseUrl = '/api/parse-receipt',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String proxyBaseUrl;

  /// Sends a supermarket receipt photo to `/api/parse-receipt`.
  Future<ReceiptParseResult> parseReceipt(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    if (imageBytes.isEmpty) {
      return const ReceiptParseResult(
        success: false,
        errorMessage: 'La imagen del recibo está vacía.',
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
              .map((it) => ReceiptFoodItem.fromJson(it as Map<String, dynamic>))
              .toList();

          final indexed = items.asMap().entries.toList();
          indexed.sort((a, b) {
            final diff = _confidenceRank(a.value.confidence)
                .compareTo(_confidenceRank(b.value.confidence));
            if (diff != 0) return diff;
            return a.key.compareTo(b.key);
          });
          final sortedItems = indexed.map((e) => e.value).toList();

          double? parseDouble(dynamic v) {
            if (v == null) return null;
            if (v is num) return v.toDouble();
            return double.tryParse(v.toString());
          }

          return ReceiptParseResult(
            success: true,
            supermarket: body['supermarket']?.toString() ??
                'Supermercado de Guatemala',
            date: body['date']?.toString(),
            totalFacturaGtq: parseDouble(body['totalFacturaGtq']),
            totalAlimentosGtq: parseDouble(body['totalAlimentosGtq']),
            summary: body['summary']?.toString() ??
                'Recibo procesado con éxito',
            items: sortedItems,
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
          return ReceiptParseResult(
            success: false,
            errorMessage: message,
          );
        }
      } catch (_) {}

      return ReceiptParseResult(
        success: false,
        errorMessage:
            'Error al procesar el recibo (código HTTP ${lastResponse.statusCode}). Puedes reintentar o ingresar tus ingredientes manualmente.',
      );
    }

    if (lastError != null) {
      return const ReceiptParseResult(
        success: false,
        errorMessage:
            'No se pudo conectar con el servicio de procesamiento de recibos o se agotó el tiempo. Verifica tu conexión o agrega tus ingredientes manualmente.',
      );
    }

    return const ReceiptParseResult(
      success: false,
      errorMessage: 'No se pudo procesar la fotografía del recibo.',
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

  static int _confidenceRank(String c) {
    switch (c.trim().toLowerCase()) {
      case 'high':
        return 0;
      case 'medium':
        return 1;
      case 'low':
        return 2;
      default:
        return 1;
    }
  }
}

