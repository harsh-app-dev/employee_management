import 'package:injectable/injectable.dart';
import 'package:employee_management/features/data/models/floor/profile_database.dart';
import 'package:employee_management/features/data/models/floor/profile_dao.dart';

@module
abstract class DatabaseModule {
  @preResolve
  Future<AppDatabase> get db => $FloorAppDatabase.databaseBuilder('profile_database.db').build();

  ProfileDao getProfileDao(AppDatabase db) => db.profileDao;
}