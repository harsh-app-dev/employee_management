import 'dart:convert';

PunchInOutRequest punchInOutRequestFromJson(String str) => PunchInOutRequest.fromJson(json.decode(str));
String punchInOutRequestToJson(PunchInOutRequest data) => json.encode(data.toJson());

class PunchInOutRequest {
  final String type; // 'punch_in', 'punch_out', 'break_start', 'break_end'
  String? punchInPhoto;
  String? punchOutPhoto;
  String? punchedInLatLong;
  String? punchedOutLatLong;
  String? punchIn;
  String? punchOut;

  PunchInOutRequest({
    required this.type,
    this.punchInPhoto,
    this.punchOutPhoto,
    this.punchedInLatLong,
    this.punchedOutLatLong,
    this.punchIn,
    this.punchOut,
  });

  factory PunchInOutRequest.fromJson(Map<String, dynamic> json) => PunchInOutRequest(
    type: json['type'],
    punchInPhoto: json['punch_in_photo'],
    punchOutPhoto: json['punch_out_photo'],
    punchedInLatLong: json['punched_in_lat_long'],
    punchedOutLatLong: json['punched_out_lat_long'],
    punchIn: json['punch_in'],
    punchOut: json['punch_out'],
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    if (punchInPhoto != null) 'punch_in_photo': punchInPhoto,
    if (punchOutPhoto != null) 'punch_out_photo': punchOutPhoto,
    if (punchedInLatLong != null) 'punched_in_lat_long': punchedInLatLong,
    if (punchedOutLatLong != null) 'punched_out_lat_long': punchedOutLatLong,
    if (punchIn != null) 'punch_in': punchIn,
    if (punchOut != null) 'punch_out': punchOut,
  };
}