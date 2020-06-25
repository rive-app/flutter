import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';

import 'stage.dart';

/// Object Bounding Box is an AABB in a specific transform space. This can be
/// used to find more precise AABB for stageItems. Not required to be
/// implemented but will help certain tools be more precise, and will allow
/// selection bounds to be drawn against this more precise box.
class OBB {
  final AABB bounds;
  final Mat2D transform;
  final Float32List poly = Float32List(8);
  OBB({
    this.bounds,
    this.transform,
  }) {
    var min = bounds.minimum;
    var max = bounds.maximum;

    var temp = Vec2D();
    Vec2D.transformMat2D(temp, Vec2D.fromValues(min[0], min[1]), transform);
    poly[0] = temp[0];
    poly[1] = temp[1];
    Vec2D.transformMat2D(temp, Vec2D.fromValues(max[0], min[1]), transform);
    poly[2] = temp[0];
    poly[3] = temp[1];
    Vec2D.transformMat2D(temp, Vec2D.fromValues(max[0], max[1]), transform);
    poly[4] = temp[0];
    poly[5] = temp[1];
    Vec2D.transformMat2D(temp, Vec2D.fromValues(min[0], max[1]), transform);
    poly[6] = temp[0];
    poly[7] = temp[1];
  }
}

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
abstract class StageItem<T> extends SelectableItem
    with StageItemFriend, StageDrawable {
  final Event _onRemoved = Event();
  Listenable get onRemoved => _onRemoved;

  /// The desired screen space stroke width for a selected StageItem.
  static const double strokeWidth = 2;

  // Override this if you don't want this item to show up in the hierarchy tree.
  bool get showInHierarchy => true;

  /// A globally available paint object used to draw contours around selected
  /// items. The stage will mutate the strokeWidth property such that the stroke
  /// is always in screen space. The stage does this by multiplying desired
  /// [strokeWidth] by the stage's zoom value.
  ///
  static Paint selectedPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..color = const Color(0xFF57A5E0);

  static Paint boundsShadow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const Color(0x26000000);

  static Paint boundsPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFF57A5E0);

  static Paint backboardContrastPaint = Paint()
    ..color = const Color(0xFF57A5E0);

  T _component;
  T get component => _component;

  Stage _stage;
  Stage get stage => _stage;

  /// Some StageItems can define a solo parent that makes them selectable during
  /// solo if their parent is soloed.
  StageItem get soloParent => null;

  /// Whether the system automatically handles adding and removing this item
  /// to/from the stage. Most [Component]s want the system to automatically add
  /// their corresponding StageItem (if any) when the [Component] is added to
  /// the file and they want it removed when it is removed from the file.
  /// Special items may want to manage their own stage presence in response to
  /// events (like a ColorPicker being turned on displaying the Gradient
  /// handles). These types of items should override isAutomatic to return false
  /// and then manage calls to [Stage.addItem]/[Stage.removeItem] manually in
  /// response to events.
  bool isAutomatic(Stage stage) => true;

  bool initialize(T component) {
    _component = component;
    return true;
  }

  /// Usually an item's hover target is itself, sometimes some items want to
  /// re-direct selection so we use this indirection to allow for that.
  ///
  /// ignore: avoid_returning_this
  StageItem get selectionTarget => this;

  /// Usually an item's inspector target is itself, sometimes some items want to
  /// re-direct the inspector so we use this indirection to allow for that.
  ///
  /// ignore: avoid_returning_this
  StageItem get inspectorItem => this;

  /// Perform a higher fidelity check for worldMouse hit. If this object doesn't
  /// have a narrow-phase hit detection, just return true to use the AABB.
  bool hitHiFi(Vec2D worldMouse) => true;

  /// Perform a high fidelity rectangle intersection test. The rectangle is
  /// provided as interleaved x/y coordinates for the four contour points of the
  /// rectangle.
  bool intersectsRect(Float32List rectPoly) =>
      obb != null && _doRectsIntersect(rectPoly, obb.poly);

  /// Override this to temporarily hide items. This shouldn't be used to
  /// permanently hide an item. If an item is no longer necessary it should be
  /// removed from the stage.
  bool get isVisible => true;

  /// Override this to prevent this item from being selected in any capacity.
  bool get isSelectable => isVisible;

  /// Override this to prevent this item from being clicked on.
  bool get isHoverSelectable => isSelectable;

  /// Use this to determine priority when both items are hovered.
  int compareDrawOrderTo(StageItem other) => drawOrder - other.drawOrder;

  /// Draw order inferred from the drawpasses. This assumes the first item in
  /// the drawPasses list is the "primary" one. So if you register multiple draw
  /// passes, make sure your most important/top layer is registered first and
  /// shadows/etc are registered second (with lower drawOrder if necessary).
  int get drawOrder => drawPasses.first.order;

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
    _onRemoved.notify();
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
  void onSelectedChanged(bool value, bool notify) {
    _stage?.markNeedsAdvance();
    var c = component;

    /// Whenever we select something, make sure we swap the active artboard to
    /// the artboard this component is on, or the component this items
    /// manipulates is on. Should we move this to a ComponentStageItem class?
    /// This is safer as it ensures all StageItems will have this logic, so for
    /// now it lives here.
    if (notify && c != null && c is Component && c.artboard != null) {
      c.context.backboard.activeArtboard = c.artboard;
    }
  }

  AABB _aabb = AABB();

  /// Get the cached AABB for this stage item. StageItems are responsible for
  /// updating this as necessary.
  AABB get aabb => _aabb;
  set aabb(AABB value) {
    if (AABB.areEqual(value, _aabb)) {
      return;
    }
    _aabb = value;
    stage?.updateBounds(this);
  }

  OBB obb;

  @override
  Iterable<StageDrawPass> get drawPasses => [
        StageDrawPass(
          draw,
          inWorldSpace: true,
          order: 1,
        ),
        if (isSelected)
          StageDrawPass(
            drawBounds,
            inWorldSpace: false,
            order: 10,
          ),
      ];

  @override
  void draw(Canvas canvas, StageDrawPass pass) {}

  // Called when the stage either solos or cancels solo for this item.
  void onSoloChanged(bool isSolo) {}

  void _drawBoundingRectangle(Canvas canvas, Mat2D transform, AABB bounds) {
    var tl = Vec2D.transformMat2D(Vec2D(), bounds.topLeft, transform);
    var tr = Vec2D.transformMat2D(Vec2D(), bounds.topRight, transform);
    var br = Vec2D.transformMat2D(Vec2D(), bounds.bottomRight, transform);
    var bl = Vec2D.transformMat2D(Vec2D(), bounds.bottomLeft, transform);

    Path boundsPath = Path()
      ..moveTo(tl[0].roundToDouble() + 0.5, tl[1].roundToDouble() + 0.5)
      ..lineTo(tr[0].roundToDouble() + 0.5, tr[1].roundToDouble() + 0.5)
      ..lineTo(br[0].roundToDouble() + 0.5, br[1].roundToDouble() + 0.5)
      ..lineTo(bl[0].roundToDouble() + 0.5, bl[1].roundToDouble() + 0.5)
      ..close();

    canvas.drawPath(
      boundsPath,
      StageItem.boundsShadow,
    );
    canvas.drawPath(
      boundsPath,
      StageItem.boundsPaint,
    );
  }

  void drawBounds(Canvas canvas, StageDrawPass drawPass) {
    if (obb != null) {
      _drawBoundingRectangle(
        canvas,
        Mat2D.multiply(Mat2D(), stage.viewTransform, obb.transform),
        obb.bounds,
      );
    } else {
      _drawBoundingRectangle(
        canvas,
        stage.viewTransform,
        aabb,
      );
    }
  }
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

