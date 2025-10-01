import 'package:employee_management/features/data/models/leave/leave_balance_response.dart';
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
import '../models/leave/leave_approval_request.dart';
import '../models/leave/leave_response.dart';
import '../models/leave/leave_status_update.dart';

@injectable
class LeaveRepository {
  final NetworkClient _networkClient;
  final LocalStorage _localStorage;

  LeaveRepository(this._networkClient, this._localStorage);

  Future<NetworkResult<List<LeaveType>>> fetchLeaveTypes() async {
    return await _networkClient.get<List<LeaveType>>(
      'leave/leave-types/',
      parser: (json) {
        // 'data' contains the list of leave types
        final leaveTypes = (json['data'] as List)
            .map((e) => LeaveType.fromJson(e))
            .toList();
        return leaveTypes;
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
      print('[POST] $uri');
      print('Headers: {Authorization: Bearer $token, Accept: application/json}');
      var multipartRequest = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'X-CSRFTOKEN': 'euRQJVDZBX8y5dhzWQZA4ig4knJTwag88YnsMB1b24QtpK1xlyYvGgRTNaQasgIK',
        });

      multipartRequest.fields['leave_type'] = request.leaveType.toString();
      multipartRequest.fields['from_date'] = DateFormat('yyyy-MM-dd').format(request.fromDate);
      multipartRequest.fields['to_date'] = DateFormat('yyyy-MM-dd').format(request.toDate);
      multipartRequest.fields['hr'] = request.hr;
      multipartRequest.fields['reason'] = request.reason;
      multipartRequest.fields['managers'] = request.managers.join(',');
      // Send from_time as timestamp
      if (request.fromTime != null && request.fromTime!.isNotEmpty) {
        final timeParts = request.fromTime!.split(':');
        final dt = DateTime(
          request.fromDate.year,
          request.fromDate.month,
          request.fromDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
        multipartRequest.fields['from_time'] = (dt.millisecondsSinceEpoch ~/ 1000).toString();
      }
      // Send to_time as timestamp
      if (request.toTime != null && request.toTime!.isNotEmpty) {
        final timeParts = request.toTime!.split(':');
        final dt = DateTime(
          request.toDate.year,
          request.toDate.month,
          request.toDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
        multipartRequest.fields['to_time'] = (dt.millisecondsSinceEpoch ~/ 1000).toString();
      }
      if (request.attachment != null) {
        multipartRequest.files.add(await http.MultipartFile.fromPath('attachment', request.attachment!.path));
      }
      multipartRequest.fields['status'] = 'Pending';

      print('Request Body: ${multipartRequest.fields} ${multipartRequest.files.map((f) => {'field': f.field, 'file': f.filename}).toList()}');

      final streamedResponse = await multipartRequest.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return NetworkSuccess(jsonDecode(response.body));
      } else {
        return NetworkError(response.statusCode, 'Failed to apply leave: ${response.body}');
      }
    } catch (e) {
      return NetworkError(-1, 'Exception: $e');
    }
  }

