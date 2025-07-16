import 'dart:convert';

PunchInOutRequest punchInOutRequestFromJson(String str) => PunchInOutRequest.fromJson(json.decode(str));
String punchInOutRequestToJson(PunchInOutRequest data) => json.encode(data.toJson());

class PunchInOutRequest {
  String? punchInPhoto;
  String? punchOutPhoto;
  String? punchedInLatLong;
  String? punchedOutLatLong;
  String? punchIn;
  String? punchOut;
  int? attendance;

  PunchInOutRequest({
    this.punchInPhoto,
    this.punchOutPhoto,
    this.punchedInLatLong,
    this.punchedOutLatLong,
    this.punchIn,
    this.punchOut,
    this.attendance,
  });

  factory PunchInOutRequest.fromJson(Map<String, dynamic> json) => PunchInOutRequest(
    punchInPhoto: json['punch_in_photo'],
    punchOutPhoto: json['punch_out_photo'],
    punchedInLatLong: json['punched_in_lat_long'],
    punchedOutLatLong: json['punched_out_lat_long'],
    punchIn: json['punch_in'],
    punchOut: json['punch_out'],
    attendance: json['attendance'],
  );

  Map<String, dynamic> toJson() => {
    'punch_in_photo': punchInPhoto,
    'punch_out_photo': punchOutPhoto,
    'punched_in_lat_long': punchedInLatLong,
    'punched_out_lat_long': punchedOutLatLong,
    'punch_in': punchIn,
    'punch_out': punchOut,
    'attendance': attendance,
  };
}