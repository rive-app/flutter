import 'dart:ui' as ui;

import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/src/generated/shapes/path_composer_base.dart';

/// The PathComposer builds the desired world and local paths for the shapes and
/// their fills/strokes. It gaurantees that one of local or world path is always
/// availble. If the Shape only wants a local path, we'll only build a local
/// one. If the Shape only wants a world path, we'll build only that world path.
/// If it wants both, we build both. If it wants none, we still build a world
/// path.
class PathComposer extends PathComposerBase {
  Shape _shape;
  Shape get shape => _shape;

  final ui.Path worldPath = ui.Path();
  final ui.Path localPath = ui.Path();
  ui.Path _fillPath;
  ui.Path get fillPath => _fillPath;

  void _changeShape(Shape value) {
    // Clean up previous shape's path composer. This should never happen as we
    // don't let the user drag the path composer in the hierarchy, but may as
    // well be safe here in case some code moves it around
    if (_shape != null && _shape.pathComposer == this) {
      _shape.pathComposer = null;
    }

    // Let the new shape know we're its composer. I'm the composer now.
    // https://imgflip.com/i/3qjf6a
    value?.pathComposer = this;
    _shape = value;
  }

  void _recomputePath() {
    // No matter what we'll need some form of a world path to get our bounds.
    // Let's optimize how we build it.
    var buildLocalPath = _shape.wantLocalPath;
    var buildWorldPath = _shape.wantWorldPath || !buildLocalPath;

    // The fill path will be whichever one of these two is available.

    if (buildLocalPath) {
      localPath.reset();
      var world = _shape.worldTransform;
      Mat2D inverseWorld = Mat2D();
      if (!Mat2D.invert(inverseWorld, world)) {
        Mat2D.identity(inverseWorld);
      }
      for (final path in _shape.paths) {
        Mat2D localTransform;
        var transform = path.pathTransform;
        if (transform != null) {
          localTransform = Mat2D();
          Mat2D.multiply(localTransform, inverseWorld, transform);
        }
        localPath.addPath(path.uiPath, ui.Offset.zero,
            matrix4: localTransform?.mat4);
      }

      // If the world path doesn't take care of setting the bounds, we should do
      // it. But if we're computing world paths anyway, no need to do this extra
      // transform...
      if (!buildWorldPath) {
        ui.Rect uiBounds = localPath.transform(world.mat4).getBounds();
        _shape.bounds = AABB.fromValues(
            uiBounds.left, uiBounds.top, uiBounds.right, uiBounds.bottom);
      }
      _fillPath = localPath;
    }
    if (buildWorldPath) {
      worldPath.reset();
      for (final path in _shape.paths) {
        worldPath.addPath(path.uiPath, ui.Offset.zero,
            matrix4: path.pathTransform?.mat4);
      }

      ui.Rect uiBounds = worldPath.getBounds();
      _shape.bounds = AABB.fromValues(
          uiBounds.left, uiBounds.top, uiBounds.right, uiBounds.bottom);
      _fillPath = worldPath;
    }
  }

  @override
  void buildDependencies() {
    super.buildDependencies();

    // We depend on the shape and all of its paths so that we can update after
    // all of them.
    if (_shape != null) {
      _shape.addDependent(this);
      for (final path in _shape?.paths) {
        path.addDependent(this);
      }
    }
  }

  @override
  void update(int dirt) {
    if (dirt & ComponentDirt.path != 0) {
      _recomputePath();
    }
  }

  @override
  void visitAncestor(Component ancestor) {
    if (ancestor is Shape) {
      _changeShape(ancestor);
    }
  }
}
