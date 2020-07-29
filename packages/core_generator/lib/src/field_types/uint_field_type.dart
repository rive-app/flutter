import 'package:utilities/binary_buffer/binary_reader.dart';
import '../field_type.dart';

class UintFieldType extends FieldType {
  UintFieldType()
      : super(
          'uint',
          'CoreUintType',
          dartName: 'int',
        );

  @override
  String get defaultValue => '0';

  @override
  DeserializedResult deserializeRuntime(BinaryReader reader) {
    var position = reader.position;
    var value = reader.readVarUint();
    return DeserializedResult(reader.position - position, value);
  }
}
