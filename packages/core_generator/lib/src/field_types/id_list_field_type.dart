import 'package:utilities/binary_buffer/binary_reader.dart';
import '../field_type.dart';

class IdListFieldType extends FieldType {
  IdListFieldType()
      : super(
          'List<Id>',
          'CoreListIdType',
        );

  @override
  String equalityCheck(String varAName, String varBName) {
    return 'listEquals($varAName, $varBName)';
  }

  @override
  DeserializedResult deserializeRuntime(BinaryReader reader) {
    throw UnimplementedError();
  }
}
