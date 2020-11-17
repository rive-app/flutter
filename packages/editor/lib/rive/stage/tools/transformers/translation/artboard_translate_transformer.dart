import 'package:rive_core/artboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard.dart';
import 'package:rive_editor/rive/stage/snapper.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';

/// Transformer that translates [StageArtboard]'s underlying [Artboard]
/// component.
class ArtboardTranslateTransformer extends StageTransformer {
  @override
  void advance(DragTransformDetails details) {
    // Handled by snapper...
  }

  @override
  void complete() {}

  @override
  bool init(Set<StageItem> items, DragTransformDetails details) {
    Set<StageArtboard> stageArtboards =
        Set.from(items.whereType<StageArtboard>());

    if (stageArtboards.isEmpty) {
      return false;
    }

    final artboards = stageArtboards.map((a) => a.component);

    artboards.first.stageItem.stage.snapper.add(
      artboards.map((artboard) => _ArtboardSnappingItem(artboard)),
      (item, exclusion) => !exclusion.contains(item) && item is StageArtboard,
    );

    // Filter out any children of the artboard that may be in the set (prevent
    // further translation transformers from affecting them so we don't get
    // double translation).
    for (final item in items.difference(stageArtboards)) {
      if (item.component is! Component) {
        continue;
      }
      var component = item.component as Component;
      if (stageArtboards.contains(component.artboard.stageItem)) {
        items.remove(item);
      }
    }
    return stageArtboards.isNotEmpty;
  }
}

class _ArtboardSnappingItem extends SnappingItem {
  final Artboard artboard;
  final Vec2D worldTranslation;

  factory _ArtboardSnappingItem(Artboard artboard) {
    return _ArtboardSnappingItem._(
      artboard,
      Vec2D.fromValues(artboard.x, artboard.y),
    );
  }

  _ArtboardSnappingItem._(this.artboard, this.worldTranslation);
  @override
  void addSources(SnappingAxes snap, bool isSingleSelection) =>
      snap.addAABB(artboard.worldBounds);

  @override
  StageItem get stageItem => artboard.stageItem;

  @override
  void translateWorld(Vec2D diff) {
    var world = Vec2D.add(Vec2D(), worldTranslation, diff);
    artboard.x = world[0];
    artboard.y = world[1];
  }
}
