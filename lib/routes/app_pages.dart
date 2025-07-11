import 'package:employee_management/features/presentation/screens/dashboard_screen.dart';
import 'package:employee_management/features/presentation/screens/login_screen.dart';
import 'package:employee_management/features/presentation/screens/profile_screen.dart' show ProfileScreen;
import 'package:employee_management/features/presentation/screens/main_screen.dart';
import 'package:flutter/cupertino.dart';

class AppPages {
  static const INITIAL = '/main';

  static final routes = <String, WidgetBuilder>{
    '/login': (context) => LoginScreen(),
    '/main': (context) => MainScreen(),
    '/dashboard': (context) => DashboardScreen(),
    '/profile': (context) => ProfileScreen()
  };
}