import 'dart:typed_data';

class Entity {
  /// Represents the kind of entity this is.
  int key;

  /// The client's session id.
  int sessionId;

  /// The serverside change id that created or changed this entity.
  int serverChangeId;
}

class ObjectProperty extends Entity {
  /// The data value encoded in binary for this property.
  Uint8List data;
}

class CoopFileObject extends Entity {
  /// The local id received from the session representing this object.
  int localId;

  List<ObjectProperty> properties;
}

class Session {
  /// Unique session id.
  int id;

  /// Last received change id.
  int changeId;

  /// User id from the database.
  String userId;
}

class CoopFile {
  String ownerId;
  String fileId;

  List<CoopFileObject> objects;
  List<Entity> deletedObjects;
  List<Session> sessions;
  int nextObjectId;
  int nextChangeId;
}

class Change {
  int op;
  int objectId;
  Uint8List value;
}

class ChangeSet {
  int id;
  List<Change> changes;
}

