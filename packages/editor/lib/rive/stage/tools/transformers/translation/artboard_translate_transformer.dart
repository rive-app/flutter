import 'package:rive_core/component.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';

/// Transformer that translates [StageArtboard]'s underlying [Artboard]
/// component.
class ArtboardTranslateTransformer extends StageTransformer {
  Set<StageArtboard> _artboards;

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
  bool init(Set<StageItem> items, DragTransformDetails details) {
    _artboards = Set.from(items.whereType<StageArtboard>());

    if (_artboards.isEmpty) {
      return false;
    }

    // Filter out any children of the artboard that may be in the set (prevent
    // further translation transformers from affecting them so we don't get
    // double translation).
    for (final item in items.difference(_artboards)) {
      if (item.component is! Component) {
        continue;
      }
      var component = item.component as Component;
      if (_artboards.contains(component.artboard.stageItem)) {
        items.remove(item);
      }
    }
    return _artboards.isNotEmpty;
  }
}
