import 'dart:typed_data';

import 'entity.dart';
import 'session.dart';

class CoopFile {
  String ownerId;
  String fileId;

  List<CoopFileObject> objects;
  List<Entity> deletedObjects;
  List<Session> sessions;
  int nextObjectId;
  int nextChangeId;
}

class CoopFileObject extends Entity {
  /// The local id received from the session representing this object.
  int localId;

  List<ObjectProperty> properties;
}

class ObjectProperty extends Entity {
  /// The data value encoded in binary for this property.
  Uint8List data;
}
