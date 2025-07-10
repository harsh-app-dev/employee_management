import 'dart:convert';

TaskHistoryResponse taskHistoryResponseFromJson(String str) =>
    TaskHistoryResponse.fromJson(json.decode(str));

String taskHistoryResponseToJson(TaskHistoryResponse data) => json.encode(data.toJson());

class TaskHistoryResponse {
  TaskHistoryResponse({Map<String, List<TaskHistoryData>>? data}) {
    _data = data;
  }

  TaskHistoryResponse.fromJson(dynamic json) {
    if (json != null) {
      _data = <String, List<TaskHistoryData>>{};
      json.forEach((key, value) {
        if (value is List) {
          _data![key] = value.map((v) => TaskHistoryData.fromJson(v)).toList();
        }
      });
    }
  }

  Map<String, List<TaskHistoryData>>? _data;

  TaskHistoryResponse copyWith({Map<String, List<TaskHistoryData>>? data}) => TaskHistoryResponse(
    data: data ?? _data,
  );

  Map<String, List<TaskHistoryData>>? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      _data!.forEach((key, value) {
        map[key] = value.map((v) => v.toJson()).toList();
      });
    }
    return map;
  }
}

class TaskHistoryData {
  TaskHistoryData({
    String? id,
    String? ticketTitle,
    String? projectTitle,
    String? updatedAt,
    String? taskPhase,
    bool? isCompleted,
    bool? isVerified,
    bool? isDeleted,
    bool? isEdited,
    String? taskDescription,
    String? createdAt,
    String? taskTimeSpend,
    String? taskCreatedDate,
    String? totalHours,
    String? parentTask,
    String? user,
    dynamic ticket,
    List<dynamic>? updatedTask,
  })  : _id = id,
        _ticketTitle = ticketTitle,
        _projectTitle = projectTitle,
        _updatedAt = updatedAt,
        _taskPhase = taskPhase,
        _isCompleted = isCompleted,
        _isVerified = isVerified,
        _isDeleted = isDeleted,
        _isEdited = isEdited,
        _taskDescription = taskDescription,
        _createdAt = createdAt,
        _taskTimeSpend = taskTimeSpend,
        _taskCreatedDate = taskCreatedDate,
        _totalHours = totalHours,
        _parentTask = parentTask,
        _user = user,
        _ticket = ticket,
        _updatedTask = updatedTask;

  TaskHistoryData.fromJson(dynamic json) {
    _id = json['id'];
    _ticketTitle = json['ticket_title'];
    _projectTitle = json['project_title'];
    _updatedAt = json['updated_at'];
    _taskPhase = json['task_phase'];
    _isCompleted = json['is_completed'];
    _isVerified = json['is_verified'];
    _isDeleted = json['is_deleted'];
    _isEdited = json['is_edited'];
    _taskDescription = json['task_description'];
    _createdAt = json['created_at'];
    _taskTimeSpend = json['task_time_spend'];
    _taskCreatedDate = json['task_created_date'];
    _totalHours = json['total_hours'];
    _parentTask = json['parent_task']?.toString();
    _user = json['user']?.toString();
    _ticket = json['ticket'];
    if (json['updated_task'] != null) {
      _updatedTask = [];
      json['updated_task'].forEach((v) {
        _updatedTask!.add(v);
      });
    }
  }

  String? _id;
  String? _ticketTitle;
  String? _projectTitle;
  String? _updatedAt;
  String? _taskPhase;
  bool? _isCompleted;
  bool? _isVerified;
  bool? _isDeleted;
  bool? _isEdited;
  String? _taskDescription;
  String? _createdAt;
  String? _taskTimeSpend;
  String? _taskCreatedDate;
  String? _totalHours;
  String? _parentTask;
  String? _user;
  dynamic _ticket;
  List<dynamic>? _updatedTask;

  TaskHistoryData copyWith({
    String? id,
    String? ticketTitle,
    String? projectTitle,
    String? updatedAt,
    String? taskPhase,
    bool? isCompleted,
    bool? isVerified,
    bool? isDeleted,
    bool? isEdited,
    String? taskDescription,
    String? createdAt,
    String? taskTimeSpend,
    String? taskCreatedDate,
    String? totalHours,
    String? parentTask,
    String? user,
    dynamic ticket,
    List<dynamic>? updatedTask,
  }) => TaskHistoryData(
    id: id ?? _id,
    ticketTitle: ticketTitle ?? _ticketTitle,
    projectTitle: projectTitle ?? _projectTitle,
    updatedAt: updatedAt ?? _updatedAt,
    taskPhase: taskPhase ?? _taskPhase,
    isCompleted: isCompleted ?? _isCompleted,
    isVerified: isVerified ?? _isVerified,
    isDeleted: isDeleted ?? _isDeleted,
    isEdited: isEdited ?? _isEdited,
    taskDescription: taskDescription ?? _taskDescription,
    createdAt: createdAt ?? _createdAt,
    taskTimeSpend: taskTimeSpend ?? _taskTimeSpend,
    taskCreatedDate: taskCreatedDate ?? _taskCreatedDate,
    totalHours: totalHours ?? _totalHours,
    parentTask: parentTask ?? _parentTask,
    user: user ?? _user,
    ticket: ticket ?? _ticket,
    updatedTask: updatedTask ?? _updatedTask,
  );

  String? get id => _id;
  String? get ticketTitle => _ticketTitle;
  String? get projectTitle => _projectTitle;
  String? get updatedAt => _updatedAt;
  String? get taskPhase => _taskPhase;
  bool? get isCompleted => _isCompleted;
  bool? get isVerified => _isVerified;
  bool? get isDeleted => _isDeleted;
  bool? get isEdited => _isEdited;
  String? get taskDescription => _taskDescription;
  String? get createdAt => _createdAt;
  String? get taskTimeSpend => _taskTimeSpend;
  String? get taskCreatedDate => _taskCreatedDate;
  String? get totalHours => _totalHours;
  String? get parentTask => _parentTask;
  String? get user => _user;
  dynamic get ticket => _ticket;
  List<dynamic>? get updatedTask => _updatedTask;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['ticket_title'] = _ticketTitle;
    map['project_title'] = _projectTitle;
    map['updated_at'] = _updatedAt;
    map['task_phase'] = _taskPhase;
    map['is_completed'] = _isCompleted;
    map['is_verified'] = _isVerified;
    map['is_deleted'] = _isDeleted;
    map['is_edited'] = _isEdited;
    map['task_description'] = _taskDescription;
    map['created_at'] = _createdAt;
    map['task_time_spend'] = _taskTimeSpend;
    map['task_created_date'] = _taskCreatedDate;
    map['total_hours'] = _totalHours;
    map['parent_task'] = _parentTask;
    map['user'] = _user;
    map['ticket'] = _ticket;
    if (_updatedTask != null) {
      map['updated_task'] = _updatedTask;
    }
    return map;
  }
} 