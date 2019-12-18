import 'container_component.dart';
import 'src/metadata.dart';
export 'container_component.dart';

part 'node.g.dart';

@CoreType(ContainerComponentBase)
abstract class NodeBase extends ContainerComponent {
  @CoreProperty()
  double _x;

  @CoreProperty()
  double _y;

  @CoreProperty()
  double _rotation;
}
