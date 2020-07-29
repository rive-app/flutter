import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:core_generator/src/field_type.dart';

class IdFieldType extends FieldType {
  IdFieldType()
      : super(
          'Id',
          'CoreIdType',
        );

  @override
  DeserializedResult deserializeRuntime(BinaryReader reader) {
    throw UnimplementedError();
  }
}
