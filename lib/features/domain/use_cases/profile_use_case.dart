import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/profile/profile_response.dart';
import 'package:employee_management/features/data/repositories/profile_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class ProfileUseCase {
  final ProfileRepository _repository;
  ProfileUseCase(this._repository);

  Future<NetworkResult<ProfileResponse>> call() async {
    return await _repository.fetchProfile();
  }
}

