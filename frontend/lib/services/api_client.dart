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
  ApiClient({http.Client? client, String? baseUrl, String? apiKey})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _apiKey = apiKey ?? AppConfig.apiKey;

  final http.Client _client;
  final String _baseUrl;
  final String _apiKey;

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_apiKey.isNotEmpty) {
      headers['X-API-Key'] = _apiKey;
    }
    return headers;
  }

  Future<bool> checkHealth() async {
    final uri = Uri.parse('$_baseUrl/health');
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 8));
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
          headers: _headers,
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 401) {
      throw ApiException(
        'Требуется API-ключ (передайте --dart-define=API_KEY=...)',
        statusCode: 401,
      );
    }

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

  Future<TransferResponse> createTransfer(CreateTransferRequest request) async {
    final uri = Uri.parse('$_baseUrl/v1/transfers');
    final response = await _client
        .post(
          uri,
          headers: _headers,
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 401) {
      throw ApiException(
        'Требуется API-ключ (передайте --dart-define=API_KEY=...)',
        statusCode: 401,
      );
    }

    if (response.statusCode != 200) {
      throw ApiException(
        'Transfer failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    return TransferResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<TransferResponse> getTransfer(String transferId) async {
    final encodedId = Uri.encodeComponent(transferId);
    final uri = Uri.parse('$_baseUrl/v1/transfers/$encodedId');
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 401) {
      throw ApiException(
        'Требуется API-ключ (передайте --dart-define=API_KEY=...)',
        statusCode: 401,
      );
    }

    if (response.statusCode != 200) {
      throw ApiException(
        'Transfer lookup failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    return TransferResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
