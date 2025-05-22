// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:employee_management/core/controllers/network_controller.dart'
    as _i347;
import 'package:employee_management/core/network/client/network_client.dart'
    as _i431;
import 'package:employee_management/core/network/network_monitor.dart'
    as _i1007;
import 'package:employee_management/features/data/repositories/auth_repository.dart'
    as _i106;
import 'package:employee_management/features/domain/use_cases/login_use_case.dart'
    as _i255;
import 'package:employee_management/features/presentation/state/login_controller.dart'
    as _i47;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i1007.NetworkMonitor>(() => _i1007.NetworkMonitor());
    gh.factory<_i347.NetworkController>(
      () => _i347.NetworkController(gh<_i1007.NetworkMonitor>()),
    );
    gh.lazySingleton<_i431.NetworkClient>(
      () => _i431.NetworkClient(baseUrl: gh<String>()),
    );
    gh.factory<_i106.AuthRepository>(
      () => _i106.AuthRepository(gh<_i431.NetworkClient>()),
    );
    gh.factory<_i255.LoginUseCase>(
      () => _i255.LoginUseCase(gh<_i106.AuthRepository>()),
    );
    gh.factory<_i47.LoginController>(
      () => _i47.LoginController(gh<_i255.LoginUseCase>()),
    );
    return this;
  }
}
