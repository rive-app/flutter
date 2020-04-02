import 'dart:typed_data';

import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';
import 'package:core/coop/change.dart';
import 'package:core/coop/coop_command.dart';
import 'package:core/core.dart';
import 'package:core/coop/protocol_version.dart' show protocolVersion;

import 'entity.dart';

class CoopFile {
  int ownerId;
  int fileId;
  int nextClientId = 1;

  /// Monotonically increasing change id tracked on the server with the coop
  /// file. Initialize it to the minimum valid value.
  int serverChangeId = CoopCommand.minChangeId;

  Map<Id, CoopFileObject> objects;

  bool deserialize(BinaryReader reader) {
    if (reader.readVarUint() != protocolVersion) {
      return false;
    }
    nextClientId = reader.readVarUint();
    ownerId = reader.readVarUint();
    fileId = reader.readVarUint();
    serverChangeId = reader.readVarUint();

    objects = {};
    int objectLength = reader.readVarUint();
    for (int i = 0; i < objectLength; i++) {
      var object = CoopFileObject()..deserialize(reader);
      objects[object.objectId] = object;
    }
    return true;
  }

  void serialize(BinaryWriter writer) {
    writer.writeVarUint(protocolVersion);
    writer.writeVarUint(nextClientId);
    writer.writeVarUint(ownerId);
    writer.writeVarUint(fileId);
    writer.writeVarUint(serverChangeId);

    writer.writeVarUint(objects.length);
    for (final object in objects.values) {
      object.serialize(writer);
    }
  }

  CoopFile clone() {
    var cloneObjects = <Id, CoopFileObject>{};
    for (final object in objects.values) {
      var clone = object.clone();
      cloneObjects[clone.objectId] = clone;
    }

    return CoopFile()
      ..ownerId = ownerId
      ..fileId = fileId
      ..nextClientId = nextClientId
      ..serverChangeId = serverChangeId
      ..objects = cloneObjects;
  }

  ChangeSet toChangeSet() {
    var changedObjects = <ObjectChanges>[];
    var id = CoopCommand.minChangeId;
    if (serverChangeId > id) {
      id = serverChangeId;
    }
    for (final object in objects.values) {
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
  Id objectId;

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
      ..objectId = objectId;
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
      ..objectId = objectId;
  }

  @override
  void serialize(BinaryWriter writer) {
    super.serialize(writer);
    objectId.serialize(writer);

    writer.writeVarUint(properties.length);
    for (final prop in properties.values) {
      prop.serialize(writer);
    }
  }

  @override
  void deserialize(BinaryReader reader) {
    super.deserialize(reader);
    objectId = Id.deserialize(reader);

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
      ..objectId = objectId
      ..properties = clonedProperties
      ..copy(this);
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
