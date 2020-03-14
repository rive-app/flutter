import 'package:core/coop/change.dart';
import 'package:core/core.dart';
import 'package:binary_buffer/binary_reader.dart';
import 'package:binary_buffer/binary_writer.dart';

import '../../artboard.dart';
import '../../node.dart';
import '../../shapes/cubic_vertex.dart';
import '../../shapes/ellipse.dart';
import '../../shapes/paint/fill.dart';
import '../../shapes/paint/gradient_stop.dart';
import '../../shapes/paint/linear_gradient.dart';
import '../../shapes/paint/radial_gradient.dart';
import '../../shapes/paint/solid_color.dart';
import '../../shapes/path_composer.dart';
import '../../shapes/points_path.dart';
import '../../shapes/rectangle.dart';
import '../../shapes/shape.dart';
import '../../shapes/straight_vertex.dart';
import '../../shapes/triangle.dart';
import 'artboard_base.dart';
import 'component_base.dart';
import 'drawable_base.dart';
import 'node_base.dart';
import 'shapes/cubic_vertex_base.dart';
import 'shapes/ellipse_base.dart';
import 'shapes/paint/fill_base.dart';
import 'shapes/paint/gradient_stop_base.dart';
import 'shapes/paint/linear_gradient_base.dart';
import 'shapes/paint/radial_gradient_base.dart';
import 'shapes/paint/shape_paint_base.dart';
import 'shapes/paint/solid_color_base.dart';
import 'shapes/parametric_path_base.dart';
import 'shapes/path_composer_base.dart';
import 'shapes/path_vertex_base.dart';
import 'shapes/points_path_base.dart';
import 'shapes/rectangle_base.dart';
import 'shapes/shape_base.dart';
import 'shapes/straight_vertex_base.dart';
import 'shapes/triangle_base.dart';

abstract class RiveCoreContext extends CoreContext {
  RiveCoreContext(String fileId) : super(fileId);

  @override
  Core makeCoreInstance(int typeKey) {
    switch (typeKey) {
      case LinearGradientBase.typeKey:
        return LinearGradient();
      case RadialGradientBase.typeKey:
        return RadialGradient();
      case SolidColorBase.typeKey:
        return SolidColor();
      case GradientStopBase.typeKey:
        return GradientStop();
      case FillBase.typeKey:
        return Fill();
      case NodeBase.typeKey:
        return Node();
      case ShapeBase.typeKey:
        return Shape();
      case StraightVertexBase.typeKey:
        return StraightVertex();
      case PointsPathBase.typeKey:
        return PointsPath();
      case RectangleBase.typeKey:
        return Rectangle();
      case CubicVertexBase.typeKey:
        return CubicVertex();
      case TriangleBase.typeKey:
        return Triangle();
      case EllipseBase.typeKey:
        return Ellipse();
      case PathComposerBase.typeKey:
        return PathComposer();
      case ArtboardBase.typeKey:
        return Artboard();
      default:
        return null;
    }
  }

