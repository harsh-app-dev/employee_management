import 'package:flutter/cupertino.dart';

import '../features/presentation/screens/login_screen.dart';

class AppPages {
  static const INITIAL = '/login';

  static final routes = <String, WidgetBuilder>{
    '/login': (context) => LoginScreen(),
  };
}