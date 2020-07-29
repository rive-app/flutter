import 'dart:typed_data';

import 'package:utilities/binary_buffer/binary_reader.dart';
import '../field_type.dart';

class StringFieldType extends FieldType {
  StringFieldType()
      : super(
          'String',
          'CoreStringType',
        );

  @override
  DeserializedResult deserializeRuntime(BinaryReader reader) {
    var length = reader.readVarUint();
    var stringReader = BinaryReader(ByteData.sublistView(
        reader.buffer, reader.position, reader.position + length));
    var value = stringReader.readString(explicitLength: false);
    // push the position (if we ever need this at runtime, consider adding a
    // position setter/advancer helper to the BinaryReader).
    for (int i = 0; i < length; i++) {
      reader.readUint8();
    }
    return DeserializedResult(length, value);
  }
}
