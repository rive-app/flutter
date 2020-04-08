import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:utilities/iterable.dart';

/// Transformer that translates [StageItem]'s with underlying [Node] components.
class NodeTranslateTransformer extends StageTransformer {
  Iterable<Node> _nodes;

  @override
  void advance(DragTransformDetails details) {
    var delta = details.artboardWorld.delta;
    for (final node in _nodes) {
      print("UPDATE NODE $node $delta");
      node.x += delta[0];
      node.y += delta[1];
    }
  }

  @override
  void complete() {}

  @override
  bool init(Iterable<StageItem> items, DragTransformDetails details) {
    _nodes = items.mapWhereType<Node>((element) => element.component);
    return _nodes.isNotEmpty;
  }
}
