// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  ProfileDao? _profileDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `profile` (`id` TEXT NOT NULL, `first_name` TEXT NOT NULL, `last_name` TEXT NOT NULL, `email` TEXT NOT NULL, `dob` TEXT NOT NULL, `phoneNo` TEXT NOT NULL, `designation` TEXT NOT NULL, `organization` TEXT NOT NULL, PRIMARY KEY (`id`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  ProfileDao get profileDao {
    return _profileDaoInstance ??= _$ProfileDao(database, changeListener);
  }
}

class _$ProfileDao extends ProfileDao {
  _$ProfileDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _profileInsertionAdapter = InsertionAdapter(
            database,
            'profile',
            (Profile item) => <String, Object?>{
                  'id': item.id,
                  'first_name': item.first_name,
                  'last_name': item.last_name,
                  'email': item.email,
                  'dob': item.dob,
                  'phoneNo': item.phoneNo,
                  'designation': item.designation,
                  'organization': item.organization
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Profile> _profileInsertionAdapter;

  @override
  Future<Profile?> getProfile(String id) async {
    return _queryAdapter.query('SELECT * FROM profile WHERE id = ?1',
        mapper: (Map<String, Object?> row) => Profile(
            id: row['id'] as String,
            first_name: row['first_name'] as String,
            last_name: row['last_name'] as String,
            email: row['email'] as String,
            dob: row['dob'] as String,
            phoneNo: row['phoneNo'] as String,
            designation: row['designation'] as String,
            organization: row['organization'] as String),
        arguments: [id]);
  }

  @override
  Future<List<Profile>> getAllProfiles() async {
    return _queryAdapter.queryList('SELECT * FROM profile',
        mapper: (Map<String, Object?> row) => Profile(
            id: row['id'] as String,
            first_name: row['first_name'] as String,
            last_name: row['last_name'] as String,
            email: row['email'] as String,
            dob: row['dob'] as String,
            phoneNo: row['phoneNo'] as String,
            designation: row['designation'] as String,
            organization: row['organization'] as String));
  }

  @override
  Future<void> clearProfile() async {
    await _queryAdapter.queryNoReturn('DELETE FROM profile');
  }

  @override
  Future<void> insertProfile(Profile profile) async {
    await _profileInsertionAdapter.insert(profile, OnConflictStrategy.replace);
  }
}
