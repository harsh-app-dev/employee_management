import 'dart:convert';

ProfileResponse profileResponseFromJson(String str) =>
    ProfileResponse.fromJson(json.decode(str));

String profileResponseToJson(ProfileResponse data) =>
    json.encode(data.toJson());

class ProfileResponse {
  ProfileResponse({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? dateOfBirth,
    String? contactNumber,
    String? designation,
    String? organization,
    String? employeeActive,
  }) {
    _id = id;
    _firstName = firstName;
    _lastName = lastName;
    _email = email;
    _dateOfBirth = dateOfBirth;
    _contactNumber = contactNumber;
    _designation = designation;
    _organization = organization;
    _employeeActive = employeeActive;
  }

  ProfileResponse.fromJson(dynamic json) {
    _id = json['id'];
    _firstName = json['first_name'];
    _lastName = json['last_name'];
    _email = json['email'];
    _dateOfBirth = json['date_of_birth'];
    _contactNumber = json['contact_number'];
    _designation = json['designation'] != null ? json['designation'].toString() : null;
    _organization = json['Organisation'] != null ? json['Organisation'].toString() : null;
    _employeeActive = json['employee_active'] != null ? json['employee_active'].toString() : null;
  }

  String? _id;
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _dateOfBirth;
  String? _contactNumber;
  String? _designation;
  String? _organization;
  String? _employeeActive;

  ProfileResponse copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? dateOfBirth,
    String? contactNumber,
    String? designation,
    String? organization,
    String? employeeActive,
  }) => ProfileResponse(
    id: id ?? _id,
    firstName: firstName ?? _firstName,
    lastName: lastName ?? _lastName,
    email: email ?? _email,
    dateOfBirth: dateOfBirth ?? _dateOfBirth,
    contactNumber: contactNumber ?? _contactNumber,
    designation: designation ?? _designation,
    organization: organization ?? _organization,
    employeeActive: employeeActive ?? _employeeActive,
  );

  String? get id => _id;

  String? get firstName => _firstName;

  String? get lastName => _lastName;

  String? get email => _email;

  String? get dateOfBirth => _dateOfBirth;

  String? get contactNumber => _contactNumber;

  String? get designation => _designation;

  String? get organization => _organization;

  String? get employeeActive => _employeeActive;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['first_name'] = _firstName;
    map['last_name'] = _lastName;
    map['email'] = _email;
    map['date_of_birth'] = _dateOfBirth;
    map['contact_number'] = _contactNumber;
    map['designation'] = _designation;
    map['Organization'] = _organization;
    map['employee_active'] = _employeeActive;

    return map;
  }
}
