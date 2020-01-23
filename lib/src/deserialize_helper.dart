// import 'package:flare_dart/math/vec2d.dart';

extension DeserializeHelper on Map<String, dynamic> {
  double getDouble(String key) {
    dynamic value = this[key];
    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is String) {
      return double.parse(value);
    }
    return 0.0;
  }

  int getInt(String key) {
    dynamic value = this[key];
    if (value is double) {
      return value.toInt();
    } else if (value is int) {
      return value;
    } else if (value is String) {
      return int.parse(value);
    }
    return 0;
  }

  bool getBool(String key) {
    var value = this[key];
    if (value is bool) {
      return value;
    }

    return false;
  }

  String getString(String key) {
    var value = this[key];
    if (value != null) {
      return value.toString();
    }
    return null;
  }
}

double deserializeDouble(dynamic value) {
  if (value is double) {
    return value;
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

bool deserializeBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  return false;
}

// Vec2D deserializeVec2(dynamic data, {Vec2D def})
// {
// 	if (data is! List || data.length != 2)
// 	{
// 		return def ?? Vec2D.fromValues(0.0, 0.0);
// 	}

// 	return Vec2D.fromValues(deserializeDouble(data[0]), deserializeDouble(data[1]));
// }
