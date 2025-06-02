import 'dart:convert';
/// message : "String"

SubmitTasksResponse submitTasksResponseFromJson(String str) => SubmitTasksResponse.fromJson(json.decode(str));
String submitTasksResponseToJson(SubmitTasksResponse data) => json.encode(data.toJson());
class SubmitTasksResponse {
  SubmitTasksResponse({
      String? message,}){
    _message = message;
}

  SubmitTasksResponse.fromJson(dynamic json) {
    _message = json['message'];
  }
  String? _message;
SubmitTasksResponse copyWith({  String? message,
}) => SubmitTasksResponse(  message: message ?? _message,
);
  String? get message => _message;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = _message;
    return map;
  }

}