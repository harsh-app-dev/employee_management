import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;
import '../../utils/network_result.dart';

@lazySingleton
class NetworkClient {
  final String baseUrl;
  final http.Client _client = http.Client();

  NetworkClient({required this.baseUrl});

  Uri _buildUri(String endpoint) => Uri.parse('$baseUrl$endpoint');

  Future<NetworkResult<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic json)? parser,
  }) async {
    final uri = _buildUri(endpoint);
    print('[POST] $uri');
    print('Headers: $headers');
    try {
      final response = await _client.get(uri, headers: headers);
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
    print('[POST] $uri');
    print('Headers: $headers');
    print('Body: ${body != null ? jsonEncode(body) : null}');
    try {
      final response = await _client.post(
        uri,
        headers: headers,
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
    try {
      final uri = _buildUri(endpoint);
      print('[PUT] $uri');
      print('Headers: $headers');
      print('Body: ${body != null ? jsonEncode(body) : null}');
      final response = await _client.put(
        uri,
        headers: headers,
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
    print('[PATCH] $uri');
    print('Headers: $headers');
    print('Body: ${body != null ? jsonEncode(body) : null}');
    try {
      final response = await _client.patch(
        _buildUri(endpoint),
        headers: headers,
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
    try {
      final response = await _client.delete(
        _buildUri(endpoint),
        headers: headers,
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
