import 'package:utilities/binary_buffer/binary_reader.dart';
import '../field_type.dart';

class DoubleFieldType extends FieldType {
  DoubleFieldType()
      : super(
          'double',
          'CoreDoubleType',
        );

  @override
  String get defaultValue => '0.0';
  
  @override
  DeserializedResult deserializeRuntime(BinaryReader reader) {
    return DeserializedResult(4, reader.readFloat32());
  }
}
