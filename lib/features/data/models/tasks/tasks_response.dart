import 'dart:convert';

TasksResponse tasksResponseFromJson(String str) => TasksResponse.fromJson(json.decode(str));
String tasksResponseToJson(TasksResponse data) => json.encode(data.toJson());
class TasksResponse {
  TasksResponse({
      String? id, 
      String? organizationPrefix, 
      String? updatedAt, 
      String? taskPhase, 
      bool? isCompleted, 
      bool? isVerified, 
      bool? isDeleted, 
      bool? isEdited, 
      String? taskDescription, 
      String? createdAt, 
      String? taskTimeSpend, 
      String? totalHours, 
      String? parentTask, 
      String? user, 
      num? ticket,}){
    _id = id;
    _organizationPrefix = organizationPrefix;
    _updatedAt = updatedAt;
    _taskPhase = taskPhase;
    _isCompleted = isCompleted;
    _isVerified = isVerified;
    _isDeleted = isDeleted;
    _isEdited = isEdited;
    _taskDescription = taskDescription;
    _createdAt = createdAt;
    _taskTimeSpend = taskTimeSpend;
    _totalHours = totalHours;
    _parentTask = parentTask;
    _user = user;
    _ticket = ticket;
}

  TasksResponse.fromJson(dynamic json) {
    _id = json['id'];
    _organizationPrefix = json['organization_prefix'];
    _updatedAt = json['updated_at'];
    _taskPhase = json['task_phase'];
    _isCompleted = json['is_completed'];
    _isVerified = json['is_verified'];
    _isDeleted = json['is_deleted'];
    _isEdited = json['is_edited'];
    _taskDescription = json['task_description'];
    _createdAt = json['created_at'];
    _taskTimeSpend = json['task_time_spend'];
    _totalHours = json['total_hours'];
    _parentTask = json['parent_task'];
    _user = json['user'];
    _ticket = json['ticket'];
  }
  String? _id;
  String? _organizationPrefix;
  String? _updatedAt;
  String? _taskPhase;
  bool? _isCompleted;
  bool? _isVerified;
  bool? _isDeleted;
  bool? _isEdited;
  String? _taskDescription;
  String? _createdAt;
  String? _taskTimeSpend;
  String? _totalHours;
  String? _parentTask;
  String? _user;
  num? _ticket;
TasksResponse copyWith({  String? id,
  String? organizationPrefix,
  String? updatedAt,
  String? taskPhase,
  bool? isCompleted,
  bool? isVerified,
  bool? isDeleted,
  bool? isEdited,
  String? taskDescription,
  String? createdAt,
  String? taskTimeSpend,
  String? totalHours,
  String? parentTask,
  String? user,
  num? ticket,
}) => TasksResponse(  id: id ?? _id,
  organizationPrefix: organizationPrefix ?? _organizationPrefix,
  updatedAt: updatedAt ?? _updatedAt,
  taskPhase: taskPhase ?? _taskPhase,
  isCompleted: isCompleted ?? _isCompleted,
  isVerified: isVerified ?? _isVerified,
  isDeleted: isDeleted ?? _isDeleted,
  isEdited: isEdited ?? _isEdited,
  taskDescription: taskDescription ?? _taskDescription,
  createdAt: createdAt ?? _createdAt,
  taskTimeSpend: taskTimeSpend ?? _taskTimeSpend,
  totalHours: totalHours ?? _totalHours,
  parentTask: parentTask ?? _parentTask,
  user: user ?? _user,
  ticket: ticket ?? _ticket,
);
  String? get id => _id;
  String? get organizationPrefix => _organizationPrefix;
  String? get updatedAt => _updatedAt;
  String? get taskPhase => _taskPhase;
  bool? get isCompleted => _isCompleted;
  bool? get isVerified => _isVerified;
  bool? get isDeleted => _isDeleted;
  bool? get isEdited => _isEdited;
  String? get taskDescription => _taskDescription;
  String? get createdAt => _createdAt;
  String? get taskTimeSpend => _taskTimeSpend;
  String? get totalHours => _totalHours;
  String? get parentTask => _parentTask;
  String? get user => _user;
  num? get ticket => _ticket;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['organization_prefix'] = _organizationPrefix;
    map['updated_at'] = _updatedAt;
    map['task_phase'] = _taskPhase;
    map['is_completed'] = _isCompleted;
    map['is_verified'] = _isVerified;
    map['is_deleted'] = _isDeleted;
    map['is_edited'] = _isEdited;
    map['task_description'] = _taskDescription;
    map['created_at'] = _createdAt;
    map['task_time_spend'] = _taskTimeSpend;
    map['total_hours'] = _totalHours;
    map['parent_task'] = _parentTask;
    map['user'] = _user;
    map['ticket'] = _ticket;
    return map;
  }
}