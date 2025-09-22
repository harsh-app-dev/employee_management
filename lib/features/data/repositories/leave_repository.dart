import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:employee_management/core/network/client/network_client.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/leave/leave_type.dart';
import 'package:employee_management/features/data/models/leave/role_user.dart';
import 'package:employee_management/features/data/models/leave/leave_apply_request.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:employee_management/core/storage/local_storage.dart';
import 'package:employee_management/core/storage/shared_preference_keys.dart';
import '../models/leave/leave_response.dart';

@injectable
class LeaveRepository {
  final NetworkClient _networkClient;
  final LocalStorage _localStorage;

  LeaveRepository(this._networkClient, this._localStorage);

  Future<NetworkResult<Map<String, dynamic>>> fetchLeaveTypes() async {
    return await _networkClient.get<Map<String, dynamic>>(
      'leave/leave-types/',
      parser: (json) {
        final leaveTypes = (json['leave_types'] as List)
            .map((e) => LeaveType.fromJson(e))
            .toList();
        final halfDayOptions = (json['half_day_options'] as List)
            .map((e) => HalfDayOption.fromJson(e))
            .toList();
        return {
          'leaveTypes': leaveTypes,
          'halfDayOptions': halfDayOptions,
        };
      },
    );
  }

  Future<NetworkResult<Map<String, List<RoleUser>>>> fetchUsersByRole() async {
    return await _networkClient.get<Map<String, List<RoleUser>>>(
      'leave/users-by-role/',
      parser: (json) {
        final hrList = (json['hr'] as List)
            .map((e) => RoleUser.fromJson(e))
            .toList();
        final managerList = (json['manager'] as List)
            .map((e) => RoleUser.fromJson(e))
            .toList();
        return {
          'hr': hrList,
          'manager': managerList,
        };
      },
    );
  }

