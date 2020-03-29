import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_core/math/aabb.dart';

import 'stage.dart';

/// A helper extension to interpret the Component's userData as a StageItem. We
/// do this so that we can leave the userData as an abstract field for
/// implementors to use. This allows us to keep separation between Rive runtime
/// logic and editor-time logic which will make it easier when we extract the
/// Component code for the runtimes. Eventually it'd be nice if this could be
/// done in something like a submodule or at least a synced external module such
/// that the codebase completely shared.
extension StageItemComponent on Component {
  StageItem get stageItem => userData as StageItem;
  set stageItem(StageItem value) => userData = value;
}

/// An individual item that can be drawn, selected/interacted with on the
/// [Stage]. Each [StageItem] has a bounding box defined by the AABB. This box
/// is always in Stage space and it defines the broad-phase hit and visibility
/// bounds of any content this item draws/allows the user to click on. It's
/// implemented as a generic as each StageItem generally has a backing
/// representation in the Rive hierarchy. [T] usually inherits from a
/// [Component], but this is not a hard requirement.
abstract class StageItem<T> extends SelectableItem with StageItemFriend {
  /// The desired screen space stroke width for a selected StageItem.
  static const double strokeWidth = 2;

  /// A globally available paint object used to draw contours around selected
  /// items. The stage will mutate the strokeWidth property such that the stroke
  /// is always in screen space. The stage does this by multiplying desired
  /// [strokeWidth] by the stage's zoom value.
  ///
  static Paint selectedPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..color = const Color(0xFF57A5E0);

  static Paint backboardContrastPaint = Paint()
    ..color = const Color(0xFF57A5E0);

  T _component;
  T get component => _component;

  Stage _stage;
  Stage get stage => _stage;

  /// StageItems are sorted by [drawOrder] before being drawn. This allows
  /// specific classification of items to draw before/after others. For example,
  /// transform handles should always draw after other content.
  int get drawOrder => 1;

  /// Whether the system automatically handles adding and removing this item
  /// to/from the stage. Most [Component]s want the system to automatically add
  /// their corresponding StageItem (if any) when the [Component] is added to
  /// the file and they want it removed when it is removed from the file.
  /// Special items may want to manage their own stage presence in response to
  /// events (like a ColorPicker being turned on displaying the Gradient
  /// handles). These types of items should override isAutomatic to return false
  /// and then manage calls to [Stage.addItem]/[Stage.removeItem] manually in
  /// response to events.
  bool get isAutomatic => true;

  bool initialize(T component) {
    _component = component;
    return true;
  }

  /// Usually an item's hover target is itself, sometimes some items want to
  /// re-direct selection so we use this indirection to allow for that.
  ///
  /// ignore: avoid_returning_this
  StageItem get hoverTarget => this;

  /// Perform a higher fidelity check for worldMouse hit. If this object doesn't
  /// have a narrow-phase hit detection, just return true to use the AABB.
  bool hitHiFi(Vec2D worldMouse) => true;

  /// Override this to temporarily hide items. This shouldn't be used to
  /// permanently hide an item. If an item is no longer necessary it should be
  /// removed from the stage.
  bool get isVisible => true;

  /// Override this to prevent this item from being clicked on.
  bool get isSelectable => isVisible;

  // ignore: use_setters_to_change_properties
  /// Invoked whenever the item has been added to the stage. This is usually
  /// used to do any further initialization or creation of sub-stageItem (for
  /// example the StageArtboard created a StageArtboardTitle so that the
  /// Artboard can have two interactable items on the Stage).
  @mustCallSuper
  void addedToStage(Stage stage) {
    _stage = stage;
  }

  /// Invoked whenever the item has been added removed from the stage. Use this
  /// as an opportunity to remove any other StageItems that may have been
  /// created/added when addedToStage was called.
  @mustCallSuper
  void removedFromStage(Stage stage) {
    _stage = null;
  }

  /// The cursor has either moved over or out of the hit area for this item.
  @override
  void onHoverChanged(bool value) {
    // No longer hovered?
    if (value) {
      _stage?.hoverItem = this;
    } else if (_stage?.hoverItem == this) {
      _stage?.hoverItem = null;
    }

    _stage?.markNeedsAdvance();
  }

  @override
  void onSelectedChanged(bool value) {
    _stage?.markNeedsAdvance();
  }

  /// Provide an aabb for this stage item.
  AABB get aabb;

  void draw(Canvas canvas) {}
}

/// Convert an AABB in object space defined by [xform] to the corresponding
/// transform space. This is accomplished by transforming min and max points of
/// the AABB by the transform [xform] and then finding the new axis aligned
/// min/max on the transformed points.
AABB obbToAABB(AABB obb, Mat2D xform) {
  Vec2D p1 = Vec2D.fromValues(obb[0], obb[1]);
  Vec2D p2 = Vec2D.fromValues(obb[2], obb[1]);
  Vec2D p3 = Vec2D.fromValues(obb[2], obb[3]);
  Vec2D p4 = Vec2D.fromValues(obb[0], obb[3]);

  Vec2D.transformMat2D(p1, p1, xform);
  Vec2D.transformMat2D(p2, p2, xform);
  Vec2D.transformMat2D(p3, p3, xform);
  Vec2D.transformMat2D(p4, p4, xform);

  return AABB.fromValues(
      min(p1[0], min(p2[0], min(p3[0], p4[0]))),
      min(p1[1], min(p2[1], min(p3[1], p4[1]))),
      max(p1[0], max(p2[0], max(p3[0], p4[0]))),
      max(p1[1], max(p2[1], max(p3[1], p4[1]))));
}
