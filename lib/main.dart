import 'package:employee_management/core/di/injectable_module.dart';
import 'package:flutter/material.dart';
import 'routes/app_pages.dart';
import 'core/configs/themes/theme.dart';
import 'core/widgets/network_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  getIt.registerSingleton<String>(
    'https://0678-2409-40d1-8-8abc-4a19-acb1-5a2f-ecd8.ngrok-free.app/api/v1/',
  );
  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Themed App',
      theme: AppTheme.light(context),
      darkTheme: AppTheme.dark(context),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.INITIAL,
      routes: AppPages.routes,
      builder: (context, child) {
        return Stack(children: [child!, const NetworkDialogHandler()]);
      },
    );
  }
}
