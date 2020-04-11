import 'dart:ui';

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/stroke.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/shapes/path_composer.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:rive_core/src/generated/shapes/shape_base.dart';
import 'package:rive_core/transform_space.dart';

export 'package:rive_core/src/generated/shapes/shape_base.dart';

class Shape extends ShapeBase with ShapePaintContainer {
  final Set<Path> paths = {};

  PathComposer _pathComposer;
  PathComposer get pathComposer => _pathComposer;
  set pathComposer(PathComposer value) {
    if (_pathComposer == value) {
      return;
    }
    _pathComposer = value;
    _pathComposer?.addDirt(ComponentDirt.path);
  }

  AABB _bounds = AABB();
  BoundsDelegate _delegate;
  AABB get bounds => _bounds;

  set bounds(AABB bounds) {
    if (AABB.areEqual(bounds, _bounds)) {
      return;
    }
    _bounds = bounds;
    _delegate?.boundsChanged();
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
    _pathComposer?.addDirt(ComponentDirt.path);
    return paths.add(path);
  }

  @override
  void onAdded() {
    // Shape has been added and is clean (all artboards and ancestors of the
    // current hierarchy's components have resolved). This is a good opportunity
    // to self-heal Shapes that are missing PathComposers.
    if (_pathComposer == null) {
      var composer = PathComposer();
      context?.batchAdd(() {
        context.add(composer);
        appendChild(composer);
      });
    }
  }

  void pathChanged(Path path) {
    _pathComposer?.addDirt(ComponentDirt.path);
  }

  bool removePath(Path path) {
    _pathComposer?.addDirt(ComponentDirt.path);
    return paths.remove(path);
  }

  @override
  void transformAffectsStrokeChanged(bool from, bool to) {
    super.transformAffectsStrokeChanged(from, to);
    // TODO: when we have strokes, we need to tell them their LinearGradients
    // that they paint in world space via LinearGradient.paintsInWorldSpace. We
    // also need to re-evaluate this based on the answer to:
    // https://2dimensions.slack.com/archives/CHTMQJAJZ/p1584584763000700
  }

  /// Compute the bounds of this shape in the requested [space].
  @override
  Rect computeBounds(TransformSpace space) {
    switch (space) {
      case TransformSpace.local:
        var inverseShapeWorld = Mat2D();
        if (Mat2D.invert(inverseShapeWorld, worldTransform)) {
          return _pathComposer.uiPath
              .transform(inverseShapeWorld.mat4)
              .getBounds();
        }
        break;
      case TransformSpace.world:
        return _pathComposer.uiPath.getBounds();
    }
    return Rect.zero;
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
  void draw(Canvas canvas) {
    assert(_pathComposer != null);
    var path = _pathComposer.uiPath;
    for (final fill in fills) {
      fill.draw(canvas, path);
    }
    for (final stroke in strokes) {
      stroke.draw(canvas, path);
    }
  }
}
