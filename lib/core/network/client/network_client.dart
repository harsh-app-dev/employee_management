import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:employee_management/core/utils/network_result.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

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
      final response = await _client.get(uri, headers: mergedHeaders).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out after 10 seconds');
        },
      );
      print('Response: ${response.statusCode} ${response.body}');
      return _handleResponse<T>(response, parser);
    } on http.ClientException catch (e) {
      print('ClientException: $e');
      return NetworkError<T>(-1, 'No internet connection.');
    } on SocketException catch (e) {
      print('SocketException: $e');
      return NetworkError<T>(-1, 'No internet connection.');
    } on TimeoutException catch (e) {
      print('TimeoutException: $e');
      return NetworkError<T>(-1, 'Request timed out. Please try again.');
    } catch (e) {
      print('Error: $e');
      return NetworkError<T>(
        -1,
        'Something went wrong. Please try again later.',
      );
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
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out after 10 seconds');
        },
      );
      print('Response: ${response.statusCode} ${response.body}');
      return _handleResponse<T>(response, parser);
    } on http.ClientException catch (e) {
      print('ClientException: $e');
      return NetworkError<T>(-1, 'No internet connection.');
    } on SocketException catch (e) {
      print('SocketException: $e');
      return NetworkError<T>(-1, 'No internet connection.');
    } on TimeoutException catch (e) {
      print('TimeoutException: $e');
      return NetworkError<T>(-1, 'Request timed out. Please try again.');
    } catch (e) {
      print('Error: $e');
      return NetworkError<T>(
        -1,
        'Something went wrong. Please try again later.',
      );
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
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out after 10 seconds');
        },
      );
      print('Response: ${response.statusCode} ${response.body}');
      return _handleResponse<T>(response, parser);
    } on http.ClientException catch (e) {
      print('ClientException: $e');
      return NetworkError<T>(-1, 'No internet connection.');
    } on SocketException catch (e) {
      print('SocketException: $e');
      return NetworkError<T>(-1, 'No internet connection.');
    } on TimeoutException catch (e) {
      print('TimeoutException: $e');
      return NetworkError<T>(-1, 'Request timed out. Please try again.');
    } catch (e) {
      print('Error: $e');
      return NetworkError<T>(
        -1,
        'Something went wrong. Please try again later.',
      );
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
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out after 10 seconds');
        },
      );
      print('Response: ${response.statusCode} ${response.body}');
      return _handleResponse<T>(response, parser);
    } on http.ClientException catch (e) {
      print('ClientException: $e');
      return NetworkError<T>(-1, 'No internet connection.');
    } on SocketException catch (e) {
      print('SocketException: $e');
      return NetworkError<T>(-1, 'No internet connection.');
    } on TimeoutException catch (e) {
      print('TimeoutException: $e');
      return NetworkError<T>(-1, 'Request timed out. Please try again.');
    } catch (e) {
      print('Error: $e');
      return NetworkError<T>(
        -1,
        'Something went wrong. Please try again later.',
      );
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
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out after 10 seconds');
        },
      );
      print('Response: ${response.statusCode} ${response.body}');
      return _handleResponse<T>(response, parser);
    } on http.ClientException catch (e) {
      print('ClientException: $e');
      return NetworkError<T>(-1, 'No internet connection.');
    } on SocketException catch (e) {
      print('SocketException: $e');
      return NetworkError<T>(-1, 'No internet connection.');
    } on TimeoutException catch (e) {
      print('TimeoutException: $e');
      return NetworkError<T>(-1, 'Request timed out. Please try again.');
    } catch (e) {
      print('Error: $e');
      return NetworkError<T>(
        -1,
        'Something went wrong. Please try again later.',
      );
    }
  }

  NetworkResult<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic json)? parser,
  ) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body);
        final data = parser != null ? parser(json) : json as T;
        return NetworkSuccess<T>(data);
      } else {
        String userMessage = 'Something went wrong. Please try again later.';
        String? message;
        try {
          final errorJson = jsonDecode(response.body);
          message =
              errorJson['message'] ?? errorJson['detail'] ?? errorJson['error'];
        } catch (_) {
          message = response.reasonPhrase;
        }
        switch (response.statusCode) {
          case 400:
            userMessage = message ?? 'Bad request.';
            break;
          case 401:
            userMessage = message ?? 'Unauthorized. Please login again.';
            break;
          case 403:
            userMessage = message ?? 'Forbidden. You do not have permission.';
            break;
          case 404:
            userMessage = message ?? 'Resource not found.';
            break;
          case 408:
            userMessage = 'Request timed out. Please try again.';
            break;
          case 422:
            userMessage = message ?? 'Unprocessable entity.';
            break;
          case 500:
            userMessage = 'Server error. Please try again later.';
            break;
          case 502:
          case 503:
          case 504:
            userMessage = 'Server unavailable. Please try again later.';
            break;
          default:
            userMessage = message ?? userMessage;
        }
        return NetworkError<T>(response.statusCode, userMessage);
      }
    } on FormatException {
      return NetworkError<T>(-1, 'Invalid response format.');
    } catch (e) {
      return NetworkError<T>(
        -1,
        'Something went wrong. Please try again later.',
      );
    }
  }
}
