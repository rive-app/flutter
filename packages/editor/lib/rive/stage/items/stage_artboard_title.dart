import 'dart:ui';

import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class StageArtboardTitle extends StageItem<Artboard> {
  final StageArtboard stageArtboard;
  Paragraph _nameParagraph;
  Size _nameSize;
  Color _lastTextColor;

  static const double namePadding = 7;
  static const double activeMarkerSize = 7;

  StageArtboardTitle(this.stageArtboard);

  @override
  StageItem get selectionTarget => stageArtboard;

  @override
  bool initialize(Artboard object) {
    if (!super.initialize(object)) {
      return false;
    }
    _updateBounds();
    _updateName();
    return true;
  }

  void boundsChanged() => _updateBounds();

  @override
  Iterable<StageDrawPass> get drawPasses =>
      [StageDrawPass(draw, order: 0, inWorldSpace: true)];

  void _updateBounds() {
    // Compute max bounds based on stage's min zoom (really broad broad-phase).
    double textPaddingLeft = activeMarkerSize + 4;
    var textHeight = (_nameSize?.height ?? 11) + namePadding;
    var textWidth = textPaddingLeft + (_nameSize?.width ?? component.width);
    var maxWorldTextHeight = textHeight / Stage.minZoom;
    var maxWorldTextWidth = textWidth / Stage.minZoom;
    aabb = AABB.fromValues(component.x, component.y - maxWorldTextHeight,
        component.x + maxWorldTextWidth, component.y);
  }

  @override
  void removedFromStage(Stage stage) {
    super.removedFromStage(stage);
    stage?.cancelDebounce(_updateName);
  }

  @override
  bool hitHiFi(Vec2D worldMouse) {
    if (_nameSize == null) {
      return false;
    }
    var originWorld = component.originWorld;
    var scale = stage.zoomLevel;

    double textPaddingLeft = 0;
    if (stage.activeArtboard == component) {
      textPaddingLeft = activeMarkerSize + 4;
    }

    var y = originWorld[1] - (namePadding + _nameSize.height) / scale;
    var worldWidth = (textPaddingLeft + _nameSize.width) / stage.zoomLevel;
    var worldHeight = _nameSize.height / stage.zoomLevel;
    return Rect.fromLTWH(originWorld[0], y, worldWidth, worldHeight)
        .contains(Offset(worldMouse[0], worldMouse[1]));
  }

  @override
  void draw(Canvas canvas, StageDrawPass pass) {
    // If you want to see the broadphase, comment this back in.
    // if (component.stageItem.selectionState.value != SelectionState.none) {
    //   canvas.drawRect(
    //     Rect.fromLTRB(
    //       aabb[0],
    //       aabb[1],
    //       aabb[2],
    //       aabb[3],
    //     ),
    //     StageItem.selectedPaint,
    //   );
    // }

    var originWorld = component.originWorld;

    // Hacky way to update the text color when the backboard changes color.
    if (_lastTextColor != StageItem.backboardContrastPaint.color) {
      _updateName();
    }

    canvas.save();
    canvas.translate(originWorld[0], originWorld[1]);
    canvas.scale(1 / stage.viewZoom);

    double textPaddingLeft = 0;
    if (stage.activeArtboard == component) {
      textPaddingLeft = activeMarkerSize + 4;
      canvas.drawOval(
          Rect.fromLTWH(
              0,
              -namePadding - _nameSize.height / 2 - activeMarkerSize / 2 - 0.5,
              activeMarkerSize,
              activeMarkerSize),
          StageItem.backboardContrastPaint);
    }
    canvas.drawParagraph(
      _nameParagraph,
      Offset(textPaddingLeft, -namePadding - _nameSize.height),
    );
    canvas.restore();
  }

  void markNameDirty() {
    stage?.debounce(_updateName);
  }

  void _updateName() {
    _lastTextColor = StageItem.backboardContrastPaint.color;
    final style = ParagraphStyle(
        textAlign: TextAlign.left, fontFamily: 'Roboto-Regular', fontSize: 11);

    ParagraphBuilder builder = ParagraphBuilder(style)
      ..pushStyle(
        TextStyle(
          color: _lastTextColor,
          fontFamily: 'Roboto-Regular',
          fontSize: 11,
        ),
      );

    var name = component.name;
    if (name == null || name.isEmpty) {
      name = 'Untitled Artboard';
    }
    builder.addText(name);
    _nameParagraph = builder.build();
    _nameParagraph.layout(const ParagraphConstraints(width: 400));
    List<TextBox> boxes = _nameParagraph.getBoxesForRange(0, name.length);

    _nameSize = boxes.isEmpty
        ? Size.zero
        : Size(boxes.last.right - boxes.first.left + 1,
            boxes.last.bottom - boxes.first.top + 1);
    _updateBounds();
  }
}
