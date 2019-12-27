import 'package:core/coop/change.dart';
import 'package:core/core.dart';
import 'package:binary_buffer/binary_writer.dart';

import 'artboard_base.dart';
import 'component_base.dart';
import 'node_base.dart';

abstract class RiveCoreContext extends CoreContext {
  RiveCoreContext(String fileId) : super(fileId);

  @override
  Change makeCoopChange(int propertyKey, Object value) {
    var change = Change()..op = propertyKey;
    switch (propertyKey) {
      case CoreContext.addKey:
      case CoreContext.removeKey:
        change.op = value as int;
        break;
      case ArtboardBase.namePropertyKey:
      case ComponentBase.namePropertyKey:
        if (value != null && value is String) {
          var writer = BinaryWriter(alignment: 32);
          writer.writeString(value);
          change.value = writer.uint8Buffer;
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
        }
        break;
      case ComponentBase.parentPropertyKey:
      case ComponentBase.orderPropertyKey:
        if (value != null && value is int) {
          var writer = BinaryWriter(alignment: 4);
          writer.writeVarInt(value);
          change.value = writer.uint8Buffer;
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
      case ArtboardBase.namePropertyKey:
        if (object is ArtboardBase) {
          if (value is String) {
            object.name = value;
          } else if (value == null) {
            object.name = null;
          }
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
      case ComponentBase.namePropertyKey:
        if (object is ComponentBase && value is String) {
          object.name = value;
        }
        break;
      case ComponentBase.parentPropertyKey:
        if (object is ComponentBase && value is int) {
          object.parent = value;
        }
        break;
      case ComponentBase.orderPropertyKey:
        if (object is ComponentBase && value is int) {
          object.order = value;
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
}
