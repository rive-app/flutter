import 'dart:typed_data';

import 'package:utilities/binary_buffer/binary_reader.dart';

abstract class CoreFieldType<T> {
  T deserialize(BinaryReader reader);
  Uint8List serialize(T value);
  T lerp(T from, T to, double f);
}
