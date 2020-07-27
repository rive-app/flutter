import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/animation/keyframe_draw_order.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/animation/loop.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/cubic_asymmetric_vertex.dart';
import 'package:rive_core/shapes/cubic_mirrored_vertex.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart';
import 'package:rive_core/shapes/path_vertex.dart';

class _KeyFrameInfo {
  const _KeyFrameInfo(this.keyFrameType, this.propertyKey);
  final Type keyFrameType;
  final int propertyKey;
}

class AnimationConverter {
  const AnimationConverter(this._fileComponents, this.riveFile);

  final Map<int, Component> _fileComponents;
  final RiveFile riveFile;

  deserialize(Map<String, Object> animationRevision, int parentId) {
    final parent = _fileComponents[parentId] as Artboard;
    if (parent == null) {
      throw ArgumentError('Cannot find parent id: $parentId');
    }

    final name = animationRevision['name'];
    final duration = animationRevision['duration'];
    final fps = animationRevision['fps'];
    final displayStart = animationRevision['displayStart'];
    final displayEnd = animationRevision['displayEnd'];
    final isLooping = animationRevision['loop'];
    final isWorkAreaActive = animationRevision['isWorkAreaActive'];
    // final order = animationRevision['order'];

    assert(name is String);
    assert(duration is num);
    assert(fps is num);
    assert(displayStart is num);
    assert(displayEnd is num);
    assert(isLooping is bool);
    assert(isWorkAreaActive is bool);

    final riveAnimation = LinearAnimation()
      ..name = name
      ..duration = (duration as num).toInt()
      ..fps = (fps as num).toInt()
      ..workStart = (displayStart as num).toInt()
      ..workEnd = (displayEnd as num).toInt()
      ..loop = _getLoopType(isLooping, isWorkAreaActive)
      ..enableWorkArea = isWorkAreaActive
      ..artboardId = parent.id;

    riveFile.batchAdd(() {
      riveFile.addObject(riveAnimation);

      final animationNodes = animationRevision['nodes'];
      _extractKeyFrames(riveAnimation, animationNodes);
    });
  }

  Loop _getLoopType(bool isLooping, bool isWorkAreaActive) {
    if (!isLooping) {
      return Loop.oneShot;
    }
    if (isWorkAreaActive) {
      return Loop.pingPong;
    }
    return Loop.loop;
  }

  /// Parses the "nodes" Object in the animation revision, and extracts the
  /// keyframes associated with each node.
  void _extractKeyFrames(
      LinearAnimation animation, Map<String, Object> animationNodes) {
    final nodeIds = animationNodes.keys;

    // Flare revisions store [id]s are as String keys, so they need to be parsed
    // and converted to our desired int format, to extract the component from
    // the map.
    for (final id in nodeIds) {
      final intId = int.parse(id);
      final component = _fileComponents[intId];

      var keyedObject = animation.getKeyed(component);
      if (keyedObject == null) {
        keyedObject = animation.makeKeyed(component);
      }

      final keyFrameGroups = animationNodes[id] as Map<String, Object>;
      for (final keyGroupName in keyFrameGroups.keys) {
        final allKeys = keyFrameGroups[keyGroupName] as List;
        for (final key in allKeys) {
          // final keyToAdd = _getKeyFrame(keyGroupName, key);
        }
      }
    }
  }

