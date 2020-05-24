import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

class CoreFractionalIndexType extends CoreFieldType<FractionalIndex> {
  @override
  FractionalIndex deserialize(BinaryReader reader) {
    var numerator = reader.readVarInt();
    var denominator = reader.readVarInt();
    return FractionalIndex(numerator, denominator);
  }

  @override
  FractionalIndex lerp(FractionalIndex from, FractionalIndex to, double f) =>
      from;

  @override
  Uint8List serialize(FractionalIndex value) {
    var writer = BinaryWriter(alignment: 8);
    write(writer, value);
    return writer.uint8Buffer;
  }

  @override
  void write(BinaryWriter writer, FractionalIndex value) {
    writer.writeVarInt(value.numerator);
    writer.writeVarInt(value.denominator);
  }
}