  Future<NetworkResult<List<LeaveResponse>>> fetchLeaveApplications() async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);

    try {
      final uri = Uri.parse('${_networkClient.baseUrl}leave/leave-history/');

      print('[GET] $uri');
      print('Headers: {Authorization: Bearer $token, Accept: application/json}');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'X-CSRFTOKEN': 'euRQJVDZBX8y5dhzWQZA4ig4knJTwag88YnsMB1b24QtpK1xlyYvGgRTNaQasgIK',
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is! List) {
          return NetworkError(-1, 'Invalid response format: Expected a list');
        }

        final leaveRequests = decoded.map<LeaveResponse>((item) {
          return LeaveResponse(
            id: item['id']?.toString() ?? '',
            leaveType: item['leave_type'] is int
                ? item['leave_type']
                : int.tryParse(item['leave_type']?.toString() ?? '0') ?? 0,
            leaveTypeName: item['leave_type_name']?.toString() ?? '',
            fromTime: item['from_time'] != null ? item['from_time'].toString() : null,
            toTime: item['to_time'] != null ? item['to_time'].toString() : null,
            fromDate: item['from_date']?.toString() ?? '',
            toDate: item['to_date']?.toString() ?? '',
            appliedDate: item['applied_date']?.toString() ?? '',
            managers: (item['managers'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
                [],
            hr: item['hr']?.toString() ?? '',
            reason: item['reason']?.toString() ?? '',
            status: item['status']?.toString() ?? '',
            attachment: item['attachment'] != null ? item['attachment'].toString() : null,
            managerDetails: (item['manager_details'] as List<dynamic>? ?? [])
                .map((e) => ManagerDetails.fromJson(e as Map<String, dynamic>))
                .toList(),
            userDetails: UserDetails.fromJson(
                item['user_details'] as Map<String, dynamic>? ?? {}),
            managerComment: (item['manager_comments'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
                [],
          );
        }).toList();

        print('Filtered leaves count: ${leaveRequests.length}');
        return NetworkSuccess(leaveRequests);
      } else {
        return NetworkError(
          response.statusCode,
          'Failed to fetch leave applications (${response.reasonPhrase})',
        );
      }
    } catch (e, stack) {
      print('Exception: $e');
      print(stack);
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
      print('[PUT] $uri');
      print('Headers: {Authorization: Bearer $token, Accept: application/json}');

      var multipartRequest = http.MultipartRequest('PUT', uri)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'X-CSRFTOKEN': 'euRQJVDZBX8y5dhzWQZA4ig4knJTwag88YnsMB1b24QtpK1xlyYvGgRTNaQasgIK',
        });

      multipartRequest.fields['leave_type'] = request.leaveType.toString();
      multipartRequest.fields['from_date'] = DateFormat('yyyy-MM-dd').format(request.fromDate);
      multipartRequest.fields['to_date'] = DateFormat('yyyy-MM-dd').format(request.toDate);
      multipartRequest.fields['hr'] = request.hr;
      multipartRequest.fields['reason'] = request.reason;
      multipartRequest.fields['managers'] = request.managers.join(',');

      // Improved timestamp calculation with timezone awareness
      if (request.fromTime != null && request.fromTime!.isNotEmpty) {
        final timeParts = request.fromTime!.split(':');
        final dt = DateTime(
          request.fromDate.year,
          request.fromDate.month,
          request.fromDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
        // Use UTC to avoid timezone issues
        final utcDt = dt.toUtc();
        multipartRequest.fields['from_time'] = (utcDt.millisecondsSinceEpoch ~/ 1000).toString();
      }

      if (request.toTime != null && request.toTime!.isNotEmpty) {
        final timeParts = request.toTime!.split(':');
        final dt = DateTime(
          request.toDate.year,
          request.toDate.month,
          request.toDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
        // Use UTC to avoid timezone issues
        final utcDt = dt.toUtc();
        multipartRequest.fields['to_time'] = (utcDt.millisecondsSinceEpoch ~/ 1000).toString();
      }

      // FIX: Only add attachment if it's a new file and exists
      if (request.attachment != null && await request.attachment!.exists()) {
        try {
          multipartRequest.files.add(
              await http.MultipartFile.fromPath('attachment', request.attachment!.path)
          );
          print('Adding attachment: ${request.attachment!.path}');
        } catch (e) {
          print('Warning: Could not attach file: $e');
          // Continue without attachment rather than failing
        }
      } else {
        print('No attachment provided or file does not exist');
      }

      multipartRequest.fields['status'] = 'Pending';

      print('Request Body: ${multipartRequest.fields} ${multipartRequest.files.map((f) => {'field': f.field, 'file': f.filename}).toList()}');

      final streamedResponse = await multipartRequest.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        return NetworkSuccess(jsonDecode(response.body));
      } else {
        return NetworkError(response.statusCode, 'Failed to update leave: ${response.body}');
      }
    } catch (e) {
      return NetworkError(-1, 'Exception: $e');
    }
  }

  Future<NetworkResult<List<LeaveApprovalRequest>>> fetchLeaveApprovalRequests() async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);

    try {
      final uri = Uri.parse('${_networkClient.baseUrl}leave/leave-requests/');

      print('[GET] $uri');
      print('Headers: {Authorization: Bearer $token, Accept: application/json}');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'X-CSRFTOKEN': 'euRQJVDZBX8y5dhzWQZA4ig4knJTwag88YnsMB1b24QtpK1xlyYvGgRTNaQasgIK',
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is! List) {
          return NetworkError(-1, 'Invalid response format: Expected a list');
        }

        final leaveRequests = decoded.map<LeaveApprovalRequest>((item) {
          return LeaveApprovalRequest(
            id: item['id']?.toString() ?? '',
            requestedBy: item['requested_by']?.toString() ?? '',
            leaveType: item['leave_type'] ?? 0, // int
            fromDate: item['from_date']?.toString() ?? '',
            toDate: item['to_date']?.toString() ?? '',
            fromTime: item['from_time'] != null ? int.tryParse(item['from_time'].toString()) : null,
            toTime: item['to_time'] != null ? int.tryParse(item['to_time'].toString()) : null,
            reason: item['reason']?.toString() ?? '',
            attachment: item['attachment'] != null ? item['attachment'].toString() : null,
            status: item['status']?.toString() ?? '',
            leaveTypeName: item['leave_type_name']?.toString() ?? '',

          );
        }).toList();

        return NetworkSuccess(leaveRequests);
      } else {
        return NetworkError(
          response.statusCode,
          'Failed to fetch leave applications (${response.reasonPhrase})',
        );
      }
    } catch (e, stack) {
      print('Exception: $e');
      print(stack);
      return NetworkError(-1, e.toString());
    }
  }

  Future<NetworkResult<void>> updateLeaveStatus({
    required String leaveId,
    required String action,
    required String comments,
  }) async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);

    try {
      final uri = Uri.parse('${_networkClient.baseUrl}leave/leave-approve/$leaveId/');
      print('[POST] $uri');
      print('Headers: {Authorization: Bearer $token, Accept: application/json}');

      final body = LeaveStatusUpdate(action: action, comments: comments).toJson();

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-CSRFTOKEN': 'euRQJVDZBX8y5dhzWQZA4ig4knJTwag88YnsMB1b24QtpK1xlyYvGgRTNaQasgIK',
        },
        body: jsonEncode(body),
      );

      print('Response: ${response.statusCode} ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return NetworkSuccess(null);
      } else {
        return NetworkError(response.statusCode, 'Failed to update leave status: ${response.body}');
      }
    } catch (e) {
      return NetworkError(-1, 'Exception: $e');
    }
  }

  Future<NetworkResult<LeaveBalance>> fetchLeaveBalance() async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    return await _networkClient.get<LeaveBalance>(
      "leave/leave-balance/",
      headers: {"Authorization": "Bearer $token"},
      parser: (json) => LeaveBalance.fromJson(json),
    );
  }
}
