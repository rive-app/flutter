import 'dart:typed_data';

import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class CoreFieldType<T> {
  T deserialize(BinaryReader reader);
  Uint8List serialize(T value);
  void write(BinaryWriter writer, T value);
  T lerp(T from, T to, double f);
}
