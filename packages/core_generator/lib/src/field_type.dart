Map<String, FieldType> _types = <String, FieldType>{};

abstract class FieldType {
  final String name;
  String _dartName;
  String get dartName => _dartName;

  String _runtimeCoreType;
  String get runtimeCoreType => _runtimeCoreType;

  final Iterable<String> imports;
  FieldType(this.name, String runtimeCoreType,
      {String dartName, this.imports}) {
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
}
