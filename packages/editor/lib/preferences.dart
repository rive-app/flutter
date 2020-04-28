import 'package:shared_preferences/shared_preferences.dart';

// spctretoken doesnt seem to be used, we are using local data apparantly.
enum Preferences { spectreToken, selectedRiveOwnerId }

final _prefNameMap = <Preferences, String>{
  Preferences.spectreToken: getPreferenceKey(Preferences.spectreToken),
  Preferences.selectedRiveOwnerId:
      getPreferenceKey(Preferences.selectedRiveOwnerId),
};

String getPreferenceKey(Preferences preference) {
  return 'Settings.${preference.toString()}';
}

class Settings {
  static Future<void> setString(Preferences preference, String value) async {
    var _prefs = await SharedPreferences.getInstance();
    await _prefs.setString(_prefNameMap[preference], value);
  }

  static Future<void> setInt(Preferences preference, int value) async {
    var _prefs = await SharedPreferences.getInstance();
    await _prefs.setInt(_prefNameMap[preference], value);
  }

  static Future<String> getString(Preferences preference) async {
    var _prefs = await SharedPreferences.getInstance();
    return _prefs.getString(_prefNameMap[preference]);
  }

  static Future<int> getInt(Preferences preference) async {
    var _prefs = await SharedPreferences.getInstance();
    return _prefs.getInt(_prefNameMap[preference]);
  }

  static Future<bool> clear(Preferences preference) async {
    var _prefs = await SharedPreferences.getInstance();
    return _prefs.remove(_prefNameMap[preference]);
  }
}
