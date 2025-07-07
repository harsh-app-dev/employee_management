import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'profile_dao.dart';
import 'profile_data.dart';

part 'profile_database.g.dart';

@Database(version: 3, entities: [Profile])
abstract class AppDatabase extends FloorDatabase {
  ProfileDao get profileDao;
}

final migration2to3 = Migration(2, 3, (database) async {
  await database.execute('ALTER TABLE profile ADD COLUMN employee_active TEXT;');
});