/// Tests for rectangle intersection given the polygon contour of the rects.
/// This can be changed into a more general polygon intersector by removing
/// length/2 in each of the outer for loops. We can get away with projecting to
/// only two axes if we know we're dealing with rectangles.
bool _doRectsIntersect(Float32List a, Float32List b) {
  var al = a.length;
  var bl = b.length;
  for (int i = 0, l = a.length ~/ 2; i < l; i += 2) {
    // Finds a line perpendicular to the edge. normal = x: p2.y - p1.y, y: p1.x
    // - p2.x
    var x = a[(i + 3) % al] - a[i + 1];
    var y = a[i] - a[(i + 2) % al];

    // Project each point in a to the perpendicular edge.
    var projectA = _projectToEdge(a, x, y);
    var projectB = _projectToEdge(b, x, y);

    // if there is no overlap between the projects, the edge we are looking at
    // separates the two polygons, and we know there is no overlap
    if (projectA.max < projectB.min || projectB.max < projectA.min) {
      return false;
    }
  }
  for (int i = 0, l = b.length ~/ 2; i < l; i += 2) {
    // Finds a line perpendicular to the edge. normal = x: p2.y - p1.y, y: p1.x
    // - p2.x
    var x = b[(i + 3) % bl] - b[i + 1];
    var y = b[i] - b[(i + 2) % bl];

    // Project each point in a to the perpendicular edge.
    var projectA = _projectToEdge(a, x, y);
    var projectB = _projectToEdge(b, x, y);

    // if there is no overlap between the projects, the edge we are looking at
    // separates the two polygons, and we know there is no overlap
    if (projectA.max < projectB.min || projectB.max < projectA.min) {
      return false;
    }
  }
  return true;
}

class _Projection {
  final double min;
  final double max;

  _Projection(this.min, this.max);
}

/// Return results contains min/max.
_Projection _projectToEdge(Float32List points, double edgeX, double edgeY) {
// Project each point in a to the perpendicular edge.
  double min = double.maxFinite, max = -double.maxFinite;
  var pl = points.length;
  for (int j = 0; j < pl; j += 2) {
    var projection = edgeX * points[j] + edgeY * points[j + 1];
    if (projection < min) {
      min = projection;
    }
    if (projection > max) {
      max = projection;
    }
  }

  return _Projection(min, max);
}
