import 'package:utilities/binary_buffer/binary_reader.dart';
import '../field_type.dart';

class ColorFieldType extends FieldType {
  ColorFieldType()
      : super(
          'Color',
          'CoreColorType',
          dartName: 'int',
        );

  @override
  String get defaultValue => '0';

  @override
  DeserializedResult deserializeRuntime(BinaryReader reader) {
    return DeserializedResult(4, reader.readUint32());
  }
}
