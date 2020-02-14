Map<String, FieldType> _types = <String, FieldType>{};

abstract class FieldType {
  final String name;
  final String import;
  FieldType(this.name, {this.import}) {
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

  int get encodingAlignment;
  String encode(String writerName, String varName);
  String decode(String readerName, String varName);

  String equalityCheck(String varAName, String varBName) {
    return "$varAName == $varBName";
  }
}
