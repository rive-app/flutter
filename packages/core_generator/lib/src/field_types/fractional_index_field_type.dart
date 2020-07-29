import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:core_generator/src/field_type.dart';

class FractionalIndexFieldType extends FieldType {
  FractionalIndexFieldType()
      : super(
          "FractionalIndex",
          'CoreFractionalIndexType',
        );

  @override
  DeserializedResult deserializeRuntime(BinaryReader reader) {
    throw UnimplementedError();
  }
}
