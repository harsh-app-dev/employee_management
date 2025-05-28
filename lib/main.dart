import 'package:employee_management/core/di/injectable_module.dart';
import 'package:employee_management/core/storage/local_storage.dart';
import 'package:employee_management/core/storage/shared_preference_keys.dart';
import 'package:employee_management/routes/app_pages.dart';
import 'package:flutter/material.dart';

import 'core/configs/themes/theme.dart';
import 'core/widgets/network_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  registerGlobalDependencies();
  await getIt<LocalStorage>().init();
  isLoggedIn.value =
      getIt<LocalStorage>().getBool(SharedPreferenceKeys.loggedInKey) ?? false;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: getIt<GlobalKey<NavigatorState>>(),
      scaffoldMessengerKey: getIt<GlobalKey<ScaffoldMessengerState>>(),
      title: 'Custom Themed App',
      theme: AppTheme.light(context),
      darkTheme: AppTheme.dark(context),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: ValueListenableBuilder(
        valueListenable: isLoggedIn,
        builder: (context, isLoggedIn, _) {
          return isLoggedIn
              ? AppPages.routes['/dashboard']!(context)
              : AppPages.routes['/login']!(context);
        },
      ),
      builder: (context, child) {
        return Stack(children: [child!, const NetworkDialogHandler()]);
      },
    );
  }
}
