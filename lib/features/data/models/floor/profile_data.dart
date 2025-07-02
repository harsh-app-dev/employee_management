import 'package:floor/floor.dart';

@Entity(tableName: 'profile')
class Profile{
  @primaryKey
  final String id;
  final String first_name;
  final String last_name;
  final String email;
  final String dob;
  final String phoneNo;
  final String designation;
  final String organization;

  Profile({required this.id, required this.first_name, required this.last_name, required this.email, required this.dob, required this.phoneNo, required this.designation, required this.organization});

  factory Profile.fromApi(Map<String, dynamic> json) => Profile(
    id: json['id'] ?? '',
    first_name: json['first_name'] ?? '',
    last_name: json['last_name'] ?? '',
    email: json['email'] ?? '',
    dob: json['date_of_birth'] ?? '',
    phoneNo: json['contact_number'] ?? '',
    designation: json['designation'] != null ? json['designation'].toString() : '',
    organization: json['Organisation'] ?? '',
  );
}