import 'package:utilities/binary_buffer/binary_reader.dart';
import '../field_type.dart';

class BoolFieldType extends FieldType {
  BoolFieldType()
      : super(
          'bool',
          'CoreBoolType',
        );

  @override
  String get defaultValue => 'false';

  @override
  DeserializedResult deserializeRuntime(BinaryReader reader) {
    return DeserializedResult(1, reader.readInt8() == 1);
  }
}
