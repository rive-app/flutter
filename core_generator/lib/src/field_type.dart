Map<String, FieldType> _types = <String, FieldType>{};

abstract class FieldType {
  final String name;
  FieldType(this.name) {
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
  String decode(String readerName);
}
