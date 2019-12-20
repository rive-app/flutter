import 'dart:typed_data';

/// An individual change.
class Change {
  int op;
  int objectId;
  Uint8List value;

  void serialize(BinaryWriter writer) {
    
  }
}

/// A set of changes associated to an id.
class ChangeSet {
  int id;
  List<Change> changes;
}
