import 'dart:convert';
/// message : "Punched out successfully."

PunchResponse punchResponseFromJson(String str) => PunchResponse.fromJson(json.decode(str));
String punchResponseToJson(PunchResponse data) => json.encode(data.toJson());
class PunchResponse {
  PunchResponse({
      String? message,}){
    _message = message;
}

  PunchResponse.fromJson(dynamic json) {
    _message = json['message'];
  }
  String? _message;
PunchResponse copyWith({  String? message,
}) => PunchResponse(  message: message ?? _message,
);
  String? get message => _message;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = _message;
    return map;
  }

}