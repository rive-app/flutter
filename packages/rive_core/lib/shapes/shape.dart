import 'dart:ui';

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart' as core;
import 'package:rive_core/shapes/paint/shape_paint_mutator.dart';
import 'package:rive_core/shapes/paint/stroke.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/shapes/path_composer.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:rive_core/src/generated/shapes/shape_base.dart';

export 'package:rive_core/src/generated/shapes/shape_base.dart';

class Shape extends ShapeBase with ShapePaintContainer {
  final Set<Path> paths = {};

  bool _wantWorldPath = false;
  bool _wantLocalPath = false;
  bool get wantWorldPath => _wantWorldPath;
  bool get wantLocalPath => _wantLocalPath;
  bool _fillInWorld = false;
  bool get fillInWorld => _fillInWorld;

  PathComposer _pathComposer;
  PathComposer get pathComposer => _pathComposer;
  set pathComposer(PathComposer value) {
    if (_pathComposer == value) {
      return;
    }
    _pathComposer = value;
    transformAffectsStrokeChanged();
  }

  // Build the bounds on demand, more efficient than re-computing whenever they
  // change as bounds rarely have bearing at runtime (they will in some cases
  // with constraints eventually).
  AABB _worldBounds;
  AABB _localBounds;
  BoundsDelegate _delegate;

  @override
  AABB get worldBounds => _worldBounds ??= computeWorldBounds();

  @override
  AABB get localBounds => _localBounds ??= computeLocalBounds();

  /// Let the shape know that any further call to get world/local bounds will
  /// need to rebuild the cached bounds.
  void markBoundsDirty() {
    _worldBounds = _localBounds = null;
    _delegate?.boundsChanged();
    for (final path in paths) {
      path.markBoundsDirty();
    }
  }

  @override
  void childAdded(Component child) {
    super.childAdded(child);
    switch (child.coreType) {
      case FillBase.typeKey:
        addFill(child as Fill);
        break;
      case StrokeBase.typeKey:
        addStroke(child as Stroke);
        break;
    }
  }

  @override
  void childRemoved(Component child) {
    super.childRemoved(child);
    switch (child.coreType) {
      case FillBase.typeKey:
        removeFill(child as Fill);
        break;
      case StrokeBase.typeKey:
        removeStroke(child as Stroke);
        break;
    }
  }

  bool addPath(Path path) {
    transformAffectsStrokeChanged();
    return paths.add(path);
  }

  // -> editor-only
  @override
  void onAdded() {
    super.onAdded();
    // Shape has been added and is clean (all artboards and ancestors of the
    // current hierarchy's components have resolved). This is a good opportunity
    // to self-heal Shapes that are missing PathComposers.
    if (_pathComposer == null) {
      var composer = PathComposer();
      context?.batchAdd(() {
        context.addObject(composer);
        appendChild(composer);
      });
    }
  }
  // <- editor-only

  void pathChanged(Path path) {
    _pathComposer?.addDirt(ComponentDirt.path);
  }

  void transformAffectsStrokeChanged() {
    addDirt(ComponentDirt.path);
    // Path composer needs to update if we update the types of paths we want.
    _pathComposer?.addDirt(ComponentDirt.path);
  }

  @override
  bool addStroke(Stroke stroke) {
    transformAffectsStrokeChanged();
    return super.addStroke(stroke);
  }

  @override
  bool removeStroke(Stroke stroke) {
    transformAffectsStrokeChanged();
    return super.removeStroke(stroke);
  }

  @override
  void update(int dirt) {
    super.update(dirt);
    if (dirt & ComponentDirt.worldTransform != 0) {
      for (final fill in fills) {
        fill.renderOpacity = renderOpacity;
      }
      for (final stroke in strokes) {
        stroke.renderOpacity = renderOpacity;
      }
    }
    // We update before the path composer so let's get our ducks in a row, what
    // do we want? PathComposer depends on us so we're safe to update our
    // desires here.
    if (dirt & ComponentDirt.path != 0) {
      // Recompute which paths we want.
      _wantWorldPath = false;
      _wantLocalPath = false;
      for (final stroke in strokes) {
        if (stroke.transformAffectsStroke) {
          _wantLocalPath = true;
        } else {
          _wantWorldPath = true;
        }
      }

      // Update the gradients' paintsInWorldSpace properties based on whether
      // the path we'll be feeding that at draw time is in world or local space.
      // This is a good opportunity to do it as gradients depend on us so
      // they'll update after us.
      _fillInWorld = _wantWorldPath || !_wantLocalPath;

      for (final fill in fills) {
        var mutator = fill.paintMutator;
        if (mutator is core.LinearGradient) {
          mutator.paintsInWorldSpace = _fillInWorld;
        }
      }

      for (final stroke in strokes) {
        var mutator = stroke.paintMutator;
        if (mutator is core.LinearGradient) {
          mutator.paintsInWorldSpace = !stroke.transformAffectsStroke;
        }
      }
    }
  }