  _KeyFrameInfo _getKeyFrame(
      String keyName, Map<String, num> jsonKey, Component component) {
    Type keyFrameType;
    int propertyKey;
    switch (keyName) {
      case "framePosX":
        keyFrameType = KeyFrameDouble;
        if (component is ArtboardBase) {
          propertyKey = ArtboardBase.xPropertyKey;
        } else if (component is NodeBase) {
          propertyKey = NodeBase.xPropertyKey;
        } else if (component is PathVertexBase) {
          propertyKey = PathVertexBase.xPropertyKey;
        }
        break;
      case "framePosY":
        keyFrameType = KeyFrameDouble;
        if (component is ArtboardBase) {
          propertyKey = ArtboardBase.yPropertyKey;
        } else if (component is NodeBase) {
          propertyKey = NodeBase.yPropertyKey;
        } else if (component is PathVertexBase) {
          propertyKey = PathVertexBase.yPropertyKey;
        }
        break;
      case "frameScaleX":
        keyFrameType = KeyFrameDouble;
        if (component is NodeBase) {
          propertyKey = NodeBase.scaleXPropertyKey;
        }
        break;
      case "frameScaleY":
        keyFrameType = KeyFrameDouble;
        if (component is NodeBase) {
          propertyKey = NodeBase.scaleXPropertyKey;
        }
        break;
      case "frameRotation":
        keyFrameType = KeyFrameDouble;
        if (component is NodeBase) {
          propertyKey = NodeBase.rotationPropertyKey;
        } else if (component is CubicMirroredVertexBase) {
          propertyKey = CubicMirroredVertexBase.rotationPropertyKey;
        } else if (component is CubicAsymmetricVertexBase) {
          propertyKey = CubicAsymmetricVertexBase.rotationPropertyKey;
        }
        break;
      case "frameOpacity":
        keyFrameType = KeyFrameDouble;
        if (component is NodeBase) {
          propertyKey = NodeBase.opacityPropertyKey;
        } else if (component is LinearGradientBase) {
          propertyKey = LinearGradientBase.opacityPropertyKey;
        }
        break;
      case "frameDrawOrder":
        keyFrameType = KeyFrameDrawOrder;
        if (component is DrawableBase) {
          propertyKey = DrawableBase.drawOrderPropertyKey;
        }
        break;
      case "frameLength":
        // TODO:
        break;
      case "frameImageVertices":
        // TODO:
        break;
      case "frameStrength":
        // TODO:
        break;
      case "frameTrigger":
        // TODO:
        break;
      case "frameIntValue":
        // TODO:
        break;
      case "frameFloatValue":
        // TODO:
        break;
      case "frameStringValue":
        // TODO:
        break;
      case "frameBooleanValue":
        // TODO:
        break;
      case "frameIsCollisionEnabled":
        // TODO:
        break;
      case "frameSequence":
        // TODO:
        break;
      case "frameActiveChild":
        // TODO:
        break;
      case "framePathVertices":
        break;
      case "frameFillColor":
        break;
      case "frameFillGradient":
        break;
      case "frameFillRadial":
        break;
      case "frameStrokeColor":
        break;
      case "frameStrokeGradient":
        break;
      case "frameStrokeRadial":
        break;
      case "frameStrokeWidth":
        break;
      case "frameStrokeOpacity":
        break;
      case "frameFillOpacity":
        break;
      case "frameWidth":
        break;
      case "frameHeight":
        break;
      case "frameCornerRadius":
        break;
      case "frameInnerRadius":
        break;
      case "frameStrokeStart":
        break;
      case "frameStrokeEnd":
        break;
      case "frameStrokeOffset":
        break;
      case "frameColor":
        break;
      case "frameOffsetX":
        break;
      case "frameOffsetY":
        break;
      case "frameBlurX":
        break;
      case "frameBlurY":
        break;
    }
    return _KeyFrameInfo(keyFrameType, propertyKey);
  }
}
/**
 * To add a keyframe to a component: 
 * 1 - Key the object:
 * keyedObject = animation.makeKeyed(component);
 * 2 - Start keying a given property:
 * keyedObject.makedKeyed([Component].[name]propertyKey)
 * 3 - Create a keyframe:
 * keyframe = component.addKeyFrame<KeyFrame[Type]>(
 *    animation, 
 *    [Component].[name]propertyKey, 
 *    frame
 *  )
 * 4 - set the keyframe value
 * keyframe.value = value
 */
