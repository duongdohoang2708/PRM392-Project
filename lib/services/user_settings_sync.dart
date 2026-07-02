import '../repositories/settings_repository.dart';

class UserSettingsSync {
  UserSettingsSync({SettingsRepository? repository})
      : _repository = repository ?? SettingsRepository();

  final SettingsRepository _repository;

  Future<Map<String, dynamic>?> pull(String uid) => _repository.fetchSettings(uid);

  Future<void> merge(String uid, Map<String, dynamic> patch) =>
      _repository.mergeSettings(uid, patch);

  Stream<Map<String, dynamic>?> watch(String uid) =>
      _repository.watchSettings(uid);
}
