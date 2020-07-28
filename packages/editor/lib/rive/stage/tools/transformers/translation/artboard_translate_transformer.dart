import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_core/component.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard.dart';
import 'package:rive_editor/rive/stage/snapper.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';

/// Transformer that translates [StageArtboard]'s underlying [Artboard]
/// component.
class ArtboardTranslateTransformer extends StageTransformer {
  ArtboardTranslateTransformer({ValueNotifier<bool> snap})
      : _snap = snap ?? ValueNotifier<bool>(true);

  Set<StageArtboard> _stageArtboards;
  Snapper _snapper;

  /// Should items snap while translating?
  final ValueNotifier<bool> _snap;

  @override
  void advance(DragTransformDetails details) {
    if (_snap.value) {
      _snapper.advance(details.world.current);
      return;
    }
    final delta = details.world.delta;
    for (final artboard in _stageArtboards) {
      artboard.component.x += delta[0];
      artboard.component.y += delta[1];
    }
  }

  @override
  void complete() {}

  @override
  bool init(Set<StageItem> items, DragTransformDetails details) {
    _stageArtboards = Set.from(items.whereType<StageArtboard>());

    if (_stageArtboards.isEmpty) {
      return false;
    }

    final artboards = _stageArtboards.map((a) => a.component);

    _snapper = Snapper.build(
        details.world.current,
        artboards,
        (item) =>
            // This makes sure the artboard name is not snapped to
            item is StageArtboard);

    // Filter out any children of the artboard that may be in the set (prevent
    // further translation transformers from affecting them so we don't get
    // double translation).
    for (final item in items.difference(_stageArtboards)) {
      if (item.component is! Component) {
        continue;
      }
      var component = item.component as Component;
      if (_stageArtboards.contains(component.artboard.stageItem)) {
        items.remove(item);
      }
    }
    return _stageArtboards.isNotEmpty;
  }

  @override
  void draw(Canvas canvas) {
    if (_snap.value) {
      _snapper?.draw(canvas);
    }
  }
}
