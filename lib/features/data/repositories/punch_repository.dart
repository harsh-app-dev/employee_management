import 'package:employee_management/core/network/client/network_client.dart';
import 'package:employee_management/core/storage/local_storage.dart';
import 'package:employee_management/core/storage/shared_preference_keys.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/punch/request/punch_in_out_request.dart';
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
    return await _networkClient.post<PunchInOutResponse>(
      "/attendance/punch/",
      headers: {"Authorization": "Bearer $token"},
      body: punchInOutRequest,
      parser: (json) => PunchInOutResponse.fromJson(json),
    );
  }

  // New method for multipart form data upload
  Future<NetworkResult<PunchInOutResponse>> punchInOutWithPhoto(
    String punchType, // 'in' or 'out'
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

      // Set fields according to punch type
      if (punchType == 'in') {
        request.fields['punched_in_lat_long'] = punchedInLatLong ?? '';
        request.fields['punched_out_lat_long'] = '';
        request.fields['punch_out_photo'] = '';
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
      } else if (punchType == 'out') {
        request.fields['punched_in_lat_long'] = '';
        request.fields['punched_out_lat_long'] = punchedOutLatLong ?? '';
        request.fields['punch_in_photo'] = '';
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
      }

      // Set other fields to null or empty as required by backend
      request.fields['punch_in'] = '';
      request.fields['punch_out'] = '';
      request.fields['attendance'] = '';

      // Print request details for debugging in consistent format
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
    String url = "attendence/attendence-history/";
    List<String> params = [];
    if (page != null) params.add('page=$page');
    if (pageSize != null) params.add('page_size=$pageSize');
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }
    return await _networkClient.get<PunchHistoryResponse>(
      url,
      headers: {"Authorization": "Bearer $token"},
      parser: (json) => PunchHistoryResponse.fromJson(json),
    );
  }

  // Break logs API
  Future<NetworkResult<dynamic>> createBreakLog({
    required String breakStart,
    required String breakOver,
    required int attendanceId,
  }) async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    final url = "attendence/break-logs-create/";
    final headers = {
      "Authorization": "Bearer $token",
      "accept": "application/json",
      "Content-Type": "application/json",
      "X-CSRFTOKEN": "Fv7MpkgvSv78FBaj8SVHV0TSlz2dhmTJ0qdeu5g8N3TuCSNzkTLpCUg0usy6K0Dq",
    };
    final body = jsonEncode({
      "break_start": breakStart,
      "break_over": breakOver,
      "attendance": attendanceId,
    });
    try {
      final response = await _networkClient.post(
        url,
        headers: headers,
        body: body,
        parser: (json) => json,
      );
      return response;
    } catch (e) {
      return NetworkError(-1, e.toString());
    }
  }
}