  @override
  bool isPropertyId(int propertyKey) {
    switch (propertyKey) {
      case ComponentBase.parentIdPropertyKey:
        return true;
      default:
        return false;
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
          // make sure object doesn't exist (we propagate changes to all
          // clients, so we'll receive our own adds which will result in
          // duplicates if we don't check here).
          if (object == null) {
            object = makeCoreInstance(reader.readVarInt());
            if (object != null) {
              object.id = objectChanges.objectId;
              justAdded = true;
            }
          }
          break;
        case CoreContext.removeKey:
          // Don't remove null objects. This can happen as we acknowledge
          // changes, so we'll attempt to delete an object we ourselves have
          // already deleted.
          if (object != null) {
            remove(object);
          }
          break;
        case ComponentBase.dependentIdsPropertyKey:
          var value = List<Id>(reader.readVarUint());
          for (int i = 0; i < value.length; i++) {
            value[i] = Id.deserialize(reader);
          }
          setObjectProperty(object, change.op, value);
          break;
        case ComponentBase.namePropertyKey:
          var value = reader.readString();
          setObjectProperty(object, change.op, value);
          break;
        case ComponentBase.parentIdPropertyKey:
          var value = Id.deserialize(reader);
          setObjectProperty(object, change.op, value);
          break;
        case ComponentBase.childOrderPropertyKey:
        case DrawableBase.drawOrderPropertyKey:
          var numerator = reader.readVarInt();
          var denominator = reader.readVarInt();
          var value = FractionalIndex(numerator, denominator);
          setObjectProperty(object, change.op, value);
          break;
        case ShapePaintBase.isVisiblePropertyKey:
        case ShapeBase.transformAffectsStrokePropertyKey:
        case PointsPathBase.isClosedPropertyKey:
          var value = reader.readInt8() == 1;
          setObjectProperty(object, change.op, value);
          break;
        case LinearGradientBase.startXPropertyKey:
        case LinearGradientBase.startYPropertyKey:
        case LinearGradientBase.endXPropertyKey:
        case LinearGradientBase.endYPropertyKey:
        case RadialGradientBase.radiusPropertyKey:
        case GradientStopBase.positionPropertyKey:
        case NodeBase.xPropertyKey:
        case NodeBase.yPropertyKey:
        case NodeBase.rotationPropertyKey:
        case NodeBase.scaleXPropertyKey:
        case NodeBase.scaleYPropertyKey:
        case NodeBase.opacityPropertyKey:
        case PathVertexBase.xPropertyKey:
        case PathVertexBase.yPropertyKey:
        case StraightVertexBase.radiusPropertyKey:
        case ParametricPathBase.widthPropertyKey:
        case ParametricPathBase.heightPropertyKey:
        case RectangleBase.cornerRadiusPropertyKey:
        case CubicVertexBase.inXPropertyKey:
        case CubicVertexBase.inYPropertyKey:
        case CubicVertexBase.outXPropertyKey:
        case CubicVertexBase.outYPropertyKey:
        case ArtboardBase.widthPropertyKey:
        case ArtboardBase.heightPropertyKey:
        case ArtboardBase.xPropertyKey:
        case ArtboardBase.yPropertyKey:
        case ArtboardBase.originXPropertyKey:
        case ArtboardBase.originYPropertyKey:
          var value = reader.readFloat64();
          setObjectProperty(object, change.op, value);
          break;
        case SolidColorBase.colorValuePropertyKey:
        case GradientStopBase.colorValuePropertyKey:
        case FillBase.fillRulePropertyKey:
        case DrawableBase.blendModePropertyKey:
          var value = reader.readVarInt();
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
      case ComponentBase.dependentIdsPropertyKey:
        if (value != null && value is List<Id>) {
          var writer = BinaryWriter(alignment: 8);
          writer.writeVarUint(value.length);
          for (final id in value) {
            id.serialize(writer);
          }
          change.value = writer.uint8Buffer;
        } else {
          return null;
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
        if (value != null && value is Id) {
          var writer = BinaryWriter(alignment: 4);
          value.serialize(writer);
          change.value = writer.uint8Buffer;
        } else {
          return null;
        }
        break;
      case ComponentBase.childOrderPropertyKey:
      case DrawableBase.drawOrderPropertyKey:
        if (value != null && value is FractionalIndex) {
          var writer = BinaryWriter(alignment: 8);
          writer.writeVarInt(value.numerator);
          writer.writeVarInt(value.denominator);
          change.value = writer.uint8Buffer;
        } else {
          return null;
        }
        break;
      case ShapePaintBase.isVisiblePropertyKey:
      case ShapeBase.transformAffectsStrokePropertyKey:
      case PointsPathBase.isClosedPropertyKey:
        if (value != null && value is bool) {
          var writer = BinaryWriter(alignment: 1);
          writer.writeInt8(value ? 1 : 0);
          change.value = writer.uint8Buffer;
        } else {
          return null;
        }
        break;
      case LinearGradientBase.startXPropertyKey:
      case LinearGradientBase.startYPropertyKey:
      case LinearGradientBase.endXPropertyKey:
      case LinearGradientBase.endYPropertyKey:
      case RadialGradientBase.radiusPropertyKey:
      case GradientStopBase.positionPropertyKey:
      case NodeBase.xPropertyKey:
      case NodeBase.yPropertyKey:
      case NodeBase.rotationPropertyKey:
      case NodeBase.scaleXPropertyKey:
      case NodeBase.scaleYPropertyKey:
      case NodeBase.opacityPropertyKey:
      case PathVertexBase.xPropertyKey:
      case PathVertexBase.yPropertyKey:
      case StraightVertexBase.radiusPropertyKey:
      case ParametricPathBase.widthPropertyKey:
      case ParametricPathBase.heightPropertyKey:
      case RectangleBase.cornerRadiusPropertyKey:
      case CubicVertexBase.inXPropertyKey:
      case CubicVertexBase.inYPropertyKey:
      case CubicVertexBase.outXPropertyKey:
      case CubicVertexBase.outYPropertyKey:
      case ArtboardBase.widthPropertyKey:
      case ArtboardBase.heightPropertyKey:
      case ArtboardBase.xPropertyKey:
      case ArtboardBase.yPropertyKey:
      case ArtboardBase.originXPropertyKey:
      case ArtboardBase.originYPropertyKey:
        if (value != null && value is double) {
          var writer = BinaryWriter(alignment: 8);
          writer.writeFloat64(value);
          change.value = writer.uint8Buffer;
        } else {
          return null;
        }
        break;
      case SolidColorBase.colorValuePropertyKey:
      case GradientStopBase.colorValuePropertyKey:
      case FillBase.fillRulePropertyKey:
      case DrawableBase.blendModePropertyKey:
        if (value != null && value is int) {
          var writer = BinaryWriter(alignment: 4);
          writer.writeVarInt(value);
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
      case ComponentBase.dependentIdsPropertyKey:
        if (object is ComponentBase && value is List<Id>) {
          object.dependentIds = value;
        }
        break;
      case ComponentBase.namePropertyKey:
        if (object is ComponentBase && value is String) {
          object.name = value;
        }
        break;
      case ComponentBase.parentIdPropertyKey:
        if (object is ComponentBase && value is Id) {
          object.parentId = value;
        }
        break;
      case ComponentBase.childOrderPropertyKey:
        if (object is ComponentBase && value is FractionalIndex) {
          object.childOrder = value;
        }
        break;
      case ShapePaintBase.isVisiblePropertyKey:
        if (object is ShapePaintBase && value is bool) {
          object.isVisible = value;
        }
        break;
      case LinearGradientBase.startXPropertyKey:
        if (object is LinearGradientBase && value is double) {
          object.startX = value;
        }
        break;
      case LinearGradientBase.startYPropertyKey:
        if (object is LinearGradientBase && value is double) {
          object.startY = value;
        }
        break;
      case LinearGradientBase.endXPropertyKey:
        if (object is LinearGradientBase && value is double) {
          object.endX = value;
        }
        break;
      case LinearGradientBase.endYPropertyKey:
        if (object is LinearGradientBase && value is double) {
          object.endY = value;
        }
        break;
      case RadialGradientBase.radiusPropertyKey:
        if (object is RadialGradientBase && value is double) {
          object.radius = value;
        }
        break;
      case SolidColorBase.colorValuePropertyKey:
        if (object is SolidColorBase && value is int) {
          object.colorValue = value;
        }
        break;
      case GradientStopBase.colorValuePropertyKey:
        if (object is GradientStopBase && value is int) {
          object.colorValue = value;
        }
        break;
      case GradientStopBase.positionPropertyKey:
        if (object is GradientStopBase && value is double) {
          object.position = value;
        }
        break;
      case FillBase.fillRulePropertyKey:
        if (object is FillBase && value is int) {
          object.fillRule = value;
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
      case DrawableBase.drawOrderPropertyKey:
        if (object is DrawableBase && value is FractionalIndex) {
          object.drawOrder = value;
        }
        break;
      case DrawableBase.blendModePropertyKey:
        if (object is DrawableBase && value is int) {
          object.blendMode = value;
        }
        break;
      case ShapeBase.transformAffectsStrokePropertyKey:
        if (object is ShapeBase && value is bool) {
          object.transformAffectsStroke = value;
        }
        break;
      case PathVertexBase.xPropertyKey:
        if (object is PathVertexBase && value is double) {
          object.x = value;
        }
        break;
      case PathVertexBase.yPropertyKey:
        if (object is PathVertexBase && value is double) {
          object.y = value;
        }
        break;
      case StraightVertexBase.radiusPropertyKey:
        if (object is StraightVertexBase && value is double) {
          object.radius = value;
        }
        break;
      case PointsPathBase.isClosedPropertyKey:
        if (object is PointsPathBase && value is bool) {
          object.isClosed = value;
        }
        break;
      case ParametricPathBase.widthPropertyKey:
        if (object is ParametricPathBase && value is double) {
          object.width = value;
        }
        break;
      case ParametricPathBase.heightPropertyKey:
        if (object is ParametricPathBase && value is double) {
          object.height = value;
        }
        break;
      case RectangleBase.cornerRadiusPropertyKey:
        if (object is RectangleBase && value is double) {
          object.cornerRadius = value;
        }
        break;
      case CubicVertexBase.inXPropertyKey:
        if (object is CubicVertexBase && value is double) {
          object.inX = value;
        }
        break;
      case CubicVertexBase.inYPropertyKey:
        if (object is CubicVertexBase && value is double) {
          object.inY = value;
        }
        break;
      case CubicVertexBase.outXPropertyKey:
        if (object is CubicVertexBase && value is double) {
          object.outX = value;
        }
        break;
      case CubicVertexBase.outYPropertyKey:
        if (object is CubicVertexBase && value is double) {
          object.outY = value;
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
    }
  }

  @override
  Object getObjectProperty(Core object, int propertyKey) {
    switch (propertyKey) {
      case ComponentBase.dependentIdsPropertyKey:
        if (object is ComponentBase) {
          return object.dependentIds;
        }
        break;
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
      case ShapePaintBase.isVisiblePropertyKey:
        if (object is ShapePaintBase) {
          return object.isVisible;
        }
        break;
      case LinearGradientBase.startXPropertyKey:
        if (object is LinearGradientBase) {
          return object.startX;
        }
        break;
      case LinearGradientBase.startYPropertyKey:
        if (object is LinearGradientBase) {
          return object.startY;
        }
        break;
      case LinearGradientBase.endXPropertyKey:
        if (object is LinearGradientBase) {
          return object.endX;
        }
        break;
      case LinearGradientBase.endYPropertyKey:
        if (object is LinearGradientBase) {
          return object.endY;
        }
        break;
      case RadialGradientBase.radiusPropertyKey:
        if (object is RadialGradientBase) {
          return object.radius;
        }
        break;
      case SolidColorBase.colorValuePropertyKey:
        if (object is SolidColorBase) {
          return object.colorValue;
        }
        break;
      case GradientStopBase.colorValuePropertyKey:
        if (object is GradientStopBase) {
          return object.colorValue;
        }
        break;
      case GradientStopBase.positionPropertyKey:
        if (object is GradientStopBase) {
          return object.position;
        }
        break;
      case FillBase.fillRulePropertyKey:
        if (object is FillBase) {
          return object.fillRule;
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
      case DrawableBase.drawOrderPropertyKey:
        if (object is DrawableBase) {
          return object.drawOrder;
        }
        break;
      case DrawableBase.blendModePropertyKey:
        if (object is DrawableBase) {
          return object.blendMode;
        }
        break;
      case ShapeBase.transformAffectsStrokePropertyKey:
        if (object is ShapeBase) {
          return object.transformAffectsStroke;
        }
        break;
      case PathVertexBase.xPropertyKey:
        if (object is PathVertexBase) {
          return object.x;
        }
        break;
      case PathVertexBase.yPropertyKey:
        if (object is PathVertexBase) {
          return object.y;
        }
        break;
      case StraightVertexBase.radiusPropertyKey:
        if (object is StraightVertexBase) {
          return object.radius;
        }
        break;
      case PointsPathBase.isClosedPropertyKey:
        if (object is PointsPathBase) {
          return object.isClosed;
        }
        break;
      case ParametricPathBase.widthPropertyKey:
        if (object is ParametricPathBase) {
          return object.width;
        }
        break;
      case ParametricPathBase.heightPropertyKey:
        if (object is ParametricPathBase) {
          return object.height;
        }
        break;
      case RectangleBase.cornerRadiusPropertyKey:
        if (object is RectangleBase) {
          return object.cornerRadius;
        }
        break;
      case CubicVertexBase.inXPropertyKey:
        if (object is CubicVertexBase) {
          return object.inX;
        }
        break;
      case CubicVertexBase.inYPropertyKey:
        if (object is CubicVertexBase) {
          return object.inY;
        }
        break;
      case CubicVertexBase.outXPropertyKey:
        if (object is CubicVertexBase) {
          return object.outX;
        }
        break;
      case CubicVertexBase.outYPropertyKey:
        if (object is CubicVertexBase) {
          return object.outY;
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
    }
    return null;
  }
}
