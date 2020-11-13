import 'dart:convert';

extension JsonCodecHelper on JsonCodec {
  Map<String, dynamic> decodeMap(String jsonString) {
    dynamic data = json.decode(jsonString);
    return data is Map<String, dynamic> ? data : null;
  }

  List<T> decodeList<T>(String jsonString) {
    dynamic data = json.decode(jsonString);
    if (data is List) {
      return data.cast<T>();
    }
    return null;
  }
}

/// Extensions for making json deserialization simpler
extension DeserializeHelper on Map<String, dynamic> {
  double getDouble(String key) => deserializeDouble(this[key]);

  int getInt(String key) => deserializeInt(this[key]);
  int optInt(String key) => _rawDeserializeInt(this[key]);

  bool getBool(String key) => deserializeBool(this[key]);
  DateTime getDateTime(String key) => deserializeDateTime(this[key]);

  String getString(String key) {
    dynamic value = this[key];
    if (value != null) {
      return value.toString();
    }
    return null;
  }

  List<T> getList<T>(String key) {
    dynamic value = this[key];
    if (value != null && value is List) {
      return value.cast<T>();
    }
    return null;
  }

  Map<T, K> getMap<T, K>(String key) {
    dynamic value = this[key];
    if (value != null && value is Map<T, K>) {
      return value;
    }
    return null;
  }
}

double deserializeDouble(dynamic value) {
  if (value is double) {
    return value;
    // ignore: avoid_double_and_int_checks
  } else if (value is int) {
    return value.toDouble();
  } else if (value is String) {
    return double.parse(value);
  }
  return 0.0;
}

int deserializeInt(dynamic value) {
  final output = _rawDeserializeInt(value);
  if (output == null) {
    // TODO: this is probalby bad?
    return 0;
  }
  return output;
}

int _rawDeserializeInt(dynamic value) {
  if (value is int) {
    return value;
  } else if (value is double) {
    return value.toInt();
  } else if (value is String) {
    return int.parse(value);
  }
  // ignore: avoid_returning_null
  return null;
}

// ignore: avoid_bool_literals_in_conditional_expressions
bool deserializeBool(dynamic value) => value is bool ? value : false;

DateTime deserializeDateTime(dynamic value) {
  if (value != null) {
    return DateTime.parse(value as String);
  }
  return null;
}
