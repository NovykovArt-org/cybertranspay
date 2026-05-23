import 'dart:convert';

import 'package:cybertranspay/config.dart';
import 'package:cybertranspay/models/route_quote.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<bool> checkHealth() async {
    final uri = Uri.parse('$_baseUrl/health');
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      return false;
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['status'] == 'ok';
  }

  Future<QuoteResponse> fetchQuote(QuoteRequest request) async {
    final uri = Uri.parse('$_baseUrl/v1/routes/quote');
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw ApiException(
        'Quote failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    return QuoteResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
