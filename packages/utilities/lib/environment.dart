import 'package:utilities/platform.dart';

final _cache = <String, String>{};

String getVariable(String key, {String defaultValue = ''}) {
  if (_cache.containsKey(key)) return _cache[key];

  String value;

  if (Platform.instance.environment.containsKey(key)) {
    value = Platform.instance.environment[key];
  }
  value ??= defaultValue;
  _cache[key] = value;

  return getVariable(key);
}
