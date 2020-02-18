import 'dart:ui' as ui;

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/src/generated/shapes/shape_base.dart';

export 'package:rive_core/src/generated/shapes/shape_base.dart';

class Shape extends ShapeBase {
  final Set<Path> paths = {};
  final ui.Path uiPath = ui.Path();

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

  bool addPath(Path path) {
    print("GOT PATH $path");
    addDirt(ComponentDirt.path);
    return paths.add(path);
  }

  void pathChanged(Path path) {
    addDirt(ComponentDirt.path);
  }

  void recomputePath() {
    uiPath.reset();
    for (final path in paths) {
      uiPath.addPath(path.uiPath, ui.Offset.zero,
          matrix4: path.pathTransform?.mat4);
    }
    ui.Rect uiBounds = uiPath.getBounds();
    bounds = AABB.fromValues(
        uiBounds.left, uiBounds.top, uiBounds.right, uiBounds.bottom);
  }

  bool removePath(Path path) {
    addDirt(ComponentDirt.path);
    return paths.remove(path);
  }

  @override
  void update(int dirt) {
    super.update(dirt);

    if (dirt & ComponentDirt.path != 0) {
      recomputePath();
    }
  }

  @override
  void userDataChanged(dynamic from, dynamic to) {
    if (to is BoundsDelegate) {
      _delegate = to;
    } else {
      _delegate = null;
    }
  }
}
