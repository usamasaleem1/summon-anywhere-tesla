import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingCompleteKey = 'onboarding_complete';
const _selectedVehicleIdKey = 'selected_vehicle_id';

final prefsStorageProvider = Provider<PrefsStorage>((ref) {
  throw UnimplementedError('prefsStorageProvider must be overridden in main');
});

class PrefsStorage {
  PrefsStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<PrefsStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefsStorage(prefs);
  }

  bool get onboardingComplete => _prefs.getBool(_onboardingCompleteKey) ?? false;

  Future<void> setOnboardingComplete(bool value) =>
      _prefs.setBool(_onboardingCompleteKey, value);

  String? get selectedVehicleId => _prefs.getString(_selectedVehicleIdKey);

  Future<void> setSelectedVehicleId(String id) =>
      _prefs.setString(_selectedVehicleIdKey, id);
}
