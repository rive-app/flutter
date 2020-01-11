import 'package:fractional/fractional.dart';
import 'component.dart';
import 'src/generated/container_component_base.dart';

class ContainerChildren extends FractionallyIndexedList<Component> {
  @override
  FractionalIndex orderOf(Component value) => value.childOrder;

  @override
  void setOrderOf(Component value, FractionalIndex order) {
    value.childOrder = order;
  }
}

abstract class ContainerComponent extends ContainerComponentBase {
  final ContainerChildren children = ContainerChildren();

  bool addChild(Component child) {
    assert(child != null);

    if (child.parent == this) {
      return false;
    }
    child.parent?.removeChild(child);
    children.append(child);
    childAdded(child);
    return true;
  }

  void childAdded(Component child) {}

  bool removeChild(Component child) {
    assert(child != null);
    if (child.parent != this) {
      return false;
    }
    children.remove(child);
    childRemoved(child);
  }

  void childRemoved(Component child) {}
}
