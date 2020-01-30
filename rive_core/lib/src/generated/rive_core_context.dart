import 'package:core/coop/change.dart';
import 'package:core/core.dart';
import 'package:binary_buffer/binary_reader.dart';
import 'package:binary_buffer/binary_writer.dart';

import '../../artboard.dart';
import '../../component.dart';
import '../../node.dart';
import 'artboard_base.dart';
import 'component_base.dart';
import 'node_base.dart';

abstract class RiveCoreContext extends CoreContext {
  RiveCoreContext(String fileId) : super(fileId);

  @override
  Core makeCoreInstance(int typeKey) {
    switch (typeKey) {
      case ArtboardBase.typeKey:
        return Artboard();
      case NodeBase.typeKey:
        return Node();
      default:
        return null;
    }
  }

  @override
  void applyCoopChanges(ObjectChanges objectChanges) {
    Core<CoreContext> object = resolve(objectChanges.objectId);
    var justAdded = false;
    for (final change in objectChanges.changes) {
      var reader = BinaryReader.fromList(change.value);
      switch (change.op) {
        case CoreContext.addKey:
          object = makeCoreInstance(reader.readVarInt())
            ..id = objectChanges.objectId;
          justAdded = true;
          break;
        case CoreContext.removeKey:
          if (object != null) {
            remove(object);
          } else {
            print("ATTEMPTED TO DELETE NULL OBJECT ${objectChanges.objectId}");
          }
          break;
        case ComponentBase.namePropertyKey:
          var value = reader.readString();
          setObjectProperty(object, change.op, value);
          break;
        case ComponentBase.parentIdPropertyKey:
          var value = reader.readVarInt();
          setObjectProperty(object, change.op, value);
          break;
        case ComponentBase.childOrderPropertyKey:
          var numerator = reader.readVarInt();
          var denominator = reader.readVarInt();
          var value = FractionalIndex(numerator, denominator);
          setObjectProperty(object, change.op, value);
          break;
        case ArtboardBase.widthPropertyKey:
        case ArtboardBase.heightPropertyKey:
        case ArtboardBase.xPropertyKey:
        case ArtboardBase.yPropertyKey:
        case ArtboardBase.originXPropertyKey:
        case ArtboardBase.originYPropertyKey:
        case NodeBase.xPropertyKey:
        case NodeBase.yPropertyKey:
        case NodeBase.rotationPropertyKey:
        case NodeBase.scaleXPropertyKey:
        case NodeBase.scaleYPropertyKey:
        case NodeBase.opacityPropertyKey:
          var value = reader.readFloat64();
          setObjectProperty(object, change.op, value);
          break;
        default:
          break;
      }
    }
    if (justAdded) {
      add(object);
    }
  }

  @override
  Change makeCoopChange(int propertyKey, Object value) {
    var change = Change()..op = propertyKey;
    switch (propertyKey) {
      case CoreContext.addKey:
      case CoreContext.removeKey:
        if (value != null && value is int) {
          var writer = BinaryWriter(alignment: 4);
          writer.writeVarInt(value);
          change.value = writer.uint8Buffer;
        }
        break;
      case ComponentBase.namePropertyKey:
        if (value != null && value is String) {
          var writer = BinaryWriter(alignment: 32);
          writer.writeString(value);
          change.value = writer.uint8Buffer;
        } else {
          return null;
        }
        break;
      case ComponentBase.parentIdPropertyKey:
        if (value != null && value is int) {
          var writer = BinaryWriter(alignment: 4);
          writer.writeVarInt(value);
          change.value = writer.uint8Buffer;
        } else {
          return null;
        }
        break;
      case ComponentBase.childOrderPropertyKey:
        if (value != null && value is FractionalIndex) {
          var writer = BinaryWriter(alignment: 8);
          writer.writeVarInt(value.numerator);
          writer.writeVarInt(value.denominator);
          change.value = writer.uint8Buffer;
        } else {
          return null;
        }
        break;
      case ArtboardBase.widthPropertyKey:
      case ArtboardBase.heightPropertyKey:
      case ArtboardBase.xPropertyKey:
      case ArtboardBase.yPropertyKey:
      case ArtboardBase.originXPropertyKey:
      case ArtboardBase.originYPropertyKey:
      case NodeBase.xPropertyKey:
      case NodeBase.yPropertyKey:
      case NodeBase.rotationPropertyKey:
      case NodeBase.scaleXPropertyKey:
      case NodeBase.scaleYPropertyKey:
      case NodeBase.opacityPropertyKey:
        if (value != null && value is double) {
          var writer = BinaryWriter(alignment: 8);
          writer.writeFloat64(value);
          change.value = writer.uint8Buffer;
        } else {
          return null;
        }
        break;
      default:
        break;
    }
    return change;
  }

