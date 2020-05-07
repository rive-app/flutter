import 'package:core/coop/change.dart';
import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:core/key_state.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

import '../../animation/animation.dart';
import '../../animation/cubic_interpolator.dart';
import '../../animation/keyed_object.dart';
import '../../animation/keyed_property.dart';
import '../../animation/keyframe_double.dart';
import '../../animation/linear_animation.dart';
import '../../artboard.dart';
import '../../backboard.dart';
import '../../node.dart';
import '../../shapes/cubic_vertex.dart';
import '../../shapes/ellipse.dart';
import '../../shapes/paint/fill.dart';
import '../../shapes/paint/gradient_stop.dart';
import '../../shapes/paint/linear_gradient.dart';
import '../../shapes/paint/radial_gradient.dart';
import '../../shapes/paint/solid_color.dart';
import '../../shapes/paint/stroke.dart';
import '../../shapes/path_composer.dart';
import '../../shapes/points_path.dart';
import '../../shapes/rectangle.dart';
import '../../shapes/shape.dart';
import '../../shapes/straight_vertex.dart';
import '../../shapes/triangle.dart';
import 'animation/animation_base.dart';
import 'animation/cubic_interpolator_base.dart';
import 'animation/keyed_object_base.dart';
import 'animation/keyed_property_base.dart';
import 'animation/keyframe_base.dart';
import 'animation/keyframe_double_base.dart';
import 'animation/linear_animation_base.dart';
import 'artboard_base.dart';
import 'backboard_base.dart';
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
import 'shapes/paint/stroke_base.dart';
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
      case KeyedObjectBase.typeKey:
        return KeyedObject();
      case KeyedPropertyBase.typeKey:
        return KeyedProperty();
      case AnimationBase.typeKey:
        return Animation();
      case CubicInterpolatorBase.typeKey:
        return CubicInterpolator();
      case KeyFrameDoubleBase.typeKey:
        return KeyFrameDouble();
      case LinearAnimationBase.typeKey:
        return LinearAnimation();
      case LinearGradientBase.typeKey:
        return LinearGradient();
      case RadialGradientBase.typeKey:
        return RadialGradient();
      case StrokeBase.typeKey:
        return Stroke();
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
      case BackboardBase.typeKey:
        return Backboard();
      default:
        return null;
    }
  }

  /// Get an integer representing the group for this property. Use this to
  /// quickly hash groups of properties together and use the string version to
  /// key labels/names from.
  static int propertyKeyGroupHashCode(int propertyKey) {
    switch (propertyKey) {
      case NodeBase.xPropertyKey:
      case NodeBase.yPropertyKey:
        return 1;
      case NodeBase.scaleXPropertyKey:
      case NodeBase.scaleYPropertyKey:
        return 2;
      default:
        return 0;
    }
  }

  static String propertyKeyGroupName(int propertyKey) {
    switch (propertyKey) {
      case NodeBase.xPropertyKey:
      case NodeBase.yPropertyKey:
        return 'position';
      case NodeBase.scaleXPropertyKey:
      case NodeBase.scaleYPropertyKey:
        return 'scale';
      default:
        return null;
    }
  }

  static String propertyKeyName(int propertyKey) {
    switch (propertyKey) {
      case KeyedObjectBase.objectIdPropertyKey:
        return 'objectId';
      case KeyedObjectBase.animationIdPropertyKey:
        return 'animationId';
      case KeyedPropertyBase.keyedObjectIdPropertyKey:
        return 'keyedObjectId';
      case KeyedPropertyBase.propertyKeyPropertyKey:
        return 'propertyKey';
      case AnimationBase.artboardIdPropertyKey:
        return 'artboardId';
      case AnimationBase.namePropertyKey:
        return 'name';
      case AnimationBase.orderPropertyKey:
        return 'order';
      case CubicInterpolatorBase.x1PropertyKey:
        return 'x1';
      case CubicInterpolatorBase.y1PropertyKey:
        return 'y1';
      case CubicInterpolatorBase.x2PropertyKey:
        return 'x2';
      case CubicInterpolatorBase.y2PropertyKey:
        return 'y2';
      case KeyFrameBase.keyedPropertyIdPropertyKey:
        return 'keyedPropertyId';
      case KeyFrameBase.framePropertyKey:
        return 'frame';
      case KeyFrameBase.interpolationPropertyKey:
        return 'interpolation';
      case KeyFrameBase.interpolatorIdPropertyKey:
        return 'interpolatorId';
      case KeyFrameDoubleBase.valuePropertyKey:
        return 'value';
      case LinearAnimationBase.fpsPropertyKey:
        return 'fps';
      case LinearAnimationBase.durationPropertyKey:
        return 'duration';
      case LinearAnimationBase.speedPropertyKey:
        return 'speed';
      case LinearAnimationBase.loopValuePropertyKey:
        return 'loopValue';
      case LinearAnimationBase.workStartPropertyKey:
        return 'workStart';
      case LinearAnimationBase.workEndPropertyKey:
        return 'workEnd';
      case LinearAnimationBase.enableWorkAreaPropertyKey:
        return 'enableWorkArea';
      case ComponentBase.dependentIdsPropertyKey:
        return 'dependentIds';
      case ComponentBase.namePropertyKey:
        return 'name';
      case ComponentBase.parentIdPropertyKey:
        return 'parentId';
      case ComponentBase.childOrderPropertyKey:
        return 'childOrder';
      case ShapePaintBase.isVisiblePropertyKey:
        return 'isVisible';
      case LinearGradientBase.startXPropertyKey:
        return 'startX';
      case LinearGradientBase.startYPropertyKey:
        return 'startY';
      case LinearGradientBase.endXPropertyKey:
        return 'endX';
      case LinearGradientBase.endYPropertyKey:
        return 'endY';
      case LinearGradientBase.opacityPropertyKey:
        return 'opacity';
      case StrokeBase.thicknessPropertyKey:
        return 'thickness';
      case StrokeBase.capPropertyKey:
        return 'cap';
      case StrokeBase.joinPropertyKey:
        return 'join';
      case StrokeBase.transformAffectsStrokePropertyKey:
        return 'transformAffectsStroke';
      case SolidColorBase.colorValuePropertyKey:
        return 'colorValue';
      case GradientStopBase.colorValuePropertyKey:
        return 'colorValue';
      case GradientStopBase.positionPropertyKey:
        return 'position';
      case FillBase.fillRulePropertyKey:
        return 'fillRule';
      case NodeBase.xPropertyKey:
        return 'x';
      case NodeBase.yPropertyKey:
        return 'y';
      case NodeBase.rotationPropertyKey:
        return 'rotation';
      case NodeBase.scaleXPropertyKey:
        return 'scaleX';
      case NodeBase.scaleYPropertyKey:
        return 'scaleY';
      case NodeBase.opacityPropertyKey:
        return 'opacity';
      case DrawableBase.drawOrderPropertyKey:
        return 'drawOrder';
      case DrawableBase.blendModePropertyKey:
        return 'blendMode';
      case PathVertexBase.xPropertyKey:
        return 'x';
      case PathVertexBase.yPropertyKey:
        return 'y';
      case StraightVertexBase.radiusPropertyKey:
        return 'radius';
      case PointsPathBase.isClosedPropertyKey:
        return 'isClosed';
      case ParametricPathBase.widthPropertyKey:
        return 'width';
      case ParametricPathBase.heightPropertyKey:
        return 'height';
      case RectangleBase.cornerRadiusPropertyKey:
        return 'cornerRadius';
      case CubicVertexBase.inXPropertyKey:
        return 'inX';
      case CubicVertexBase.inYPropertyKey:
        return 'inY';
      case CubicVertexBase.outXPropertyKey:
        return 'outX';
      case CubicVertexBase.outYPropertyKey:
        return 'outY';
      case ArtboardBase.widthPropertyKey:
        return 'width';
      case ArtboardBase.heightPropertyKey:
        return 'height';
      case ArtboardBase.xPropertyKey:
        return 'x';
      case ArtboardBase.yPropertyKey:
        return 'y';
      case ArtboardBase.originXPropertyKey:
        return 'originX';
      case ArtboardBase.originYPropertyKey:
        return 'originY';
      case BackboardBase.activeArtboardIdPropertyKey:
        return 'activeArtboardId';
      case BackboardBase.mainArtboardIdPropertyKey:
        return 'mainArtboardId';
      case BackboardBase.colorValuePropertyKey:
        return 'colorValue';
      default:
        return null;
    }
  }

  CoreIdType get idType;
  CoreIntType get intType;
  CoreStringType get stringType;
  CoreFractionalIndexType get fractionalIndexType;
  CoreDoubleType get doubleType;
  CoreBoolType get boolType;
  CoreListIdType get listIdType;

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
        case KeyedObjectBase.objectIdPropertyKey:
        case KeyedObjectBase.animationIdPropertyKey:
        case KeyedPropertyBase.keyedObjectIdPropertyKey:
        case AnimationBase.artboardIdPropertyKey:
        case KeyFrameBase.keyedPropertyIdPropertyKey:
        case KeyFrameBase.interpolatorIdPropertyKey:
        case ComponentBase.parentIdPropertyKey:
        case BackboardBase.activeArtboardIdPropertyKey:
        case BackboardBase.mainArtboardIdPropertyKey:
          var value = idType.deserialize(reader);
          setId(object, change.op, value);
          break;
        case KeyedPropertyBase.propertyKeyPropertyKey:
        case KeyFrameBase.framePropertyKey:
        case KeyFrameBase.interpolationPropertyKey:
        case LinearAnimationBase.fpsPropertyKey:
        case LinearAnimationBase.durationPropertyKey:
        case LinearAnimationBase.loopValuePropertyKey:
        case LinearAnimationBase.workStartPropertyKey:
        case LinearAnimationBase.workEndPropertyKey:
        case StrokeBase.capPropertyKey:
        case StrokeBase.joinPropertyKey:
        case SolidColorBase.colorValuePropertyKey:
        case GradientStopBase.colorValuePropertyKey:
        case FillBase.fillRulePropertyKey:
        case DrawableBase.blendModePropertyKey:
        case BackboardBase.colorValuePropertyKey:
          var value = intType.deserialize(reader);
          setInt(object, change.op, value);
          break;
        case AnimationBase.namePropertyKey:
        case ComponentBase.namePropertyKey:
          var value = stringType.deserialize(reader);
          setString(object, change.op, value);
          break;
        case AnimationBase.orderPropertyKey:
        case ComponentBase.childOrderPropertyKey:
        case DrawableBase.drawOrderPropertyKey:
          var value = fractionalIndexType.deserialize(reader);
          setFractionalIndex(object, change.op, value);
          break;
        case CubicInterpolatorBase.x1PropertyKey:
        case CubicInterpolatorBase.y1PropertyKey:
        case CubicInterpolatorBase.x2PropertyKey:
        case CubicInterpolatorBase.y2PropertyKey:
        case KeyFrameDoubleBase.valuePropertyKey:
        case LinearAnimationBase.speedPropertyKey:
        case LinearGradientBase.startXPropertyKey:
        case LinearGradientBase.startYPropertyKey:
        case LinearGradientBase.endXPropertyKey:
        case LinearGradientBase.endYPropertyKey:
        case LinearGradientBase.opacityPropertyKey:
        case StrokeBase.thicknessPropertyKey:
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
          var value = doubleType.deserialize(reader);
          setDouble(object, change.op, value);
          break;
        case LinearAnimationBase.enableWorkAreaPropertyKey:
        case ShapePaintBase.isVisiblePropertyKey:
        case StrokeBase.transformAffectsStrokePropertyKey:
        case PointsPathBase.isClosedPropertyKey:
          var value = boolType.deserialize(reader);
          setBool(object, change.op, value);
          break;
        case ComponentBase.dependentIdsPropertyKey:
          var value = listIdType.deserialize(reader);
          setListId(object, change.op, value);
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
      case KeyedObjectBase.objectIdPropertyKey:
      case KeyedObjectBase.animationIdPropertyKey:
      case KeyedPropertyBase.keyedObjectIdPropertyKey:
      case AnimationBase.artboardIdPropertyKey:
      case KeyFrameBase.keyedPropertyIdPropertyKey:
      case KeyFrameBase.interpolatorIdPropertyKey:
      case ComponentBase.parentIdPropertyKey:
      case BackboardBase.activeArtboardIdPropertyKey:
      case BackboardBase.mainArtboardIdPropertyKey:
        if (value != null && value is Id) {
          change.value = idType.serialize(value);
        } else {
          return null;
        }
        break;
      case KeyedPropertyBase.propertyKeyPropertyKey:
      case KeyFrameBase.framePropertyKey:
      case KeyFrameBase.interpolationPropertyKey:
      case LinearAnimationBase.fpsPropertyKey:
      case LinearAnimationBase.durationPropertyKey:
      case LinearAnimationBase.loopValuePropertyKey:
      case LinearAnimationBase.workStartPropertyKey:
      case LinearAnimationBase.workEndPropertyKey:
      case StrokeBase.capPropertyKey:
      case StrokeBase.joinPropertyKey:
      case SolidColorBase.colorValuePropertyKey:
      case GradientStopBase.colorValuePropertyKey:
      case FillBase.fillRulePropertyKey:
      case DrawableBase.blendModePropertyKey:
      case BackboardBase.colorValuePropertyKey:
        if (value != null && value is int) {
          change.value = intType.serialize(value);
        } else {
          return null;
        }
        break;
      case AnimationBase.namePropertyKey:
      case ComponentBase.namePropertyKey:
        if (value != null && value is String) {
          change.value = stringType.serialize(value);
        } else {
          return null;
        }
        break;
      case AnimationBase.orderPropertyKey:
      case ComponentBase.childOrderPropertyKey:
      case DrawableBase.drawOrderPropertyKey:
        if (value != null && value is FractionalIndex) {
          change.value = fractionalIndexType.serialize(value);
        } else {
          return null;
        }
        break;
      case CubicInterpolatorBase.x1PropertyKey:
      case CubicInterpolatorBase.y1PropertyKey:
      case CubicInterpolatorBase.x2PropertyKey:
      case CubicInterpolatorBase.y2PropertyKey:
      case KeyFrameDoubleBase.valuePropertyKey:
      case LinearAnimationBase.speedPropertyKey:
      case LinearGradientBase.startXPropertyKey:
      case LinearGradientBase.startYPropertyKey:
      case LinearGradientBase.endXPropertyKey:
      case LinearGradientBase.endYPropertyKey:
      case LinearGradientBase.opacityPropertyKey:
      case StrokeBase.thicknessPropertyKey:
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
          change.value = doubleType.serialize(value);
        } else {
          return null;
        }
        break;
      case LinearAnimationBase.enableWorkAreaPropertyKey:
      case ShapePaintBase.isVisiblePropertyKey:
      case StrokeBase.transformAffectsStrokePropertyKey:
      case PointsPathBase.isClosedPropertyKey:
        if (value != null && value is bool) {
          change.value = boolType.serialize(value);
        } else {
          return null;
        }
        break;
      case ComponentBase.dependentIdsPropertyKey:
        if (value != null && value is List<Id>) {
          change.value = listIdType.serialize(value);
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
      case KeyedObjectBase.objectIdPropertyKey:
        if (object is KeyedObjectBase && value is Id) {
          object.objectId = value;
        }
        break;
      case KeyedObjectBase.animationIdPropertyKey:
        if (object is KeyedObjectBase && value is Id) {
          object.animationId = value;
        }
        break;
      case KeyedPropertyBase.keyedObjectIdPropertyKey:
        if (object is KeyedPropertyBase && value is Id) {
          object.keyedObjectId = value;
        }
        break;
      case KeyedPropertyBase.propertyKeyPropertyKey:
        if (object is KeyedPropertyBase && value is int) {
          object.propertyKey = value;
        }
        break;
      case AnimationBase.artboardIdPropertyKey:
        if (object is AnimationBase && value is Id) {
          object.artboardId = value;
        }
        break;
      case AnimationBase.namePropertyKey:
        if (object is AnimationBase && value is String) {
          object.name = value;
        }
        break;
      case AnimationBase.orderPropertyKey:
        if (object is AnimationBase && value is FractionalIndex) {
          object.order = value;
        }
        break;
      case CubicInterpolatorBase.x1PropertyKey:
        if (object is CubicInterpolatorBase && value is double) {
          object.x1 = value;
        }
        break;
      case CubicInterpolatorBase.y1PropertyKey:
        if (object is CubicInterpolatorBase && value is double) {
          object.y1 = value;
        }
        break;
      case CubicInterpolatorBase.x2PropertyKey:
        if (object is CubicInterpolatorBase && value is double) {
          object.x2 = value;
        }
        break;
      case CubicInterpolatorBase.y2PropertyKey:
        if (object is CubicInterpolatorBase && value is double) {
          object.y2 = value;
        }
        break;
      case KeyFrameBase.keyedPropertyIdPropertyKey:
        if (object is KeyFrameBase && value is Id) {
          object.keyedPropertyId = value;
        }
        break;
      case KeyFrameBase.framePropertyKey:
        if (object is KeyFrameBase && value is int) {
          object.frame = value;
        }
        break;
      case KeyFrameBase.interpolationPropertyKey:
        if (object is KeyFrameBase && value is int) {
          object.interpolation = value;
        }
        break;
      case KeyFrameBase.interpolatorIdPropertyKey:
        if (object is KeyFrameBase && value is Id) {
          object.interpolatorId = value;
        }
        break;
      case KeyFrameDoubleBase.valuePropertyKey:
        if (object is KeyFrameDoubleBase && value is double) {
          object.value = value;
        }
        break;
      case LinearAnimationBase.fpsPropertyKey:
        if (object is LinearAnimationBase && value is int) {
          object.fps = value;
        }
        break;
      case LinearAnimationBase.durationPropertyKey:
        if (object is LinearAnimationBase && value is int) {
          object.duration = value;
        }
        break;
      case LinearAnimationBase.speedPropertyKey:
        if (object is LinearAnimationBase && value is double) {
          object.speed = value;
        }
        break;
      case LinearAnimationBase.loopValuePropertyKey:
        if (object is LinearAnimationBase && value is int) {
          object.loopValue = value;
        }
        break;
      case LinearAnimationBase.workStartPropertyKey:
        if (object is LinearAnimationBase && value is int) {
          object.workStart = value;
        }
        break;
      case LinearAnimationBase.workEndPropertyKey:
        if (object is LinearAnimationBase && value is int) {
          object.workEnd = value;
        }
        break;
      case LinearAnimationBase.enableWorkAreaPropertyKey:
        if (object is LinearAnimationBase && value is bool) {
          object.enableWorkArea = value;
        }
        break;
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
      case LinearGradientBase.opacityPropertyKey:
        if (object is LinearGradientBase && value is double) {
          object.opacity = value;
        }
        break;
      case StrokeBase.thicknessPropertyKey:
        if (object is StrokeBase && value is double) {
          object.thickness = value;
        }
        break;
      case StrokeBase.capPropertyKey:
        if (object is StrokeBase && value is int) {
          object.cap = value;
        }
        break;
      case StrokeBase.joinPropertyKey:
        if (object is StrokeBase && value is int) {
          object.join = value;
        }
        break;
      case StrokeBase.transformAffectsStrokePropertyKey:
        if (object is StrokeBase && value is bool) {
          object.transformAffectsStroke = value;
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
      case BackboardBase.activeArtboardIdPropertyKey:
        if (object is BackboardBase && value is Id) {
          object.activeArtboardId = value;
        }
        break;
      case BackboardBase.mainArtboardIdPropertyKey:
        if (object is BackboardBase && value is Id) {
          object.mainArtboardId = value;
        }
        break;
      case BackboardBase.colorValuePropertyKey:
        if (object is BackboardBase && value is int) {
          object.colorValue = value;
        }
        break;
    }
  }

  static bool animates(int propertyKey) {
    switch (propertyKey) {
      case StrokeBase.thicknessPropertyKey:
      case NodeBase.xPropertyKey:
      case NodeBase.yPropertyKey:
      case NodeBase.scaleXPropertyKey:
      case NodeBase.scaleYPropertyKey:
      case NodeBase.opacityPropertyKey:
        return true;
      default:
        return false;
    }
  }

  static KeyState getKeyState(Core object, int propertyKey) {
    switch (propertyKey) {
      case StrokeBase.thicknessPropertyKey:
        return (object as StrokeBase).thicknessKeyState;
        break;
      case NodeBase.xPropertyKey:
        return (object as NodeBase).xKeyState;
        break;
      case NodeBase.yPropertyKey:
        return (object as NodeBase).yKeyState;
        break;
      case NodeBase.scaleXPropertyKey:
        return (object as NodeBase).scaleXKeyState;
        break;
      case NodeBase.scaleYPropertyKey:
        return (object as NodeBase).scaleYKeyState;
        break;
      case NodeBase.opacityPropertyKey:
        return (object as NodeBase).opacityKeyState;
        break;
      default:
        return null;
    }
  }

  static void setKeyState(Core object, int propertyKey, KeyState value) {
    switch (propertyKey) {
      case StrokeBase.thicknessPropertyKey:
        if (object is StrokeBase) {
          object.thicknessKeyState = value;
        }
        break;
      case NodeBase.xPropertyKey:
        if (object is NodeBase) {
          object.xKeyState = value;
        }
        break;
      case NodeBase.yPropertyKey:
        if (object is NodeBase) {
          object.yKeyState = value;
        }
        break;
      case NodeBase.scaleXPropertyKey:
        if (object is NodeBase) {
          object.scaleXKeyState = value;
        }
        break;
      case NodeBase.scaleYPropertyKey:
        if (object is NodeBase) {
          object.scaleYKeyState = value;
        }
        break;
      case NodeBase.opacityPropertyKey:
        if (object is NodeBase) {
          object.opacityKeyState = value;
        }
        break;
    }
  }

  @override
  void resetAnimated(Core object, int propertyKey) {
    switch (propertyKey) {
      case StrokeBase.thicknessPropertyKey:
        if (object is StrokeBase) {
          object.thicknessAnimated = null;
          object.thicknessKeyState = KeyState.none;
        }
        break;
      case NodeBase.xPropertyKey:
        if (object is NodeBase) {
          object.xAnimated = null;
          object.xKeyState = KeyState.none;
        }
        break;
      case NodeBase.yPropertyKey:
        if (object is NodeBase) {
          object.yAnimated = null;
          object.yKeyState = KeyState.none;
        }
        break;
      case NodeBase.scaleXPropertyKey:
        if (object is NodeBase) {
          object.scaleXAnimated = null;
          object.scaleXKeyState = KeyState.none;
        }
        break;
      case NodeBase.scaleYPropertyKey:
        if (object is NodeBase) {
          object.scaleYAnimated = null;
          object.scaleYKeyState = KeyState.none;
        }
        break;
      case NodeBase.opacityPropertyKey:
        if (object is NodeBase) {
          object.opacityAnimated = null;
          object.opacityKeyState = KeyState.none;
        }
        break;
    }
  }

  @override
  Object getObjectProperty(Core object, int propertyKey) {
    switch (propertyKey) {
      case KeyedObjectBase.objectIdPropertyKey:
        if (object is KeyedObjectBase) {
          return object.objectId;
        }
        break;
      case KeyedObjectBase.animationIdPropertyKey:
        if (object is KeyedObjectBase) {
          return object.animationId;
        }
        break;
      case KeyedPropertyBase.keyedObjectIdPropertyKey:
        if (object is KeyedPropertyBase) {
          return object.keyedObjectId;
        }
        break;
      case KeyedPropertyBase.propertyKeyPropertyKey:
        if (object is KeyedPropertyBase) {
          return object.propertyKey;
        }
        break;
      case AnimationBase.artboardIdPropertyKey:
        if (object is AnimationBase) {
          return object.artboardId;
        }
        break;
      case AnimationBase.namePropertyKey:
        if (object is AnimationBase) {
          return object.name;
        }
        break;
      case AnimationBase.orderPropertyKey:
        if (object is AnimationBase) {
          return object.order;
        }
        break;
      case CubicInterpolatorBase.x1PropertyKey:
        if (object is CubicInterpolatorBase) {
          return object.x1;
        }
        break;
      case CubicInterpolatorBase.y1PropertyKey:
        if (object is CubicInterpolatorBase) {
          return object.y1;
        }
        break;
      case CubicInterpolatorBase.x2PropertyKey:
        if (object is CubicInterpolatorBase) {
          return object.x2;
        }
        break;
      case CubicInterpolatorBase.y2PropertyKey:
        if (object is CubicInterpolatorBase) {
          return object.y2;
        }
        break;
      case KeyFrameBase.keyedPropertyIdPropertyKey:
        if (object is KeyFrameBase) {
          return object.keyedPropertyId;
        }
        break;
      case KeyFrameBase.framePropertyKey:
        if (object is KeyFrameBase) {
          return object.frame;
        }
        break;
      case KeyFrameBase.interpolationPropertyKey:
        if (object is KeyFrameBase) {
          return object.interpolation;
        }
        break;
      case KeyFrameBase.interpolatorIdPropertyKey:
        if (object is KeyFrameBase) {
          return object.interpolatorId;
        }
        break;
      case KeyFrameDoubleBase.valuePropertyKey:
        if (object is KeyFrameDoubleBase) {
          return object.value;
        }
        break;
      case LinearAnimationBase.fpsPropertyKey:
        if (object is LinearAnimationBase) {
          return object.fps;
        }
        break;
      case LinearAnimationBase.durationPropertyKey:
        if (object is LinearAnimationBase) {
          return object.duration;
        }
        break;
      case LinearAnimationBase.speedPropertyKey:
        if (object is LinearAnimationBase) {
          return object.speed;
        }
        break;
      case LinearAnimationBase.loopValuePropertyKey:
        if (object is LinearAnimationBase) {
          return object.loopValue;
        }
        break;
      case LinearAnimationBase.workStartPropertyKey:
        if (object is LinearAnimationBase) {
          return object.workStart;
        }
        break;
      case LinearAnimationBase.workEndPropertyKey:
        if (object is LinearAnimationBase) {
          return object.workEnd;
        }
        break;
      case LinearAnimationBase.enableWorkAreaPropertyKey:
        if (object is LinearAnimationBase) {
          return object.enableWorkArea;
        }
        break;
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
      case LinearGradientBase.opacityPropertyKey:
        if (object is LinearGradientBase) {
          return object.opacity;
        }
        break;
      case StrokeBase.thicknessPropertyKey:
        if (object is StrokeBase) {
          return object.thickness;
        }
        break;
      case StrokeBase.capPropertyKey:
        if (object is StrokeBase) {
          return object.cap;
        }
        break;
      case StrokeBase.joinPropertyKey:
        if (object is StrokeBase) {
          return object.join;
        }
        break;
      case StrokeBase.transformAffectsStrokePropertyKey:
        if (object is StrokeBase) {
          return object.transformAffectsStroke;
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
      case BackboardBase.activeArtboardIdPropertyKey:
        if (object is BackboardBase) {
          return object.activeArtboardId;
        }
        break;
      case BackboardBase.mainArtboardIdPropertyKey:
        if (object is BackboardBase) {
          return object.mainArtboardId;
        }
        break;
      case BackboardBase.colorValuePropertyKey:
        if (object is BackboardBase) {
          return object.colorValue;
        }
        break;
    }
    return null;
  }

  CoreFieldType coreType(int propertyKey) {
    switch (propertyKey) {
      case KeyedObjectBase.objectIdPropertyKey:
      case KeyedObjectBase.animationIdPropertyKey:
      case KeyedPropertyBase.keyedObjectIdPropertyKey:
      case AnimationBase.artboardIdPropertyKey:
      case KeyFrameBase.keyedPropertyIdPropertyKey:
      case KeyFrameBase.interpolatorIdPropertyKey:
      case ComponentBase.parentIdPropertyKey:
      case BackboardBase.activeArtboardIdPropertyKey:
      case BackboardBase.mainArtboardIdPropertyKey:
        return idType;
      case KeyedPropertyBase.propertyKeyPropertyKey:
      case KeyFrameBase.framePropertyKey:
      case KeyFrameBase.interpolationPropertyKey:
      case LinearAnimationBase.fpsPropertyKey:
      case LinearAnimationBase.durationPropertyKey:
      case LinearAnimationBase.loopValuePropertyKey:
      case LinearAnimationBase.workStartPropertyKey:
      case LinearAnimationBase.workEndPropertyKey:
      case StrokeBase.capPropertyKey:
      case StrokeBase.joinPropertyKey:
      case SolidColorBase.colorValuePropertyKey:
      case GradientStopBase.colorValuePropertyKey:
      case FillBase.fillRulePropertyKey:
      case DrawableBase.blendModePropertyKey:
      case BackboardBase.colorValuePropertyKey:
        return intType;
      case AnimationBase.namePropertyKey:
      case ComponentBase.namePropertyKey:
        return stringType;
      case AnimationBase.orderPropertyKey:
      case ComponentBase.childOrderPropertyKey:
      case DrawableBase.drawOrderPropertyKey:
        return fractionalIndexType;
      case CubicInterpolatorBase.x1PropertyKey:
      case CubicInterpolatorBase.y1PropertyKey:
      case CubicInterpolatorBase.x2PropertyKey:
      case CubicInterpolatorBase.y2PropertyKey:
      case KeyFrameDoubleBase.valuePropertyKey:
      case LinearAnimationBase.speedPropertyKey:
      case LinearGradientBase.startXPropertyKey:
      case LinearGradientBase.startYPropertyKey:
      case LinearGradientBase.endXPropertyKey:
      case LinearGradientBase.endYPropertyKey:
      case LinearGradientBase.opacityPropertyKey:
      case StrokeBase.thicknessPropertyKey:
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
        return doubleType;
      case LinearAnimationBase.enableWorkAreaPropertyKey:
      case ShapePaintBase.isVisiblePropertyKey:
      case StrokeBase.transformAffectsStrokePropertyKey:
      case PointsPathBase.isClosedPropertyKey:
        return boolType;
      case ComponentBase.dependentIdsPropertyKey:
        return listIdType;
      default:
        return null;
    }
  }

  static Id getId(Core object, int propertyKey) {
    switch (propertyKey) {
      case KeyedObjectBase.objectIdPropertyKey:
        return (object as KeyedObjectBase).objectId;
      case KeyedObjectBase.animationIdPropertyKey:
        return (object as KeyedObjectBase).animationId;
      case KeyedPropertyBase.keyedObjectIdPropertyKey:
        return (object as KeyedPropertyBase).keyedObjectId;
      case AnimationBase.artboardIdPropertyKey:
        return (object as AnimationBase).artboardId;
      case KeyFrameBase.keyedPropertyIdPropertyKey:
        return (object as KeyFrameBase).keyedPropertyId;
      case KeyFrameBase.interpolatorIdPropertyKey:
        return (object as KeyFrameBase).interpolatorId;
      case ComponentBase.parentIdPropertyKey:
        return (object as ComponentBase).parentId;
      case BackboardBase.activeArtboardIdPropertyKey:
        return (object as BackboardBase).activeArtboardId;
      case BackboardBase.mainArtboardIdPropertyKey:
        return (object as BackboardBase).mainArtboardId;
    }
    return null;
  }

  static int getInt(Core object, int propertyKey) {
    switch (propertyKey) {
      case KeyedPropertyBase.propertyKeyPropertyKey:
        return (object as KeyedPropertyBase).propertyKey;
      case KeyFrameBase.framePropertyKey:
        return (object as KeyFrameBase).frame;
      case KeyFrameBase.interpolationPropertyKey:
        return (object as KeyFrameBase).interpolation;
      case LinearAnimationBase.fpsPropertyKey:
        return (object as LinearAnimationBase).fps;
      case LinearAnimationBase.durationPropertyKey:
        return (object as LinearAnimationBase).duration;
      case LinearAnimationBase.loopValuePropertyKey:
        return (object as LinearAnimationBase).loopValue;
      case LinearAnimationBase.workStartPropertyKey:
        return (object as LinearAnimationBase).workStart;
      case LinearAnimationBase.workEndPropertyKey:
        return (object as LinearAnimationBase).workEnd;
      case StrokeBase.capPropertyKey:
        return (object as StrokeBase).cap;
      case StrokeBase.joinPropertyKey:
        return (object as StrokeBase).join;
      case SolidColorBase.colorValuePropertyKey:
        return (object as SolidColorBase).colorValue;
      case GradientStopBase.colorValuePropertyKey:
        return (object as GradientStopBase).colorValue;
      case FillBase.fillRulePropertyKey:
        return (object as FillBase).fillRule;
      case DrawableBase.blendModePropertyKey:
        return (object as DrawableBase).blendMode;
      case BackboardBase.colorValuePropertyKey:
        return (object as BackboardBase).colorValue;
    }
    return 0;
  }

  static String getString(Core object, int propertyKey) {
    switch (propertyKey) {
      case AnimationBase.namePropertyKey:
        return (object as AnimationBase).name;
      case ComponentBase.namePropertyKey:
        return (object as ComponentBase).name;
    }
    return null;
  }

  static FractionalIndex getFractionalIndex(Core object, int propertyKey) {
    switch (propertyKey) {
      case AnimationBase.orderPropertyKey:
        return (object as AnimationBase).order;
      case ComponentBase.childOrderPropertyKey:
        return (object as ComponentBase).childOrder;
      case DrawableBase.drawOrderPropertyKey:
        return (object as DrawableBase).drawOrder;
    }
    return null;
  }

  static double getDouble(Core object, int propertyKey) {
    switch (propertyKey) {
      case CubicInterpolatorBase.x1PropertyKey:
        return (object as CubicInterpolatorBase).x1;
      case CubicInterpolatorBase.y1PropertyKey:
        return (object as CubicInterpolatorBase).y1;
      case CubicInterpolatorBase.x2PropertyKey:
        return (object as CubicInterpolatorBase).x2;
      case CubicInterpolatorBase.y2PropertyKey:
        return (object as CubicInterpolatorBase).y2;
      case KeyFrameDoubleBase.valuePropertyKey:
        return (object as KeyFrameDoubleBase).value;
      case LinearAnimationBase.speedPropertyKey:
        return (object as LinearAnimationBase).speed;
      case LinearGradientBase.startXPropertyKey:
        return (object as LinearGradientBase).startX;
      case LinearGradientBase.startYPropertyKey:
        return (object as LinearGradientBase).startY;
      case LinearGradientBase.endXPropertyKey:
        return (object as LinearGradientBase).endX;
      case LinearGradientBase.endYPropertyKey:
        return (object as LinearGradientBase).endY;
      case LinearGradientBase.opacityPropertyKey:
        return (object as LinearGradientBase).opacity;
      case StrokeBase.thicknessPropertyKey:
        return (object as StrokeBase).thickness;
      case GradientStopBase.positionPropertyKey:
        return (object as GradientStopBase).position;
      case NodeBase.xPropertyKey:
        return (object as NodeBase).x;
      case NodeBase.yPropertyKey:
        return (object as NodeBase).y;
      case NodeBase.rotationPropertyKey:
        return (object as NodeBase).rotation;
      case NodeBase.scaleXPropertyKey:
        return (object as NodeBase).scaleX;
      case NodeBase.scaleYPropertyKey:
        return (object as NodeBase).scaleY;
      case NodeBase.opacityPropertyKey:
        return (object as NodeBase).opacity;
      case PathVertexBase.xPropertyKey:
        return (object as PathVertexBase).x;
      case PathVertexBase.yPropertyKey:
        return (object as PathVertexBase).y;
      case StraightVertexBase.radiusPropertyKey:
        return (object as StraightVertexBase).radius;
      case ParametricPathBase.widthPropertyKey:
        return (object as ParametricPathBase).width;
      case ParametricPathBase.heightPropertyKey:
        return (object as ParametricPathBase).height;
      case RectangleBase.cornerRadiusPropertyKey:
        return (object as RectangleBase).cornerRadius;
      case CubicVertexBase.inXPropertyKey:
        return (object as CubicVertexBase).inX;
      case CubicVertexBase.inYPropertyKey:
        return (object as CubicVertexBase).inY;
      case CubicVertexBase.outXPropertyKey:
        return (object as CubicVertexBase).outX;
      case CubicVertexBase.outYPropertyKey:
        return (object as CubicVertexBase).outY;
      case ArtboardBase.widthPropertyKey:
        return (object as ArtboardBase).width;
      case ArtboardBase.heightPropertyKey:
        return (object as ArtboardBase).height;
      case ArtboardBase.xPropertyKey:
        return (object as ArtboardBase).x;
      case ArtboardBase.yPropertyKey:
        return (object as ArtboardBase).y;
      case ArtboardBase.originXPropertyKey:
        return (object as ArtboardBase).originX;
      case ArtboardBase.originYPropertyKey:
        return (object as ArtboardBase).originY;
    }
    return 0.0;
  }

  static bool getBool(Core object, int propertyKey) {
    switch (propertyKey) {
      case LinearAnimationBase.enableWorkAreaPropertyKey:
        return (object as LinearAnimationBase).enableWorkArea;
      case ShapePaintBase.isVisiblePropertyKey:
        return (object as ShapePaintBase).isVisible;
      case StrokeBase.transformAffectsStrokePropertyKey:
        return (object as StrokeBase).transformAffectsStroke;
      case PointsPathBase.isClosedPropertyKey:
        return (object as PointsPathBase).isClosed;
    }
    return false;
  }

  static List<Id> getListId(Core object, int propertyKey) {
    switch (propertyKey) {
      case ComponentBase.dependentIdsPropertyKey:
        return (object as ComponentBase).dependentIds;
    }
    return null;
  }

  static void setId(Core object, int propertyKey, Id value) {
    switch (propertyKey) {
      case KeyedObjectBase.objectIdPropertyKey:
        (object as KeyedObjectBase).objectId = value;
        break;
      case KeyedObjectBase.animationIdPropertyKey:
        (object as KeyedObjectBase).animationId = value;
        break;
      case KeyedPropertyBase.keyedObjectIdPropertyKey:
        (object as KeyedPropertyBase).keyedObjectId = value;
        break;
      case AnimationBase.artboardIdPropertyKey:
        (object as AnimationBase).artboardId = value;
        break;
      case KeyFrameBase.keyedPropertyIdPropertyKey:
        (object as KeyFrameBase).keyedPropertyId = value;
        break;
      case KeyFrameBase.interpolatorIdPropertyKey:
        (object as KeyFrameBase).interpolatorId = value;
        break;
      case ComponentBase.parentIdPropertyKey:
        (object as ComponentBase).parentId = value;
        break;
      case BackboardBase.activeArtboardIdPropertyKey:
        (object as BackboardBase).activeArtboardId = value;
        break;
      case BackboardBase.mainArtboardIdPropertyKey:
        (object as BackboardBase).mainArtboardId = value;
        break;
    }
  }

  static void setInt(Core object, int propertyKey, int value) {
    switch (propertyKey) {
      case KeyedPropertyBase.propertyKeyPropertyKey:
        (object as KeyedPropertyBase).propertyKey = value;
        break;
      case KeyFrameBase.framePropertyKey:
        (object as KeyFrameBase).frame = value;
        break;
      case KeyFrameBase.interpolationPropertyKey:
        (object as KeyFrameBase).interpolation = value;
        break;
      case LinearAnimationBase.fpsPropertyKey:
        (object as LinearAnimationBase).fps = value;
        break;
      case LinearAnimationBase.durationPropertyKey:
        (object as LinearAnimationBase).duration = value;
        break;
      case LinearAnimationBase.loopValuePropertyKey:
        (object as LinearAnimationBase).loopValue = value;
        break;
      case LinearAnimationBase.workStartPropertyKey:
        (object as LinearAnimationBase).workStart = value;
        break;
      case LinearAnimationBase.workEndPropertyKey:
        (object as LinearAnimationBase).workEnd = value;
        break;
      case StrokeBase.capPropertyKey:
        (object as StrokeBase).cap = value;
        break;
      case StrokeBase.joinPropertyKey:
        (object as StrokeBase).join = value;
        break;
      case SolidColorBase.colorValuePropertyKey:
        (object as SolidColorBase).colorValue = value;
        break;
      case GradientStopBase.colorValuePropertyKey:
        (object as GradientStopBase).colorValue = value;
        break;
      case FillBase.fillRulePropertyKey:
        (object as FillBase).fillRule = value;
        break;
      case DrawableBase.blendModePropertyKey:
        (object as DrawableBase).blendMode = value;
        break;
      case BackboardBase.colorValuePropertyKey:
        (object as BackboardBase).colorValue = value;
        break;
    }
  }

  static void setString(Core object, int propertyKey, String value) {
    switch (propertyKey) {
      case AnimationBase.namePropertyKey:
        (object as AnimationBase).name = value;
        break;
      case ComponentBase.namePropertyKey:
        (object as ComponentBase).name = value;
        break;
    }
  }

  static void setFractionalIndex(
      Core object, int propertyKey, FractionalIndex value) {
    switch (propertyKey) {
      case AnimationBase.orderPropertyKey:
        (object as AnimationBase).order = value;
        break;
      case ComponentBase.childOrderPropertyKey:
        (object as ComponentBase).childOrder = value;
        break;
      case DrawableBase.drawOrderPropertyKey:
        (object as DrawableBase).drawOrder = value;
        break;
    }
  }

  static void setDouble(Core object, int propertyKey, double value) {
    switch (propertyKey) {
      case CubicInterpolatorBase.x1PropertyKey:
        (object as CubicInterpolatorBase).x1 = value;
        break;
      case CubicInterpolatorBase.y1PropertyKey:
        (object as CubicInterpolatorBase).y1 = value;
        break;
      case CubicInterpolatorBase.x2PropertyKey:
        (object as CubicInterpolatorBase).x2 = value;
        break;
      case CubicInterpolatorBase.y2PropertyKey:
        (object as CubicInterpolatorBase).y2 = value;
        break;
      case KeyFrameDoubleBase.valuePropertyKey:
        (object as KeyFrameDoubleBase).value = value;
        break;
      case LinearAnimationBase.speedPropertyKey:
        (object as LinearAnimationBase).speed = value;
        break;
      case LinearGradientBase.startXPropertyKey:
        (object as LinearGradientBase).startX = value;
        break;
      case LinearGradientBase.startYPropertyKey:
        (object as LinearGradientBase).startY = value;
        break;
      case LinearGradientBase.endXPropertyKey:
        (object as LinearGradientBase).endX = value;
        break;
      case LinearGradientBase.endYPropertyKey:
        (object as LinearGradientBase).endY = value;
        break;
      case LinearGradientBase.opacityPropertyKey:
        (object as LinearGradientBase).opacity = value;
        break;
      case StrokeBase.thicknessPropertyKey:
        (object as StrokeBase).thickness = value;
        break;
      case GradientStopBase.positionPropertyKey:
        (object as GradientStopBase).position = value;
        break;
      case NodeBase.xPropertyKey:
        (object as NodeBase).x = value;
        break;
      case NodeBase.yPropertyKey:
        (object as NodeBase).y = value;
        break;
      case NodeBase.rotationPropertyKey:
        (object as NodeBase).rotation = value;
        break;
      case NodeBase.scaleXPropertyKey:
        (object as NodeBase).scaleX = value;
        break;
      case NodeBase.scaleYPropertyKey:
        (object as NodeBase).scaleY = value;
        break;
      case NodeBase.opacityPropertyKey:
        (object as NodeBase).opacity = value;
        break;
      case PathVertexBase.xPropertyKey:
        (object as PathVertexBase).x = value;
        break;
      case PathVertexBase.yPropertyKey:
        (object as PathVertexBase).y = value;
        break;
      case StraightVertexBase.radiusPropertyKey:
        (object as StraightVertexBase).radius = value;
        break;
      case ParametricPathBase.widthPropertyKey:
        (object as ParametricPathBase).width = value;
        break;
      case ParametricPathBase.heightPropertyKey:
        (object as ParametricPathBase).height = value;
        break;
      case RectangleBase.cornerRadiusPropertyKey:
        (object as RectangleBase).cornerRadius = value;
        break;
      case CubicVertexBase.inXPropertyKey:
        (object as CubicVertexBase).inX = value;
        break;
      case CubicVertexBase.inYPropertyKey:
        (object as CubicVertexBase).inY = value;
        break;
      case CubicVertexBase.outXPropertyKey:
        (object as CubicVertexBase).outX = value;
        break;
      case CubicVertexBase.outYPropertyKey:
        (object as CubicVertexBase).outY = value;
        break;
      case ArtboardBase.widthPropertyKey:
        (object as ArtboardBase).width = value;
        break;
      case ArtboardBase.heightPropertyKey:
        (object as ArtboardBase).height = value;
        break;
      case ArtboardBase.xPropertyKey:
        (object as ArtboardBase).x = value;
        break;
      case ArtboardBase.yPropertyKey:
        (object as ArtboardBase).y = value;
        break;
      case ArtboardBase.originXPropertyKey:
        (object as ArtboardBase).originX = value;
        break;
      case ArtboardBase.originYPropertyKey:
        (object as ArtboardBase).originY = value;
        break;
    }
  }

  static void animateDouble(Core object, int propertyKey, double value) {
    switch (propertyKey) {
      case StrokeBase.thicknessPropertyKey:
        (object as StrokeBase).thicknessAnimated = value;
        break;
      case NodeBase.xPropertyKey:
        (object as NodeBase).xAnimated = value;
        break;
      case NodeBase.yPropertyKey:
        (object as NodeBase).yAnimated = value;
        break;
      case NodeBase.scaleXPropertyKey:
        (object as NodeBase).scaleXAnimated = value;
        break;
      case NodeBase.scaleYPropertyKey:
        (object as NodeBase).scaleYAnimated = value;
        break;
      case NodeBase.opacityPropertyKey:
        (object as NodeBase).opacityAnimated = value;
        break;
    }
  }

  static void setBool(Core object, int propertyKey, bool value) {
    switch (propertyKey) {
      case LinearAnimationBase.enableWorkAreaPropertyKey:
        (object as LinearAnimationBase).enableWorkArea = value;
        break;
      case ShapePaintBase.isVisiblePropertyKey:
        (object as ShapePaintBase).isVisible = value;
        break;
      case StrokeBase.transformAffectsStrokePropertyKey:
        (object as StrokeBase).transformAffectsStroke = value;
        break;
      case PointsPathBase.isClosedPropertyKey:
        (object as PointsPathBase).isClosed = value;
        break;
    }
  }

  static void setListId(Core object, int propertyKey, List<Id> value) {
    switch (propertyKey) {
      case ComponentBase.dependentIdsPropertyKey:
        (object as ComponentBase).dependentIds = value;
        break;
    }
  }
}
