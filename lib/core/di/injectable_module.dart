import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injectable_module.config.dart';

final getIt = GetIt.instance;

final baseUrl = 'https://9b0c1217ae3c.ngrok-free.app/api/v1/';
final navigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);

@InjectableInit()
Future<void> configureDependencies() async => await getIt.init();

void registerGlobalDependencies() {
  getIt.registerSingleton<GlobalKey<NavigatorState>>(navigatorKey);
  getIt.registerSingleton<String>(baseUrl);
  getIt.registerSingleton<GlobalKey<ScaffoldMessengerState>>(
    scaffoldMessengerKey,
  );
}
