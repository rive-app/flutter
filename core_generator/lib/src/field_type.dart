Map<String, FieldType> _types = <String, FieldType>{};

// All supported field types.
List<FieldType> fields;

void initializeFields() {
  fields = [
    FieldType("String"),
    FieldType("int"),
    FieldType("double"),
  ];
}

class FieldType {
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
}