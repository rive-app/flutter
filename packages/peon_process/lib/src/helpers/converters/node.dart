import 'package:peon_process/converters.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';

class NodeConverter extends TransformComponentConverter {
  NodeConverter(
    NodeBase node,
    RiveFile file,
    ContainerComponent maybeParent,
  ) : super(node, file, maybeParent);
}
