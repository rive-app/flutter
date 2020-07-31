import 'package:peon_process/converters.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/animation/loop.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/rive_file.dart';

class AnimationConverter {
  const AnimationConverter(this._fileComponents, this.riveFile);

  final Map<String, Component> _fileComponents;
  final RiveFile riveFile;

  deserialize(Map<String, Object> animationRevision, String parentId) {
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
    final order = animationRevision['order'];

    assert(name is String);
    assert(duration is num);
    assert(fps is num);
    assert(displayStart is num);
    assert(displayEnd is num);
    assert(isLooping is bool);
    assert(isWorkAreaActive is bool);

    riveFile.batchAdd(() {
      final riveAnimation = LinearAnimation();
      riveFile.addObject(riveAnimation);

      riveAnimation
        ..name = name
        ..fps = (fps as num).toInt()
        ..duration = (duration as num).toInt() * riveAnimation.fps
        ..workStart = (displayStart as num).toInt()
        ..workEnd = (displayEnd as num).toInt()
        ..loop = _getLoopType(isLooping, isWorkAreaActive)
        ..enableWorkArea = isWorkAreaActive
        ..artboardId = parent.id;
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
      Component component;
      if (id == "ORDER") {
        component = animation.artboard;
      } else {
        component = _fileComponents[id];
      }

      final keyFrameGroups = animationNodes[id] as Map<String, Object>;
      for (final keyGroupName in keyFrameGroups.keys) {
        final allKeys = keyFrameGroups[keyGroupName] as List;
        for (final jsonKey in allKeys) {
          _addKeyFrame(animation, component, keyGroupName, jsonKey);
        }
      }
    }
  }

  void _addKeyFrame(LinearAnimation animation, Component component,
      String keyGroupName, Map<String, Object> jsonKey) {
    final value = jsonKey['v'];
    final time = jsonKey['t'] as num;
    final frame = (time * animation.fps).floor();
    final interpolatorType = jsonKey['i'];
    final interpolatorCurve = jsonKey['curve'];

    switch (keyGroupName) {
      case "framePosX":
        KeyFramePosX(value, interpolatorType, interpolatorCurve)
            .convertKey(component, animation, frame);
        return;
      case "framePosY":
        KeyFramePosY(value, interpolatorType, interpolatorCurve)
            .convertKey(component, animation, frame);
        return;
      case "frameScaleX":
        KeyFrameScaleX(value, interpolatorType, interpolatorCurve)
            .convertKey(component, animation, frame);
        return;
      case "frameScaleY":
        KeyFrameScaleY(value, interpolatorType, interpolatorCurve)
            .convertKey(component, animation, frame);
        return;
      case "frameRotation":
        KeyFrameRotation(value, interpolatorType, interpolatorCurve)
            .convertKey(component, animation, frame);
        return;
      case "frameOpacity":
        KeyFrameOpacity(value, interpolatorType, interpolatorCurve)
            .convertKey(component, animation, frame);
        return;
      case "frameDrawOrder":
        KeyFrameDrawOrderConverter(
                _fileComponents, value, interpolatorType, interpolatorCurve)
            .convertKey(component, animation, frame);
        return;
      case "frameLength":
        // Needs bones.
        break;
      case "frameImageVertices":
        // Needs images.
        break;
      case "frameStrength":
        // Needs bones.
        break;
      case "frameTrigger":
        // Needs triggers.
        break;
      case "frameIntValue":
        // Needs custom properties.
        break;
      case "frameFloatValue":
        // Needs custom properties.
        break;
      case "frameStringValue":
        // Needs custom properties.
        break;
      case "frameBooleanValue":
        // Needs custom properties.
        break;
      case "frameIsCollisionEnabled":
        // Needs collision detectors..
        break;
      case "frameSequence":
        // Needs image sequences.
        break;
      case "frameActiveChild":
        // Needs Solo nodes.
        break;
      case "framePathVertices":
        if (value is Map) {
          for (final vertexId in value.keys) {
            final vertexComponent = _fileComponents[vertexId];
            final vertexValues = value[vertexId] as Map;

            final converter = KeyFrameVertexConverter.fromVertex(
              vertexComponent,
              vertexValues,
              interpolatorType,
              interpolatorCurve,
            );

            if (converter == null) {
              throw StateError(
                  'Cannot find a converter for ${vertexComponent.runtimeType}');
            }

            converter.convertKey(vertexComponent, animation, frame);
          }
        }
        break;
      case "frameFillColor":
        if (value is List) {
          KeyFrameSolidColorConverter(
                  value, interpolatorType, interpolatorCurve)
              .convertKey(component, animation, frame);
          break;
        }
        throw UnsupportedError('Not a valid fill color list $value');
      case "frameFillRadial":
        if (value is List) {
          KeyFrameRadialGradientConverter(
                  value, interpolatorType, interpolatorCurve)
              .convertKey(component, animation, frame);
        }
        break;
      case "frameFillGradient":
        if (value is List) {
          KeyFrameGradientConverter(value, interpolatorType, interpolatorCurve)
              .convertKey(component, animation, frame);
        }
        break;
      case "frameStrokeColor":
        if (value is List) {
          KeyFrameSolidStrokeConverter(
                  value, interpolatorType, interpolatorCurve)
              .convertKey(component, animation, frame);
        }
        break;
      case "frameStrokeGradient":
        if (value is List) {
          KeyFrameStrokeGradientConverter(
                  value, interpolatorType, interpolatorCurve)
              .convertKey(component, animation, frame);
        }
        break;
      case "frameStrokeRadial":
        if (value is List) {
          KeyFrameStrokeRadialGradientConverter(
                  value, interpolatorType, interpolatorCurve)
              .convertKey(component, animation, frame);
        }
        break;
      case "frameStrokeWidth":
        if (value is num) {
          KeyFrameStrokeWidthConverter(
                  value, interpolatorType, interpolatorCurve)
              .convertKey(component, animation, frame);
        }
        break;
      case "frameStrokeOpacity":
        // TODO: KeyFrameDouble;
        break;
      case "frameFillOpacity":
        if (value is num) {
          KeyFrameFillOpacityConverter(
                  value, interpolatorType, interpolatorCurve)
              .convertKey(component, animation, frame);
        }
        break;
      case "frameWidth":
        // TODO: KeyFrameDouble;
        break;
      case "frameHeight":
        // TODO: KeyFrameDouble;
        break;
      case "frameCornerRadius":
        // TODO: KeyFrameDouble;
        break;
      case "frameInnerRadius":
        // Needs stars.
        break;
      case "frameStrokeStart":
        // Needs trim paths.
        break;
      case "frameStrokeEnd":
        // Needs trim paths.
        break;
      case "frameStrokeOffset":
        // Needs trim paths.
        break;
      case "frameColor":
        // Needs shadows.
        break;
      case "frameOffsetX":
        // Needs shadows.
        break;
      case "frameOffsetY":
        // Needs shadows.
        break;
      case "frameBlurX":
        // Needs blurs.
        break;
      case "frameBlurY":
        // Needs blurs.
        break;
    }
  }
}
