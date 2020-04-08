import 'package:flutter/foundation.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';

/// The current state of a mouse's translation in some transform space. Also
/// stores previous translation and the delta between them.
class MouseTranslation {
  Vec2D _last;
  Vec2D _current;
  Vec2D _delta;

  Vec2D get last => _last;
  Vec2D get current => _current;
  Vec2D get delta => _delta;

  MouseTranslation(Vec2D origin)
      : _last = Vec2D.clone(origin),
        _current = Vec2D.clone(origin),
        _delta = Vec2D();

  void _moveTo(Vec2D location) {
    _last = _current;
    _current = Vec2D.clone(location);
    _delta = Vec2D.subtract(Vec2D(), location, _last);
  }
}

/// Transform details passed to the various drag operation handlers that a
/// transformer is expected to implement.
class DragTransformDetails {
  final Artboard artboard;

  final MouseTranslation world;
  final MouseTranslation artboardWorld;
  final List<StageItem> items = [];
  final List<StageTransformer> _transformers = [];

  void _moveTo(Vec2D worldMouse) {
    artboardWorld
        ._moveTo(Vec2D.subtract(Vec2D(), worldMouse, artboard.originWorld));
    world._moveTo(worldMouse);
  }

  DragTransformDetails(this.artboard, Vec2D worldMouse)
      : world = MouseTranslation(worldMouse),
        artboardWorld = artboard == null
            ? null
            : MouseTranslation(
                Vec2D.subtract(Vec2D(), worldMouse, artboard.originWorld),
              );
}

/// A [TransformingTool] is similar to a [DraggableTool] in that it can be
/// dragged on the stage, but it works with the concept of creating individual
/// transformers for sets of items that transformers know how to handle. Because
/// different transformers work in different spaces, we group by those spaces
/// and create multiple versions of the transformers as necessary.
mixin TransformingTool {
  Map<Artboard, DragTransformDetails> _artboardTransformSpaces;

  /// Start a drag operation in world coordinates relative to the origin of the
  /// [activeArtboard]. The [activeArtboard] for this operation is provided as
  /// well.
  void startTransformers(
    Iterable<StageItem> selection,
    Vec2D worldMouse,
  ) {
    _artboardTransformSpaces = {};

    for (final item in selection) {
      dynamic component = item.component;
      if (component is Component) {
        var space = _artboardTransformSpaces[component.artboard] ??=
            DragTransformDetails(component.artboard, worldMouse);
        space.items.add(item);
      }
    }

    // We create transformers for each of the transform spaces we have.
    for (final details in _artboardTransformSpaces.values) {
      // Make a mutable list so that the transformers can modify it if they want
      // to take items out of play from other transformers. N.B. transformer
      // order is important in such cases.
      var mutableSelection = Set<StageItem>.from(details.items);

      for (final transformer in transformers) {
        // Because previous transformers can mutate the set...
        if (mutableSelection.isEmpty) {
          break;
        }

        if (transformer.init(mutableSelection, details)) {
          details._transformers.add(transformer);
        }
      }
    }
  }

  @mustCallSuper
  void advanceTransformers(Vec2D worldMouse) {
    for (final details in _artboardTransformSpaces.values) {
      details._moveTo(worldMouse);
      for (final transformer in details._transformers) {
        transformer.advance(details);
      }
    }
  }

  @mustCallSuper
  void completeTransformers() {
    for (final details in _artboardTransformSpaces.values) {
      for (final transformer in details._transformers) {
        transformer.complete();
      }
    }
    _artboardTransformSpaces.clear();
  }

  /// Not every draggable tool is required to create a transformer.
  List<StageTransformer> get transformers => [];
}
