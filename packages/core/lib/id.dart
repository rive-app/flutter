import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

/// A client specific object id.
class Id {
  final int client;
  final int object;

  const Id(this.client, this.object);

  @override
  int get hashCode => _szudzik(client, object);

  @override
  bool operator ==(Object other) =>
      other is Id && other.client == client && other.object == object;

  @override
  String toString() {
    return '$client-$object';
  }

  void serialize(BinaryWriter writer) {
    writer.writeVarUint(client);
    writer.writeVarUint(object);
  }

  factory Id.deserialize(BinaryReader reader) {
    int client = reader.readVarUint();
    int object = reader.readVarUint();
    return Id(client, object);
  }

  Id get next => Id(client, object + 1);
}

/// Szudzik's function for hashing two ints together
int _szudzik(int a, int b) {
  // a and b must be >= 0
  int x = a.abs();
  int y = b.abs();
  return x >= y ? x * x + x + y : x + y * y;
}