  @override
  void setObjectProperty(Core object, int propertyKey, Object value) {
    switch (propertyKey) {
      case ComponentBase.namePropertyKey:
        if (object is ComponentBase && value is String) {
          object.name = value;
        }
        break;
      case ComponentBase.parentIdPropertyKey:
        if (object is ComponentBase && value is int) {
          object.parentId = value;
        }
        break;
      case ComponentBase.childOrderPropertyKey:
        if (object is ComponentBase && value is FractionalIndex) {
          object.childOrder = value;
        }
        break;
      case ArtboardBase.widthPropertyKey:
        if (object is ArtboardBase && value is double) {
          object.width = value;
        }
        break;
      case ArtboardBase.heightPropertyKey:
        if (object is ArtboardBase && value is double) {
          object.height = value;
        }
        break;
      case ArtboardBase.xPropertyKey:
        if (object is ArtboardBase && value is double) {
          object.x = value;
        }
        break;
      case ArtboardBase.yPropertyKey:
        if (object is ArtboardBase && value is double) {
          object.y = value;
        }
        break;
      case ArtboardBase.originXPropertyKey:
        if (object is ArtboardBase && value is double) {
          object.originX = value;
        }
        break;
      case ArtboardBase.originYPropertyKey:
        if (object is ArtboardBase && value is double) {
          object.originY = value;
        }
        break;
      case NodeBase.xPropertyKey:
        if (object is NodeBase && value is double) {
          object.x = value;
        }
        break;
      case NodeBase.yPropertyKey:
        if (object is NodeBase && value is double) {
          object.y = value;
        }
        break;
      case NodeBase.rotationPropertyKey:
        if (object is NodeBase && value is double) {
          object.rotation = value;
        }
        break;
      case NodeBase.scaleXPropertyKey:
        if (object is NodeBase && value is double) {
          object.scaleX = value;
        }
        break;
      case NodeBase.scaleYPropertyKey:
        if (object is NodeBase && value is double) {
          object.scaleY = value;
        }
        break;
      case NodeBase.opacityPropertyKey:
        if (object is NodeBase && value is double) {
          object.opacity = value;
        }
        break;
    }
  }

  @override
  Object getObjectProperty(Core object, int propertyKey) {
    switch (propertyKey) {
      case ComponentBase.namePropertyKey:
        if (object is ComponentBase) {
          return object.name;
        }
        break;
      case ComponentBase.parentIdPropertyKey:
        if (object is ComponentBase) {
          return object.parentId;
        }
        break;
      case ComponentBase.childOrderPropertyKey:
        if (object is ComponentBase) {
          return object.childOrder;
        }
        break;
      case ArtboardBase.widthPropertyKey:
        if (object is ArtboardBase) {
          return object.width;
        }
        break;
      case ArtboardBase.heightPropertyKey:
        if (object is ArtboardBase) {
          return object.height;
        }
        break;
      case ArtboardBase.xPropertyKey:
        if (object is ArtboardBase) {
          return object.x;
        }
        break;
      case ArtboardBase.yPropertyKey:
        if (object is ArtboardBase) {
          return object.y;
        }
        break;
      case ArtboardBase.originXPropertyKey:
        if (object is ArtboardBase) {
          return object.originX;
        }
        break;
      case ArtboardBase.originYPropertyKey:
        if (object is ArtboardBase) {
          return object.originY;
        }
        break;
      case NodeBase.xPropertyKey:
        if (object is NodeBase) {
          return object.x;
        }
        break;
      case NodeBase.yPropertyKey:
        if (object is NodeBase) {
          return object.y;
        }
        break;
      case NodeBase.rotationPropertyKey:
        if (object is NodeBase) {
          return object.rotation;
        }
        break;
      case NodeBase.scaleXPropertyKey:
        if (object is NodeBase) {
          return object.scaleX;
        }
        break;
      case NodeBase.scaleYPropertyKey:
        if (object is NodeBase) {
          return object.scaleY;
        }
        break;
      case NodeBase.opacityPropertyKey:
        if (object is NodeBase) {
          return object.opacity;
        }
        break;
    }
    return null;
  }
}
