import 'package:utilities/binary_buffer/binary_reader.dart';
import '../field_type.dart';

class IntFieldType extends FieldType {
  IntFieldType()
      : super(
          'int',
          'CoreIntType',
        );

  @override
  String get defaultValue => '0';

  @override
  DeserializedResult deserializeRuntime(BinaryReader reader) {
    var position = reader.position;
    var value = reader.readVarInt();
    return DeserializedResult(reader.position - position, value);
  }
}