  Future<NetworkResult<dynamic>> applyLeave(LeaveApplyRequest request) async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    try {
      var uri = Uri.parse('${_networkClient.baseUrl}leave/leave-applications/');
      var multipartRequest = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'X-CSRFTOKEN': 'euRQJVDZBX8y5dhzWQZA4ig4knJTwag88YnsMB1b24QtpK1xlyYvGgRTNaQasgIK', // Add CSRF Token
        });

      // Add fields
      multipartRequest.fields['start_date'] = DateFormat('yyyy-MM-dd').format(request.startDate);
      multipartRequest.fields['end_date'] = DateFormat('yyyy-MM-dd').format(request.endDate);
      multipartRequest.fields['hr'] = request.hrId;
      multipartRequest.fields['leave_type'] = request.leaveTypeId;
      multipartRequest.fields['reason'] = request.reason;
      multipartRequest.fields['is_half_day'] = request.isHalfDay.toString();

      /*// Add list of managers using the key 'managers' as overwritten and send the last one only
      for (int i = 0; i < request.managerIds.length; i++) {
        multipartRequest.fields['managers'] = request.managerIds[i];
      }*/

     /* manager ID is send in a repeated key way
      for (var managerId in request.managerIds) {
        multipartRequest.fields.addAll({'managers': managerId});
      }*/

      // Add list of managers as comma-separated string
      if (request.managerIds.isNotEmpty) {
        multipartRequest.fields['managers'] = request.managerIds.join(',');
      }



      // Optional fields
      if (request.halfDaySession != null) {
        multipartRequest.fields['half_day_session'] = request.halfDaySession!;
      }
      if (request.startTime != null && request.startTime!.isNotEmpty) {
        multipartRequest.fields['start_time'] = request.startTime!;
        if (request.endTime != null && request.endTime!.isNotEmpty) {
          multipartRequest.fields['end_time'] = request.endTime!;
        }
      }
      // If startTime is null or empty, do not send start_time or end_time fields at all
      else {
        multipartRequest.fields['start_time'] = '';
        multipartRequest.fields['end_time'] = '';
      }

      // Add attachment if it exists
      if (request.attachment != null) {
        multipartRequest.files.add(
          await http.MultipartFile.fromPath(
            'attachment',
            request.attachment!.path,
          ),
        );
      }
      
      print('[POST] ${multipartRequest.url}');
      print('Headers: ${multipartRequest.headers}');
      print('Fields: ${multipartRequest.fields}');

      final response = await multipartRequest.send();
      final responseBody = await response.stream.bytesToString();
      print('Response: \\${response.statusCode} \\$responseBody');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return NetworkSuccess(json.decode(responseBody));
      } else {
        return NetworkError(response.statusCode, responseBody);
      }
    } catch (e) {
      return NetworkError(-1, 'An error occurred: $e');
    }
  }

  Future<NetworkResult<List<LeaveResponse>>> fetchLeaveApplications() async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    try {
      var uri = Uri.parse('${_networkClient.baseUrl}leave/leave-history/');
      // Log API request details
      print('Hitting API: $uri');
      print('Headers: {"Authorization: Bearer $token","Accept: application/json",}');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'X-CSRFTOKEN': 'euRQJVDZBX8y5dhzWQZA4ig4knJTwag88YnsMB1b24QtpK1xlyYvGgRTNaQasgIK', // Add CSRF Token
        },
      );
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<LeaveResponse> leaveRequests = data.map((item) {
          return LeaveResponse(
            id: item['id'].toString(),
            dateRange: DateTimeRange(
              start: DateTime.parse(item['start_date']),
              end: DateTime.parse(item['end_date']),
            ),
            leaveType: item['leave_type'].toString(), // You may want to map this to name if available
            reason: item['reason'] ?? '',
            hr: item['hr_details'] != null ? '${item['hr_details']['first_name']} ${item['hr_details']['last_name']}' : '',
            teamLead: item['manager_details'] != null && item['manager_details'].isNotEmpty
              ? '${item['manager_details'][0]['first_name']} ${item['manager_details'][0]['last_name']}'
              : '',
            status: item['status'] ?? '',
            appliedDate: DateTime.parse(item['applied_at']),
            processedDate: null, // Not available in response
            managerComment: null, // Not available in response
            totalDays: double.tryParse(item['total_days'].toString()) ?? 1.0,
            shortLeaveTime: item['start_time'] != null && item['end_time'] != null
              ? '${item['start_time']} - ${item['end_time']}'
              : null,
            halfDayType: item['half_day_session'],
            attachmentPath: item['attachment'],
            leaveTypeName: item['leave_type_name'].toString(), // You may want to map this to name if available

          );
        }).toList();
        return NetworkSuccess(leaveRequests);
      } else {
        return NetworkError(response.statusCode,'Failed to fetch leave applications');
      }
    } catch (e) {
      return NetworkError(-1, e.toString());
    }
  }

  Future<NetworkResult<void>> withdrawLeave(String leaveId) async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    try {
      var uri = Uri.parse('${_networkClient.baseUrl}leave/leave-applications/$leaveId/');
      print('[DELETE] $uri');
      print('Headers: {Authorization: Bearer $token, Accept: application/json}');
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          // Add CSRF token if required by backend
        },
      );
      print('Response: ${response.statusCode} ${response.body}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return NetworkSuccess(null);
      } else {
        return NetworkError(response.statusCode, response.body);
      }
    } catch (e) {
      return NetworkError(-1, 'An error occurred: $e');
    }
  }

  Future<NetworkResult<dynamic>> updateLeave(String leaveId, LeaveApplyRequest request) async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    try {
      var uri = Uri.parse('${_networkClient.baseUrl}leave/leave-applications/$leaveId/');
      var multipartRequest = http.MultipartRequest('PATCH', uri)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'X-CSRFTOKEN': 'dOcX7diDSJM2H2XQXatOKGUhnMYyTFm2xUHYr1pfOkKzrrB4rGQQpc3H09ayVAMz',
        });

      multipartRequest.fields['start_date'] = DateFormat('yyyy-MM-dd').format(request.startDate);
      multipartRequest.fields['end_date'] = DateFormat('yyyy-MM-dd').format(request.endDate);
      multipartRequest.fields['hr'] = request.hrId;
      multipartRequest.fields['leave_type'] = request.leaveTypeId;
      multipartRequest.fields['reason'] = request.reason;
      multipartRequest.fields['is_half_day'] = request.isHalfDay ? 'true' : '';
      for (int i = 0; i < request.managerIds.length; i++) {
        multipartRequest.fields['managers'] = request.managerIds[i];
      }
      if (request.halfDaySession != null) {
        multipartRequest.fields['half_day_session'] = request.halfDaySession!;
      }
      if (request.startTime != null && request.startTime!.isNotEmpty) {
        multipartRequest.fields['start_time'] = request.startTime!;
        if (request.endTime != null && request.endTime!.isNotEmpty) {
          multipartRequest.fields['end_time'] = request.endTime!;
        }
      }
      // If startTime is null or empty, do not send start_time or end_time fields at all
      else {
        multipartRequest.fields['start_time'] = '';
        multipartRequest.fields['end_time'] = '';
      }
      if (request.attachment != null) {
        multipartRequest.files.add(
          await http.MultipartFile.fromPath(
            'attachment',
            request.attachment!.path,
          ),
        );
      } else {
        multipartRequest.fields['attachment'] = '';
      }
      print('[PATCH] ${multipartRequest.url}');
      print('Headers: ${multipartRequest.headers}');
      print('Fields: ${multipartRequest.fields}');
      final response = await multipartRequest.send();
      final responseBody = await response.stream.bytesToString();
      print('Response: ${response.statusCode} $responseBody');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return NetworkSuccess(json.decode(responseBody));
      } else {
        return NetworkError(response.statusCode, responseBody);
      }
    } catch (e) {
      return NetworkError(-1, 'An error occurred: $e');
    }
  }
}
