import 'package:employee_management/core/network/client/network_client.dart';
import 'package:employee_management/core/storage/local_storage.dart';
import 'package:employee_management/core/storage/shared_preference_keys.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/punch/request/punch_in_out_request.dart';
import 'package:employee_management/features/data/models/punch/response/attendence_response.dart';
import 'package:employee_management/features/data/models/punch/response/punch_in_out_response.dart';
import 'package:employee_management/features/data/models/punch/response/punch_history_response.dart';
import 'package:employee_management/features/data/models/punch/state/PunchStateResponse.dart';
import 'package:injectable/injectable.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

@injectable
class PunchRepository {
  final NetworkClient _networkClient;
  final LocalStorage _localStorage;

  PunchRepository(this._networkClient, this._localStorage);

  Future<NetworkResult<PunchInOutResponse>> punchInOut(
      PunchInOutRequest punchInOutRequest,
      ) async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_networkClient.baseUrl}attendence/attendence-create/')
      );
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'accept': '*/*',
        'X-CSRFTOKEN': '5OtGmZanAgPHuHg1tScbBiOiWx2xiLS6jrJ7KLMnvVaLas84OkKeI8Th9qqIEFUv',
      });
      // Add fields from PunchInOutRequest
      final data = punchInOutRequest.toJson();
      data.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });
      // Print request details for debugging
      print('[POST] ${request.url}');
      print('Body: {fields: ${request.fields}}');
      if (request.fields.containsKey('type')) {
        print('Type sent: \'${request.fields['type']}\'');
      }
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Response: ${response.statusCode} $responseBody');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(responseBody);
        return NetworkSuccess(PunchInOutResponse.fromJson(jsonData));
      } else {
        return NetworkError(response.statusCode, responseBody);
      }
    } catch (e) {
      return NetworkError(-1, 'Upload failed: $e');
    }
  }

  // New method for multipart form data upload
  Future<NetworkResult<PunchInOutResponse>> punchInOutWithPhoto(
    String type, // 'punch_in', 'punch_out', 'break_start', 'break_end'
    String? punchedInLatLong,
    String? punchedOutLatLong,
    File? photoFile,
  ) async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_networkClient.baseUrl}attendence/attendence-create/')
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'accept': '*/*',
        'X-CSRFTOKEN': '5OtGmZanAgPHuHg1tScbBiOiWx2xiLS6jrJ7KLMnvVaLas84OkKeI8Th9qqIEFUv',
      });

      request.fields['type'] = type;

      if (type == 'punch_in') {
        request.fields['punched_in_lat_long'] = punchedInLatLong ?? '';
        if (photoFile != null && await photoFile.exists()) {
          final stream = http.ByteStream(photoFile.openRead());
          final length = await photoFile.length();
          final multipartFile = http.MultipartFile(
            'punch_in_photo',
            stream,
            length,
            filename: 'punch_in_photo.jpg',
          );
          request.files.add(multipartFile);
        }
      } else if (type == 'punch_out') {
        request.fields['punched_out_lat_long'] = punchedOutLatLong ?? '';
        if (photoFile != null && await photoFile.exists()) {
          final stream = http.ByteStream(photoFile.openRead());
          final length = await photoFile.length();
          final multipartFile = http.MultipartFile(
            'punch_out_photo',
            stream,
            length,
            filename: 'punch_out_photo.jpg',
          );
          request.files.add(multipartFile);
        }
      } else if (type == 'break_start') {
        // Optionally add break_start photo/latlong if needed in future
      } else if (type == 'break_end') {
        // Only send type for break_end
      }

      // Print request details for debugging
      print('[POST] ${request.url}');
      print('Body: {fields: ${request.fields}, files: ${request.files.map((f) => f.filename).toList()}}');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('Response: ${response.statusCode} $responseBody');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(responseBody);
        return NetworkSuccess(PunchInOutResponse.fromJson(jsonData));
      } else {
        return NetworkError(response.statusCode, responseBody);
      }
    } catch (e) {
      print('Upload failed: $e');
      return NetworkError(-1, 'Upload failed: $e');
    }
  }

  Future<NetworkResult<PunchStateResponse>> getPunchState() async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    return await _networkClient.get<PunchStateResponse>(
      "accounts/user/me/",
      headers: {"Authorization": "Bearer $token"},
      parser: (json) => PunchStateResponse.fromJson(json),
    );
  }

  // Fetch punch history with optional pagination and date range
  Future<NetworkResult<PunchHistoryResponse>> getPunchHistory({
    int? page,
    int? pageSize,
    String? startDate,
    String? endDate,
  }) async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    String url = "attendence/attendence-list";
    List<String> params = [];
    if (endDate != null) params.add('end_date=$endDate');
    if (page != null) params.add('page=$page');
    // if (pageSize != null) params.add('page_size=$pageSize');
    if (startDate != null) params.add('start_date=$startDate');
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }
    return await _networkClient.get<PunchHistoryResponse>(
      url,
      headers: {"Authorization": "Bearer $token"},
      parser: (json) => PunchHistoryResponse.fromJson(json),
    );
  }
  Future<NetworkResult<AttendanceResponse>> getPunchHistoryDetail({String? date}) async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    String url = "attendence/attendence-details-history";
    if (date != null) {
      url += "?start_date=$date";
    }
    return await _networkClient.get<AttendanceResponse>(
      url,
      headers: {"Authorization": "Bearer $token"},
      parser: (json) => AttendanceResponse.fromJson(json),
    );
  }

}
