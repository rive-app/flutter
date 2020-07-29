import 'package:utilities/binary_buffer/binary_reader.dart';

Map<String, FieldType> _types = <String, FieldType>{};

class DeserializedResult {
  final int length;
  final dynamic value;

  DeserializedResult(this.length, this.value);
}

abstract class FieldType {
  final String name;
  String _dartName;
  String get dartName => _dartName;

  String _runtimeCoreType;
  String get runtimeCoreType => _runtimeCoreType;

  FieldType(
    this.name,
    String runtimeCoreType, {
    String dartName,
  }) {
    _dartName = dartName ?? name;
    _runtimeCoreType = runtimeCoreType;
    _types[name] = this;
  }

  static FieldType find(dynamic key) {
    if (key is! String) {
      return null;
    }
    return _types[key];
  }

  @override
  String toString() {
    return name;
  }

  String equalityCheck(String varAName, String varBName) {
    return "$varAName == $varBName";
  }

  String get defaultValue => 'null';

  String get uncapitalizedName => '${name[0].toLowerCase()}${name.substring(1)}'
      .replaceAll('<', '')
      .replaceAll('>', '');

  String get capitalizedName => '${name[0].toUpperCase()}${name.substring(1)}'
      .replaceAll('<', '')
      .replaceAll('>', '');

  String get snakeName => name
      .replaceAllMapped(RegExp('(.+?)([A-Z])'), (Match m) => '${m[1]}_${m[2]}')
      .toLowerCase();

  DeserializedResult deserializeRuntime(BinaryReader reader);
}
