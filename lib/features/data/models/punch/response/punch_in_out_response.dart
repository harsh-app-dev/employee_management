import 'dart:convert';

PunchInOutResponse punchResponseFromJson(String str) => PunchInOutResponse.fromJson(json.decode(str));
String punchResponseToJson(PunchInOutResponse data) => json.encode(data.toJson());
class PunchInOutResponse {
  PunchInOutResponse({
      String? message,}){
    _message = message;
}

  PunchInOutResponse.fromJson(dynamic json) {
    _message = json['message'];
  }
  String? _message;
PunchInOutResponse copyWith({  String? message,
}) => PunchInOutResponse(  message: message ?? _message,
);
  String? get message => _message;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = _message;
    return map;
  }
}