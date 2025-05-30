import 'dart:convert';

SubmitTaskRequest submitTaskRequestFromJson(String str) =>
    SubmitTaskRequest.fromJson(json.decode(str));

String submitTaskRequestToJson(SubmitTaskRequest data) =>
    json.encode(data.toJson());

class SubmitTaskRequest {
  SubmitTaskRequest({List<String>? taskIds, String? status = ""}) {
    _taskUuids = taskIds;
    _status = status;
  }

  SubmitTaskRequest.fromJson(dynamic json) {
    _taskUuids = json['task_uuids'] != null
        ? json['task_uuids'].cast<String>()
        : [];
    _status = json['status'];
  }

  List<String>? _taskUuids;
  String? _status;

  SubmitTaskRequest copyWith({List<String>? taskUuids, String? status}) =>
      SubmitTaskRequest(
        taskIds: taskUuids ?? _taskUuids,
        status: status ?? _status,
      );

  List<String>? get taskUuids => _taskUuids;

  String? get status => _status;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['task_uuids'] = _taskUuids;
    map['status'] = _status;
    return map;
  }
}
