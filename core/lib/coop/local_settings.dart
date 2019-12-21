abstract class LocalSettings {
  Future<int> getIntSetting(String name);
  Future<void> setIntSetting(String name, int value);
  Future<String> getStringSetting(String name);
  Future<void> setStringSetting(String name, String value);
}
