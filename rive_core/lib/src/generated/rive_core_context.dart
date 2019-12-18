import 'package:core/core.dart';
import 'artboard_base.dart';
import 'component_base.dart';
import 'node_base.dart';

class RiveCoreContext extends CoreContext {
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
