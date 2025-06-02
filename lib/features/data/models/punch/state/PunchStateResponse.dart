import 'dart:convert';

PunchStateResponse punchStateResponseFromJson(String str) => PunchStateResponse.fromJson(json.decode(str));
String punchStateResponseToJson(PunchStateResponse data) => json.encode(data.toJson());
class PunchStateResponse {
  PunchStateResponse({
      String? id, 
      String? firstName, 
      String? lastName, 
      bool? isPunchedIn, 
      bool? isPunchedOut,}){
    _id = id;
    _firstName = firstName;
    _lastName = lastName;
    _isPunchedIn = isPunchedIn;
    _isPunchedOut = isPunchedOut;
}

  PunchStateResponse.fromJson(dynamic json) {
    _id = json['id'];
    _firstName = json['first_name'];
    _lastName = json['last_name'];
    _isPunchedIn = json['is_punched_in'];
    _isPunchedOut = json['is_punched_out'];
  }
  String? _id;
  String? _firstName;
  String? _lastName;
  bool? _isPunchedIn;
  bool? _isPunchedOut;
PunchStateResponse copyWith({  String? id,
  String? firstName,
  String? lastName,
  bool? isPunchedIn,
  bool? isPunchedOut,
}) => PunchStateResponse(  id: id ?? _id,
  firstName: firstName ?? _firstName,
  lastName: lastName ?? _lastName,
  isPunchedIn: isPunchedIn ?? _isPunchedIn,
  isPunchedOut: isPunchedOut ?? _isPunchedOut,
);
  String? get id => _id;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  bool? get isPunchedIn => _isPunchedIn;
  bool? get isPunchedOut => _isPunchedOut;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['first_name'] = _firstName;
    map['last_name'] = _lastName;
    map['is_punched_in'] = _isPunchedIn;
    map['is_punched_out'] = _isPunchedOut;
    return map;
  }

}