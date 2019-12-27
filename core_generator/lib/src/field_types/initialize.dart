// All supported field types.

import '../field_type.dart';
import 'double_field_type.dart';
import 'int_field_type.dart';
import 'string_field_type.dart';   

List<FieldType> fields;

void initializeFields() {
  fields = [
    StringFieldType(),
    IntFieldType(),
    DoubleFieldType(),
  ];
}
