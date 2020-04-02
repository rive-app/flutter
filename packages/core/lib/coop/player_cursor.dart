import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

class PlayerCursor {
  final double x;
  final double y;

  PlayerCursor(this.x, this.y);

  void serialize(BinaryWriter writer) {
    writer.writeFloat32(x);
    writer.writeFloat32(y);
  }

  factory PlayerCursor.deserialize(BinaryReader reader) {
    return PlayerCursor(reader.readFloat32(), reader.readFloat32());
  }

  @override
  bool operator ==(Object other) =>
      other is PlayerCursor && other.x == x && other.y == y;
}
