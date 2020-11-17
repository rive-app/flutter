import 'package:peon_process/converters.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/clipping_shape.dart';

class ClipFinalizer extends ConversionFinalizer {
  final String clipId;

  const ClipFinalizer(Node clipped, this.clipId) : super(clipped);

  @override
  void finalize(Map<String, Component> fileComponents) {
    final clipped = component as Node;

    riveFile.batchAdd(() {
      final clipSource = fileComponents[clipId] as Node;
      final clipper = ClippingShape();
      riveFile.addObject(clipper);
      clipper.source = clipSource;
      clipped.appendChild(clipper);
    });
  }
}

class NodeConverter extends TransformComponentConverter {
  NodeConverter(
    NodeBase node,
    RiveFile file,
    ContainerComponent maybeParent,
  ) : super(node, file, maybeParent);

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);
    final clipIds = jsonData['clips'];
    // final clipsOptions = jsonData['clipsOptions'];

    final nodeComponent = component as Node;

    if (clipIds is List) {
      for (final c in clipIds) {
        if (c is Map) {
          final clipId = c['id'] as int;
          final cf = ClipFinalizer(nodeComponent, clipId.toString());
          super.addFinalizer(cf);
        } else if (c is int) {
          final cf = ClipFinalizer(nodeComponent, c.toString());
          super.addFinalizer(cf);
        }
      }
    }
  }
}
