import 'package:employee_management/features/data/models/floor/profile_data.dart';
import 'package:floor/floor.dart';

@dao
abstract class ProfileDao{
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertProfile(Profile profile);

  @Query('SELECT * FROM profile WHERE id = :id')
  Future<Profile?> getProfile(String id);

  @Query('SELECT * FROM profile')
  Future<List<Profile>> getAllProfiles();

  @Query('DELETE FROM profile')
  Future<void> clearProfile();
}