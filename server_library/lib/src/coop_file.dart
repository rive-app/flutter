import 'dart:typed_data';

import 'package:binary_buffer/binary_reader.dart';
import 'package:binary_buffer/binary_writer.dart';
import 'package:core/coop/change.dart';
import 'package:core/coop/coop_command.dart';
import 'package:core/core.dart';

import 'entity.dart';
import 'session.dart';

class CoopFile {
  int ownerId;
  int fileId;

  Map<int, CoopFileObject> objects;

  void deserialize(BinaryReader reader) {
    ownerId = reader.readVarUint();
    fileId = reader.readVarUint();

    objects = {};
    int objectLength = reader.readVarUint();
    for (int i = 0; i < objectLength; i++) {
      var object = CoopFileObject()..deserialize(reader);
      objects[object.localId] = object;
    }
  }

  void serialize(BinaryWriter writer) {
    writer.writeVarUint(ownerId);
    writer.writeVarUint(fileId);

    writer.writeVarUint(objects.length);
    for (final object in objects.values) {
      object.serialize(writer);
    }
  }

  CoopFile clone() {
    var cloneObjects = <int, CoopFileObject>{};
    for (final object in objects.values) {
      var clone = object.clone();
      cloneObjects[clone.localId] = clone;
    }

    return CoopFile()
      ..ownerId = ownerId
      ..fileId = fileId
      ..objects = cloneObjects;
  }

  ChangeSet toChangeSet() {
    var changedObjects = <ObjectChanges>[];
    var id = CoopCommand.minChangeId;
    for (final object in objects.values) {
      if (object.serverChangeId > id) {
        id = object.serverChangeId;
      }
      changedObjects.add(object.toObjectCreationChanges());
    }
    for (final object in objects.values) {
      changedObjects.add(object.toObjectPropertyChanges());
    }
    var changeSet = ChangeSet()
      ..id = id
      ..objects = changedObjects;

    return changeSet;
  }
}

// Store session, nextObjectId, nextChange Id in Dynamo
class CoopFileObject extends Entity {
  /// The local id received from the session representing this object.
  int localId;

  Map<int, ObjectProperty> properties = {};

  void addProperty(ObjectProperty property) {
    properties[property.key] = property;
  }

  ObjectChanges toObjectCreationChanges() {
    var writer = BinaryWriter();
    writer.writeVarUint(key);

    return ObjectChanges()
      ..changes = [
        Change()
          ..op = CoreContext.addKey
          ..value = writer.uint8Buffer,
      ]
      ..objectId = localId;
  }

  ObjectChanges toObjectPropertyChanges() {
    var writer = BinaryWriter();
    writer.writeVarUint(key);

    return ObjectChanges()
      ..changes = properties.values
          .map(
            (prop) => Change()
              ..op = prop.key
              ..value = prop.data,
          )
          .toList(growable: false)
      ..objectId = localId;
  }

  @override
  void serialize(BinaryWriter writer) {
    super.serialize(writer);
    writer.writeVarInt(localId);

    writer.writeVarUint(properties.length);
    for (final prop in properties.values) {
      prop.serialize(writer);
    }
  }

  @override
  void deserialize(BinaryReader reader) {
    super.deserialize(reader);
    localId = reader.readVarInt();

    properties.clear();
    int propertyCount = reader.readVarUint();
    for (int i = 0; i < propertyCount; i++) {
      var prop = ObjectProperty()..deserialize(reader);
      properties[prop.key] = prop;
    }
  }

  CoopFileObject clone() {
    var clonedProperties = <int, ObjectProperty>{};
    for (final prop in properties.values) {
      var cp = prop.clone();
      clonedProperties[cp.key] = cp;
    }
    return CoopFileObject()
      ..localId = localId
      ..properties = clonedProperties
      ..copy(this);
  }
}

class CoopFileServerData {
  List<Session> sessions;
  int nextObjectId;
  int nextChangeId;

  void serialize(BinaryWriter writer) {
    writer.writeVarUint(sessions.length);
    for (final session in sessions) {
      session.serialize(writer);
    }
    writer.writeVarUint(nextObjectId);
    writer.writeVarUint(nextChangeId);
  }

  void deserialize(BinaryReader reader) {
    int sessionsCount = reader.readVarUint();
    sessions = List<Session>(sessionsCount);
    for (int i = 0; i < sessionsCount; i++) {
      sessions[i] = Session()..deserialize(reader);
    }
    nextObjectId = reader.readVarUint();
    nextChangeId = reader.readVarUint();
  }
}

class ObjectProperty extends Entity {
  /// The data value encoded in binary for this property.
  Uint8List data;

  @override
  void serialize(BinaryWriter writer) {
    super.serialize(writer);
    writer.writeVarUint(data.length);
    writer.write(data);
  }

  @override
  void deserialize(BinaryReader reader) {
    super.deserialize(reader);
    int numBytes = reader.readVarUint();
    data = reader.read(numBytes);
  }

  ObjectProperty clone() {
    return ObjectProperty()
      // should dupe this data?
      ..data = data
      ..copy(this);
  }
}
