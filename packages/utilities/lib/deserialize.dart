/// Extensions for making json deserialization simpler
extension DeserializeHelper on Map<String, dynamic> {
  double getDouble(String key) => deserializeDouble(this[key]);

  int getInt(String key) => deserializeInt(this[key]);

  bool getBool(String key) => deserializeBool(this[key]);

  String getString(String key) {
    dynamic value = this[key];
    if (value != null) {
      return value.toString();
    }
    return null;
  }

  List<dynamic> getList(String key) {
    dynamic value = this[key];
    if (value != null) {
      return value as List<dynamic>;
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
  if (value is int) {
    return value;
  } else if (value is double) {
    return value.toInt();
  } else if (value is String) {
    return int.parse(value);
  }
  return 0;
}

// ignore: avoid_bool_literals_in_conditional_expressions
bool deserializeBool(dynamic value) => value is bool ? value : false;
