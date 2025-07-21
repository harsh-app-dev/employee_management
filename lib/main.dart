import 'package:employee_management/core/di/injectable_module.dart';
import 'package:employee_management/core/storage/local_storage.dart';
import 'package:employee_management/core/storage/shared_preference_keys.dart';
import 'package:employee_management/features/presentation/state/getx/theme_controller.dart';
import 'package:employee_management/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import 'core/configs/themes/theme.dart';
import 'core/widgets/network_dialog.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:employee_management/core/services/firebase_messaging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessagingService().initialize();
  await configureDependencies();
  registerGlobalDependencies();
  await getIt<LocalStorage>().init();
  isLoggedIn.value =
      getIt<LocalStorage>().getBool(SharedPreferenceKeys.loggedInKey) ?? false;
  Get.put(ThemeController()); // Ensure ThemeController is registered before runApp
  runApp(
    FlutterSizer(
      builder: (context, orientation, deviceType) {
        return const MyApp();
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();
    return Obx(
      () => GetMaterialApp(
        navigatorKey: getIt<GlobalKey<NavigatorState>>(),
        scaffoldMessengerKey: getIt<GlobalKey<ScaffoldMessengerState>>(),
        title: 'Custom Themed App',
        theme: AppTheme.light(context),
        darkTheme: AppTheme.dark(context),
        themeMode: themeController.themeMode.value,
        debugShowCheckedModeBanner: false,
        routes: AppPages.routes,
        home: ValueListenableBuilder(
          valueListenable: isLoggedIn,
          builder: (context, isLoggedIn, _) {
            return isLoggedIn
                ? AppPages.routes['/main']!(context)
                : AppPages.routes['/login']!(context);
          },
        ),
        builder: (context, child) {
          return Stack(children: [child!, const NetworkDialogHandler()]);
        },
      ),
    );
  }
}
