import 'dart:convert';

PunchInOutRequest punchInOutRequestFromJson(String str) => PunchInOutRequest.fromJson(json.decode(str));
String punchInOutRequestToJson(PunchInOutRequest data) => json.encode(data.toJson());
class PunchInOutRequest {
  PunchInOutRequest({
      String? punchedInLatLong, 
      String? punchedOutLatLong,}){
    _punchedInLatLong = punchedInLatLong;
    _punchedOutLatLong = punchedOutLatLong;
}

  PunchInOutRequest.fromJson(dynamic json) {
    _punchedInLatLong = json['punched_in_lat_long'];
    _punchedOutLatLong = json['punched_out_lat_long'];
  }
  String? _punchedInLatLong;
  String? _punchedOutLatLong;
PunchInOutRequest copyWith({  String? punchedInLatLong,
  String? punchedOutLatLong,
}) => PunchInOutRequest(  punchedInLatLong: punchedInLatLong ?? _punchedInLatLong,
  punchedOutLatLong: punchedOutLatLong ?? _punchedOutLatLong,
);
  String? get punchedInLatLong => _punchedInLatLong;
  String? get punchedOutLatLong => _punchedOutLatLong;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['punched_in_lat_long'] = _punchedInLatLong;
    map['punched_out_lat_long'] = _punchedOutLatLong;
    return map;
  }

}