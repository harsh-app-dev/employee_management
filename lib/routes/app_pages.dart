import 'package:employee_management/features/presentation/screens/dashboard_screen.dart';
import 'package:employee_management/features/presentation/screens/login_screen.dart';
import 'package:employee_management/features/presentation/screens/profile_screen.dart' show ProfileScreen;
import 'package:flutter/cupertino.dart';

class AppPages {
  static const INITIAL = '/login';

  static final routes = <String, WidgetBuilder>{
    '/login': (context) => LoginScreen(),
    '/dashboard': (context) => DashboardScreen(),
    '/profile': (context) => ProfileScreen()
  };
}