  bool removePath(Path path) {
    transformAffectsStrokeChanged();
    return paths.remove(path);
  }

  AABB computeWorldBounds() {
    // When we have Path.getTightBounds exposed we'll be able to do:
    // if (_wantWorldPath) {
    //   return _pathComposer.worldPath.getTightBounds();
    // } else {
    //   _pathComposer.localPath.transform(worldTransform.mat4)
    //    .getTightBounds();
    // }
    if (paths.isEmpty) {
      return AABB.fromMinMax(worldTranslation, worldTranslation);
    }
    var path = paths.first;
    var renderPoints = path.renderVertices;
    if (renderPoints.isEmpty) {
      // Can't build bounds from nothing...
      return AABB.fromMinMax(worldTranslation, worldTranslation);
    }
    AABB worldBounds =
        path.preciseComputeBounds(renderPoints, path.pathTransform);

    for (final path in paths.skip(1)) {
      var renderPoints = path.renderVertices;
      AABB.combine(worldBounds, worldBounds,
          path.preciseComputeBounds(renderPoints, path.pathTransform));
    }
    return worldBounds;
  }

  AABB computeLocalBounds() {
    // When we have Path.getTightBounds exposed we'll be able to do:
    // if (_wantLocalPath) {
    //   return _pathComposer.localPath.getTightBounds();
    // } else {
    //   var inverseShapeWorld = Mat2D();
    //   if (Mat2D.invert(inverseShapeWorld, worldTransform)) {
    //     return _pathComposer.worldPath
    //         .transform(inverseShapeWorld.mat4)
    //         .getTightBounds();
    //   }
    // }
    if (paths.isEmpty) {
      // return a 0, 0, 0, 0 AABB as it means we are at the origin of our world
      return AABB();
    }
    var path = paths.first;
    var renderPoints = path.renderVertices;
    if (renderPoints.isEmpty) {
      // Can't build bounds from nothing...
      return AABB();
    }
    var toShapeTransform = Mat2D();
    if (!Mat2D.invert(toShapeTransform, worldTransform)) {
      Mat2D.identity(toShapeTransform);
    }

    AABB localBounds = path.preciseComputeBounds(
      renderPoints,
      Mat2D.multiply(
        Mat2D(),
        toShapeTransform,
        path.pathTransform,
      ),
    );

    for (final path in paths.skip(1)) {
      var renderPoints = path.renderVertices;
      AABB.combine(
        localBounds,
        localBounds,
        path.preciseComputeBounds(
          renderPoints,
          Mat2D.multiply(
            Mat2D(),
            toShapeTransform,
            path.pathTransform,
          ),
        ),
      );
    }
    return localBounds;
  }

  @override
  void userDataChanged(dynamic from, dynamic to) {
    if (to is BoundsDelegate) {
      _delegate = to;
    } else {
      _delegate = null;
    }
  }

  @override
  void blendModeValueChanged(int from, int to) {
    for (final fill in fills) {
      fill.blendMode = blendMode;
    }
    for (final stroke in strokes) {
      stroke.blendMode = blendMode;
    }
  }

  @override
  void draw(Canvas canvas) {
    assert(_pathComposer != null);

    var path = _pathComposer.fillPath;
    assert(path != null, 'path should\'ve been generated by the time we draw');
    if (!_fillInWorld) {
      canvas.save();
      canvas.transform(worldTransform.mat4);
    }
    for (final fill in fills) {
      fill.draw(canvas, path);
    }
    if (!_fillInWorld) {
      canvas.restore();
    }

    // Strokes are slightly more complicated, they may want a local path. Note
    // that we've already built this up during our update and processed any
    // gradients to have their offsets in the correct transform space (see our
    // update method).
    for (final stroke in strokes) {
      var transformAffectsStroke = stroke.transformAffectsStroke;
      var path = transformAffectsStroke
          ? _pathComposer.localPath
          : _pathComposer.worldPath;

      if (transformAffectsStroke) {
        // Get into world space.
        canvas.save();
        canvas.transform(worldTransform.mat4);
        stroke.draw(canvas, path);
        canvas.restore();
      } else {
        stroke.draw(canvas, path);
      }
    }
  }

  @override
  void onPaintMutatorChanged(ShapePaintMutator mutator) {
    // The transform affects stroke property may have changed as we have a new
    // mutator.
    transformAffectsStrokeChanged();
  }

  @override
  void onStrokesChanged() {
    // The transform affects stroke property may have changed as we have a new
    // mutator.
    transformAffectsStrokeChanged();
  }

  @override
  void onFillsChanged() {
    // The transform affects stroke property may have changed as we have a new
    // mutator.
    transformAffectsStrokeChanged();
  }
}
