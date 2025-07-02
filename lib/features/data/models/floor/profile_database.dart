import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'profile_dao.dart';
import 'profile_data.dart';

part 'profile_database.g.dart';

@Database(version: 2, entities: [Profile])
abstract class AppDatabase extends FloorDatabase {
  ProfileDao get profileDao;
}