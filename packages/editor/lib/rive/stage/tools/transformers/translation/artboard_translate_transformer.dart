import 'package:rive_editor/rive/stage/items/stage_artboard.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';

/// Transformer that translates [StageArtboard]'s underlying [Artboard]
/// component.
class ArtboardTranslateTransformer extends StageTransformer {
  Iterable<StageArtboard> _artboards;

  @override
  void advance(DragTransformDetails details) {
    var delta = details.world.delta;
    for (final artboard in _artboards) {
      artboard.component.x += delta[0];
      artboard.component.y += delta[1];
    }
  }

  @override
  void complete() {}

  @override
  bool init(Iterable<StageItem> items, DragTransformDetails details) {
    _artboards = items.whereType<StageArtboard>();
    return _artboards.isNotEmpty;
  }
}
