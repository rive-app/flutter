import 'package:rive_core/artboard.dart';

import 'src/generated/node_base.dart';
export 'src/generated/node_base.dart';

class Node extends NodeBase {
  Artboard _artboard;
  @override
  void update(int dirt) {}

  @override
  Artboard get artboard => _artboard;

  @override
  bool resolveArtboard() {
    for (var curr = parent; curr != null; curr = curr.parent) {
      if (curr is Artboard) {
        _artboard = curr;
        return true;
      }
    }
    _artboard = null;
    return false;
  }
}
