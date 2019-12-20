import 'dart:typed_data';

import 'package:binary_buffer/binary_writer.dart';
import 'package:binary_buffer/binary_reader.dart';

/// An individual change.
class Change {
  int op;
  int objectId;
  Uint8List value;

  void serialize(BinaryWriter writer) {
    writer.writeVarUint(op);
    writer.writeVarUint(objectId);
    writer.writeVarUint(value.length);
    writer.write(value);
  }

  void deserialize(BinaryReader reader) {
    op = reader.readVarUint();
    objectId = reader.readVarUint();
    int length = reader.readVarUint();
    value = reader.read(length);
  }
}

/// A set of changes associated to an id.
class ChangeSet {
  int id;
  List<Change> changes;

  void serialize(BinaryWriter writer) {
    writer.writeVarUint(id);
    writer.writeVarUint(changes.length ?? 0);
    for (final change in changes) {
      change.serialize(writer);
    }
  }

  void deserialize(BinaryReader reader) {
    id = reader.readVarUint();
    int changesLength = reader.readVarUint();
    changes = List<Change>(changesLength);
    for (int i = 0; i < changes.length; i++) {
      changes[i] = Change()..deserialize(reader);
    }
  }
}
