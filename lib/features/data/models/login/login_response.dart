import 'dart:convert';

LoginResponse loginResponseFromJson(String str) =>
    LoginResponse.fromJson(json.decode(str));

String loginResponseToJson(LoginResponse data) => json.encode(data.toJson());

class LoginResponse {
  LoginResponse({
    bool? success,
    String? refresh,
    String? access,
    User? user,
    String? role,
    String? designation,
  }) {
    _success = success;
    _refresh = refresh;
    _access = access;
    _user = user;
    _role = role;
    _designation = designation;
  }

  LoginResponse.fromJson(dynamic json) {
    _success = json['success'];
    _refresh = json['refresh'];
    _access = json['access'];
    _user = json['user'] != null ? User.fromJson(json['user']) : null;
    _role = json['role'];
    _designation = json['designation'];
  }

  bool? _success;
  String? _refresh;
  String? _access;
  User? _user;
  String? _role;
  String? _designation;

  LoginResponse copyWith({
    bool? success,
    String? refresh,
    String? access,
    User? user,
    String? role,
    String? designation,
  }) => LoginResponse(
    success: success ?? _success,
    refresh: refresh ?? _refresh,
    access: access ?? _access,
    user: user ?? _user,
    role: role ?? _role,
    designation: designation ?? _designation,
  );

  bool? get success => _success;

  String? get refresh => _refresh;

  String? get access => _access;

  User? get user => _user;

  String? get role => _role;

  String? get designation => _designation;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = _success;
    map['refresh'] = _refresh;
    map['access'] = _access;
    if (_user != null) {
      map['user'] = _user?.toJson();
    }
    map['role'] = _role;
    map['designation'] = _designation;
    return map;
  }
}

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

class User {
  User({
    String? userId,
    String? username,
    String? exp,
    String? email,
    num? origIat,
  }) {
    _userId = userId;
    _username = username;
    _exp = exp;
    _email = email;
    _origIat = origIat;
  }

  User.fromJson(dynamic json) {
    _userId = json['user_id'];
    _username = json['username'];
    _exp = json['exp'];
    _email = json['email'];
    _origIat = json['orig_iat'];
  }

  String? _userId;
  String? _username;
  String? _exp;
  String? _email;
  num? _origIat;

  User copyWith({
    String? userId,
    String? username,
    String? exp,
    String? email,
    num? origIat,
  }) => User(
    userId: userId ?? _userId,
    username: username ?? _username,
    exp: exp ?? _exp,
    email: email ?? _email,
    origIat: origIat ?? _origIat,
  );

  String? get userId => _userId;

  String? get username => _username;

  String? get exp => _exp;

  String? get email => _email;

  num? get origIat => _origIat;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['user_id'] = _userId;
    map['username'] = _username;
    map['exp'] = _exp;
    map['email'] = _email;
    map['orig_iat'] = _origIat;
    return map;
  }
}
