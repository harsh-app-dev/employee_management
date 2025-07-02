// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:employee_management/core/controllers/network_controller.dart'
    as _i347;
import 'package:employee_management/core/di/database_module.dart' as _i509;
import 'package:employee_management/core/network/client/network_client.dart'
    as _i431;
import 'package:employee_management/core/network/network_monitor.dart'
    as _i1007;
import 'package:employee_management/core/storage/local_storage.dart' as _i1007;
import 'package:employee_management/features/data/models/floor/profile_dao.dart'
    as _i271;
import 'package:employee_management/features/data/models/floor/profile_database.dart'
    as _i1065;
import 'package:employee_management/features/data/repositories/auth_repository.dart'
    as _i106;
import 'package:employee_management/features/data/repositories/logout_repository.dart'
    as _i1067;
import 'package:employee_management/features/data/repositories/profile_repository.dart'
    as _i840;
import 'package:employee_management/features/data/repositories/punch_repository.dart'
    as _i730;
import 'package:employee_management/features/data/repositories/submit_tasks_repository.dart'
    as _i802;
import 'package:employee_management/features/data/repositories/task_repository.dart'
    as _i498;
import 'package:employee_management/features/domain/use_cases/login_use_case.dart'
    as _i255;
import 'package:employee_management/features/domain/use_cases/logout_use_case.dart'
    as _i427;
import 'package:employee_management/features/domain/use_cases/profile_use_case.dart'
    as _i288;
import 'package:employee_management/features/domain/use_cases/punch_in_out_use_case.dart'
    as _i828;
import 'package:employee_management/features/domain/use_cases/punch_state_use_case.dart'
    as _i876;
import 'package:employee_management/features/domain/use_cases/submit_tasks_use_case.dart'
    as _i124;
import 'package:employee_management/features/domain/use_cases/task_use_case.dart'
    as _i238;
import 'package:employee_management/features/presentation/state/dashboard_controller.dart'
    as _i297;
import 'package:employee_management/features/presentation/state/login_controller.dart'
    as _i47;
import 'package:employee_management/features/presentation/state/profile_controller.dart'
    as _i833;
import 'package:employee_management/features/presentation/state/punch_controller.dart'
    as _i72;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final databaseModule = _$DatabaseModule();
    await gh.factoryAsync<_i1065.AppDatabase>(
      () => databaseModule.db,
      preResolve: true,
    );
    gh.lazySingleton<_i1007.NetworkMonitor>(() => _i1007.NetworkMonitor());
    gh.lazySingleton<_i1007.LocalStorage>(() => _i1007.LocalStorage());
    gh.factory<_i271.ProfileDao>(
        () => databaseModule.getProfileDao(gh<_i1065.AppDatabase>()));
    gh.factory<_i347.NetworkController>(
        () => _i347.NetworkController(gh<_i1007.NetworkMonitor>()));
    gh.lazySingleton<_i431.NetworkClient>(
        () => _i431.NetworkClient(baseUrl: gh<String>()));
    gh.factory<_i1067.LogoutRepository>(
        () => _i1067.LogoutRepository(gh<_i1007.LocalStorage>()));
    gh.factory<_i427.LogoutUseCase>(
        () => _i427.LogoutUseCase(gh<_i1067.LogoutRepository>()));
    gh.factory<_i106.AuthRepository>(() => _i106.AuthRepository(
          gh<_i431.NetworkClient>(),
          gh<_i1007.LocalStorage>(),
        ));
    gh.factory<_i840.ProfileRepository>(() => _i840.ProfileRepository(
          gh<_i431.NetworkClient>(),
          gh<_i1007.LocalStorage>(),
        ));
    gh.factory<_i730.PunchRepository>(() => _i730.PunchRepository(
          gh<_i431.NetworkClient>(),
          gh<_i1007.LocalStorage>(),
        ));
    gh.factory<_i802.SubmitTaskRepository>(() => _i802.SubmitTaskRepository(
          gh<_i431.NetworkClient>(),
          gh<_i1007.LocalStorage>(),
        ));
    gh.factory<_i498.TaskRepository>(() => _i498.TaskRepository(
          gh<_i431.NetworkClient>(),
          gh<_i1007.LocalStorage>(),
        ));
    gh.factory<_i238.TaskUseCase>(
        () => _i238.TaskUseCase(gh<_i498.TaskRepository>()));
    gh.factory<_i828.PunchInOutUseCase>(
        () => _i828.PunchInOutUseCase(gh<_i730.PunchRepository>()));
    gh.factory<_i876.PunchStateUseCase>(
        () => _i876.PunchStateUseCase(gh<_i730.PunchRepository>()));
    gh.factory<_i288.ProfileUseCase>(
        () => _i288.ProfileUseCase(gh<_i840.ProfileRepository>()));
    gh.factory<_i124.SubmitTasksUseCase>(
        () => _i124.SubmitTasksUseCase(gh<_i802.SubmitTaskRepository>()));
    gh.factory<_i72.PunchController>(() => _i72.PunchController(
          gh<_i828.PunchInOutUseCase>(),
          gh<_i876.PunchStateUseCase>(),
        ));
    gh.factory<_i255.LoginUseCase>(
        () => _i255.LoginUseCase(gh<_i106.AuthRepository>()));
    gh.factory<_i833.ProfileController>(() => _i833.ProfileController(
          gh<_i288.ProfileUseCase>(),
          gh<_i427.LogoutUseCase>(),
          gh<_i271.ProfileDao>(),
        ));
    gh.factory<_i297.DashboardController>(() => _i297.DashboardController(
          gh<_i238.TaskUseCase>(),
          gh<_i124.SubmitTasksUseCase>(),
        ));
    gh.factory<_i47.LoginController>(
        () => _i47.LoginController(gh<_i255.LoginUseCase>()));
    return this;
  }
}

class _$DatabaseModule extends _i509.DatabaseModule {}
