import 'dart:convert';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;

@lazySingleton
class NetworkClient {
  final String baseUrl;
  final http.Client _client = http.Client();

  // Default headers
  static const Map<String, String> _defaultHeaders = {
    'accept': '*/*',
    'Content-Type': 'application/json',
    'X-CSRFTOKEN':
        '5OtGmZanAgPHuHg1tScbBiOiWx2xiLS6jrJ7KLMnvVaLas84OkKeI8Th9qqIEFUv',
  };

  NetworkClient({required this.baseUrl});

  Uri _buildUri(String endpoint) => Uri.parse('$baseUrl$endpoint');

  Map<String, String> _mergeHeaders(Map<String, String>? headers) {
    return {..._defaultHeaders, if (headers != null) ...headers};
  }

  Future<NetworkResult<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic json)? parser,
  }) async {
    final uri = _buildUri(endpoint);
    final mergedHeaders = _mergeHeaders(headers);
    print('[GET] $uri');
    print('Headers: $mergedHeaders');
    try {
      final response = await _client.get(uri, headers: mergedHeaders);
      return _handleResponse<T>(response, parser);
    } catch (e) {
      return NetworkError<T>(-1, e.toString());
    }
  }

  Future<NetworkResult<T>> post<T>(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    T Function(dynamic json)? parser,
  }) async {
    final uri = _buildUri(endpoint);
    final mergedHeaders = _mergeHeaders(headers);
    print('[POST] $uri');
    print('Headers: $mergedHeaders');
    print('Body: ${body != null ? jsonEncode(body) : null}');
    try {
      final response = await _client.post(
        uri,
        headers: mergedHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      print('Response: ${response.statusCode} ${response.body}');
      return _handleResponse<T>(response, parser);
    } catch (e) {
      print('Error: $e');
      return NetworkError<T>(-1, e.toString());
    }
  }

  Future<NetworkResult<T>> put<T>(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    T Function(dynamic json)? parser,
  }) async {
    final uri = _buildUri(endpoint);
    final mergedHeaders = _mergeHeaders(headers);
    print('[PUT] $uri');
    print('Headers: $mergedHeaders');
    print('Body: ${body != null ? jsonEncode(body) : null}');
    try {
      final response = await _client.put(
        uri,
        headers: mergedHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      print('Response: ${response.statusCode} ${response.body}');
      return _handleResponse<T>(response, parser);
    } catch (e) {
      print('Error: $e');
      return NetworkError<T>(-1, e.toString());
    }
  }

  Future<NetworkResult<T>> patch<T>(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    T Function(dynamic json)? parser,
  }) async {
    final uri = _buildUri(endpoint);
    final mergedHeaders = _mergeHeaders(headers);
    print('[PATCH] $uri');
    print('Headers: $mergedHeaders');
    print('Body: ${body != null ? jsonEncode(body) : null}');
    try {
      final response = await _client.patch(
        uri,
        headers: mergedHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      print('Response: ${response.statusCode} ${response.body}');
      return _handleResponse<T>(response, parser);
    } catch (e) {
      print('Error: $e');
      return NetworkError<T>(-1, e.toString());
    }
  }

  Future<NetworkResult<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    T Function(dynamic json)? parser,
  }) async {
    final uri = _buildUri(endpoint);
    final mergedHeaders = _mergeHeaders(headers);
    print('[DELETE] $uri');
    print('Headers: $mergedHeaders');
    print('Body: ${body != null ? jsonEncode(body) : null}');
    try {
      final response = await _client.delete(
        uri,
        headers: mergedHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      print('Response: ${response.statusCode} ${response.body}');
      return _handleResponse<T>(response, parser);
    } catch (e) {
      print('Error: $e');
      return NetworkError<T>(-1, e.toString());
    }
  }

  NetworkResult<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic json)? parser,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      final data = parser != null ? parser(json) : json as T;
      return NetworkSuccess<T>(data);
    } else {
      return NetworkError<T>(
        response.statusCode,
        response.reasonPhrase ?? 'Error',
      );
    }
  }
}
