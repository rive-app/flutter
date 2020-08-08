// All supported field types.

import '../field_type.dart';
import 'bool_field_type.dart';
import 'color_field_type.dart';
import 'double_field_type.dart';
import 'fractional_index_field_type.dart';
import 'id_field_type.dart';
import 'id_list_field_type.dart';
import 'string_field_type.dart';
import 'uint_field_type.dart';

List<FieldType> fields;

void initializeFields() {
  fields = [
    StringFieldType(),
    UintFieldType(),
    DoubleFieldType(),
    FractionalIndexFieldType(),
    IdListFieldType(),
    BoolFieldType(),
    IdFieldType(),
    ColorFieldType(),
  ];
}
