import 'dart:typed_data';

import 'package:core/field_types/core_field_type.dart';
import 'package:core/id.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

class CoreIdType extends CoreFieldType<Id> {
  @override
  Id deserialize(BinaryReader reader) {
    int client = reader.readVarUint();
    int object = reader.readVarUint();
    return Id(client, object);
  }

  @override
  Id lerp(Id from, Id to, double f) => from;

  @override
  Uint8List serialize(Id value) {
    var writer = BinaryWriter(alignment: 8);
    write(writer, value);
    return writer.uint8Buffer;
  }

  @override
  void write(BinaryWriter writer, Id value) {
    writer.writeVarUint(value.client);
    writer.writeVarUint(value.object);
  }
}
