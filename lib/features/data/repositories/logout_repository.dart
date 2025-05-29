import 'package:employee_management/core/storage/local_storage.dart';
import 'package:injectable/injectable.dart';

@injectable
class LogoutRepository {
  final LocalStorage _localStorage;

  LogoutRepository(this._localStorage);

  Future<void> logout() async {
    await _localStorage.clear();
  }
}