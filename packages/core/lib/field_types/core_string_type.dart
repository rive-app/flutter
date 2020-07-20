import 'dart:typed_data';

import 'package:core/field_types/core_field_type.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

class CoreStringType extends CoreFieldType<String> {
  @override
  String deserialize(BinaryReader reader) {
    // TODO: replace with this in a few days:
    // return reader.readString(explicitLength: false);

    // Temporary workaround:
    var actualReader = BinaryReader(reader.buffer);
    var hackyTestReader = BinaryReader(reader.buffer);
    var oldStyle =
        hackyTestReader.readVarUint() == reader.buffer.lengthInBytes - 1;
    return actualReader.readString(explicitLength: oldStyle);
  }

  @override
  String lerp(String from, String to, double f) => from;

  @override
  Uint8List serialize(String value) {
    var writer = BinaryWriter(alignment: value.length * 2);
    writer.writeString(value, explicitLength: false);
    return writer.uint8Buffer;
  }
}
