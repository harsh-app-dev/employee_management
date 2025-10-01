import 'dart:convert';

TaskResponse taskResponseFromJson(String str) =>
    TaskResponse.fromJson(json.decode(str));

String taskResponseToJson(TaskResponse data) => json.encode(data.toJson());

class TaskResponse {
  TaskResponse({List<Data>? data, bool? submitTask, bool? canSubmit}) {
    _data = data;
    _submitTask = submitTask;
    _canSubmit = canSubmit;
  }

  TaskResponse.fromJson(dynamic json) {

    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(Data.fromJson(v));
      });
      // Sort so that isEdited == true are at the end
      _data?.sort((a, b) {
        if ((a.isEdited == true) && (b.isEdited != true)) return 1;
        if ((a.isEdited != true) && (b.isEdited == true)) return -1;
        return 0;
      });
    }
    _submitTask = json['submit_task'];
    _canSubmit = json['can_submit'];
  }

  List<Data>? _data;
  bool? _submitTask;
  bool? _canSubmit;

  TaskResponse copyWith({
    List<Data>? data,
    bool? submitTask,
    bool? canSubmit,
  }) => TaskResponse(
    data: data ?? _data,
    submitTask: submitTask ?? _submitTask,
    canSubmit: canSubmit ?? _canSubmit,
  );

  List<Data>? get data => _data;

  bool? get submitTask => _submitTask;

  bool? get canSubmit => _canSubmit;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    map['submit_task'] = _submitTask;
    map['can_submit'] = _canSubmit;
    return map;
  }
}

Data dataFromJson(String str) => Data.fromJson(json.decode(str));

String dataToJson(Data data) => json.encode(data.toJson());

class Data {
  Data({
    String? id,
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
    Ticket? ticket,
    int? ticketId,
    String? ticketTitle,
    String? projectTitle,
    String? taskCreatedDate,
    String? parentTask,
    String? user,
    String? updatedTask,
  })  : _id = id,
        _updatedAt = updatedAt,
        _taskPhase = taskPhase,
        _isCompleted = isCompleted,
        _isVerified = isVerified,
        _isDeleted = isDeleted,
        _isEdited = isEdited,
        _taskDescription = taskDescription,
        _createdAt = createdAt,
        _taskTimeSpend = taskTimeSpend,
        _totalHours = totalHours,
        _ticket = ticket,
        _ticketId = ticketId,
        _ticketTitle = ticketTitle,
        _projectTitle = projectTitle,
        _taskCreatedDate = taskCreatedDate,
        _parentTask = parentTask,
        _user = user,
        _updatedTask = updatedTask;

  Data.fromJson(dynamic json) {
    _id = json['id'];
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
    if (json['ticket'] is Map) {
      _ticket = Ticket.fromJson(json['ticket']);
      _ticketId = null;
    } else if (json['ticket'] is int) {
      _ticket = null;
      _ticketId = json['ticket'];
    } else {
      _ticket = null;
      _ticketId = null;
    }
    _ticketTitle = json['ticket_title'];
    _projectTitle = json['project_title'];
    _taskCreatedDate = json['task_created_date'];
    _parentTask = json['parent_task']?.toString();
    _user = json['user']?.toString();
    _updatedTask = json['updated_task']?.toString();
  }

  String? _id;
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
  Ticket? _ticket;
  int? _ticketId;
  String? _ticketTitle;
  String? _projectTitle;
  String? _taskCreatedDate;
  String? _parentTask;
  String? _user;
  String? _updatedTask;

  Data copyWith({
    String? id,
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
    Ticket? ticket,
    int? ticketId,
    String? ticketTitle,
    String? projectTitle,
    String? taskCreatedDate,
    String? parentTask,
    String? user,
    String? updatedTask,
  }) => Data(
    id: id ?? _id,
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
    ticket: ticket ?? _ticket,
    ticketId: ticketId ?? _ticketId,
    ticketTitle: ticketTitle ?? _ticketTitle,
    projectTitle: projectTitle ?? _projectTitle,
    taskCreatedDate: taskCreatedDate ?? _taskCreatedDate,
    parentTask: parentTask ?? _parentTask,
    user: user ?? _user,
    updatedTask: updatedTask ?? _updatedTask,
  );

  String? get id => _id;

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

  Ticket? get ticket => _ticket;

  int? get ticketId => _ticketId;

  String? get ticketTitle => _ticketTitle;

  String? get projectTitle => _projectTitle;

  String? get taskCreatedDate => _taskCreatedDate;

  String? get parentTask => _parentTask;

  String? get user => _user;

  String? get updatedTask => _updatedTask;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
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
    if (_ticket != null) {
      map['ticket'] = _ticket?.toJson();
    } else if (_ticketId != null) {
      map['ticket'] = _ticketId;
    }
    map['ticket_title'] = _ticketTitle;
    map['project_title'] = _projectTitle;
    map['task_created_date'] = _taskCreatedDate;
    map['parent_task'] = _parentTask;
    map['user'] = _user;
    map['updated_task'] = _updatedTask;
    return map;
  }
}

class Ticket {
  Ticket({String? title, Project? project})
    : _title = title,
      _project = project;

  Ticket.fromJson(dynamic json) {
    _title = json['title'];
    _project = json['project'] != null
        ? Project.fromJson(json['project'])
        : null;
  }

  String? _title;
  Project? _project;

  String? get title => _title;

  Project? get project => _project;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = _title;
    if (_project != null) {
      map['project'] = _project?.toJson();
    }
    return map;
  }
}

class Project {
  Project({String? title}) : _title = title;

  Project.fromJson(dynamic json) {
    _title = json['title'];
  }

  String? _title;

  String? get title => _title;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = _title;
    return map;
  }
}
