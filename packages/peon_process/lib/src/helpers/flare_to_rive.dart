import 'dart:convert';

import 'package:local_data/local_data.dart';
import 'package:peon_process/converters.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/bones/root_bone.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/ellipse.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/stroke.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_core/shapes/rectangle.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/triangle.dart';

typedef bool DescentCallback(Object obj);

class FlareToRive {
  FlareToRive(String filename)
      : riveFile = RiveFile(
          filename,
          localDataPlatform: LocalDataPlatform.make(),
        )..addObject(Backboard());

  final RiveFile riveFile;
  final _fileComponents = <String, Component>{};
  AnimationConverter _animationConverter;

  void toFile(String revision) {
    final revisionObject = jsonDecode(revision) as Map<String, Object>;
    final artboards = revisionObject['artboards'] as Map<String, Object>;
    final animations = _getAnimations(artboards);

    _getRiveComponents(artboards);

    _animationConverter = AnimationConverter(_fileComponents, riveFile);
    animations.forEach(_generateAnimations);
  }

  List<_ArtboardAnimations> _getAnimations(Map<String, Object> artboards) {
    final children = artboards['children'] as List;
    if (children == null || children.isEmpty) {
      throw const FormatException('"Artboards" object has no children');
    }

    final animationList = <_ArtboardAnimations>[];

    // Iterate over all the artboard objects in this 'artboards' container,
    for (final child in children) {
      final artboardID = child['id']?.toString();
      if (artboardID == null) {
        throw StateError('Artboard ID cannot be null ${child['id']}');
      }
      final animations = child['animations'] as Object;
      if (animations is List) {
        animationList.add(_ArtboardAnimations(artboardID, animations));
      }
    }

    return animationList;
  }

  /// Fills [_fileComponents] by deserializing JSON.
  void _getRiveComponents(Map<String, Object> artboards) {
    // Queue to perform BFS on the hierarchy tree.
    final queue = <Map<String, Object>>[artboards];

    while (queue.isNotEmpty) {
      var head = queue.removeAt(0);
      final headId = head['id'].toString();
      final parentId = head['parent'];

      ContainerComponent parent;
      if (parentId != null) {
        parent = _fileComponents[parentId.toString()] as ContainerComponent;
      }

      final component = _fromJSON(head, parent);
      if (component != null) {
        // Update the component mapping.
        _fileComponents[headId] = component;
      }

      // Proceed by looping on all the children, if any.
      final componentChildren = head.remove('children');
      if (componentChildren == null) continue;

      // For each child, add a 'parent' property to the JSON object to be able
      // to reconcile the two afterwards.
      for (final component in componentChildren) {
        if (component is Map<String, Object>) {
          // Don't add parent ids to artboards.
          if (component['type'] != 'artboard') {
            component['parent'] = headId;
          }

          queue.add(component);
        } else {
          throw UnsupportedError('Not a map?? $component');
        }
      }
    }
  }

  Component _fromJSON(
      Map<String, Object> object, ContainerComponent maybeParent) {
    final objectType = object['type'] as String;

    ComponentConverter converter;

    switch (objectType) {
      case 'artboard':
        converter = ArtboardConverter(Artboard(), riveFile, null)
          ..deserialize(object);
        break;
      case 'node':
        converter = NodeConverter(Node(), riveFile, maybeParent)
          ..deserialize(object);
        break;
      case 'shape':
        converter = ShapeConverter(Shape(), riveFile, maybeParent)
          ..deserialize(object);

        // TODO: trim extra strokes
        _shapePropToChildren(object);
        break;
      case 'ellipse':
        converter = ParametricPathConverter(Ellipse(), riveFile, maybeParent)
          ..deserialize(object);
        break;
      case 'triangle':
        converter = ParametricPathConverter(Triangle(), riveFile, maybeParent)
          ..deserialize(object);
        break;
      case 'rectangle':
        converter = RectangleConverter(Rectangle(), riveFile, maybeParent)
          ..deserialize(object);
        break;
      case 'colorFill':
        converter = FillColorConverter(Fill(), riveFile, maybeParent)
          ..deserialize(object);
        break;
      case 'gradientFill':
      case 'radialGradientFill':
        converter = FillGradientConverter(Fill(), riveFile, maybeParent)
          ..deserialize(object);
        break;
      case 'colorStroke':
        converter = StrokeColorConverter(Stroke(), riveFile, maybeParent)
          ..deserialize(object);
        break;
      case 'gradientStroke':
      case 'radialGradientStroke':
        converter = StrokeGradientConverter(Stroke(), riveFile, maybeParent)
          ..deserialize(object);
        break;
        break;
      case 'path':
        converter = PathConverter(PointsPath(), riveFile, maybeParent)
          ..deserialize(object);
        break;
      case 'point':
        final pointType = object['pointType'] as String;
        converter = PathPointConverter(pointType, riveFile, maybeParent)
          ..deserialize(object);
        break;
      case 'rootBone':
        converter = BoneConverter(RootBone(), riveFile, maybeParent)
          ..deserialize(object);
        break;
      case 'bone':
        converter = BoneConverter(Bone(), riveFile, maybeParent)
          ..deserialize(object);
        break;
      default:
        print('===== UNKNOWN TYPE!? $objectType');
        // const encoder = JsonEncoder.withIndent(' ');
        // String prettyprint = encoder.convert(object);
        // print(prettyprint);
        break;
    }

    return converter?.component;
  }

  // Propagate 'transformAffectsStroke' property from parent Shape
  // to its child Stroke.
  // N.B. in Flare every shape can only have a single stroke.
  static void _shapePropToChildren(Map<String, Object> jsonShape) {
    final children = jsonShape['children'];
    if (!(children is List)) {
      return;
    }
    final transformAffectsStroke = jsonShape['transformAffectsStroke'];

    for (final child in children) {
      final childType = (child['type'] as String).toLowerCase();
      if (childType.contains('stroke')) {
        child['transformAffectsStroke'] = transformAffectsStroke;
      }
    }
  }

  void _generateAnimations(_ArtboardAnimations artboardAnimations) {
    final animationList = artboardAnimations.jsonAnimations;
    final parentId = artboardAnimations.artboardID;

    for (final jsonAnimation in animationList) {
      _animationConverter.deserialize(
          jsonAnimation as Map<String, Object>, parentId);
    }
  }
}

/// Wrapper class for storing the list of animations of a Flare artboard.
/// [artboardID] is the Flare id
/// [jsonAnimations] is the list of JSON objects that'll be deserialized.
class _ArtboardAnimations {
  const _ArtboardAnimations(this.artboardID, this.jsonAnimations);
  final String artboardID;
  final List jsonAnimations;
}
